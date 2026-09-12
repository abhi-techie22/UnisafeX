const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const allowedTravelModes = new Set(["DRIVE", "WALK", "BICYCLE", "TRANSIT"]);
const maxRouteDistanceMeters = 2_500_000;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  const authResult = await requireAuthenticatedUser(request);
  if (!authResult.ok) {
    return json({ error: authResult.error }, authResult.status);
  }

  const apiKey = firstConfiguredGoogleKey();
  if (!apiKey) {
    return json({ error: "Routes API is not configured." }, 503);
  }

  try {
    const body = await request.json();
    const origin = parseCoordinate(body.origin);
    const destination = parseCoordinate(body.destination);
    const travelMode = String(body.travelMode ?? "DRIVE").toUpperCase();

    if (!origin || !destination || !allowedTravelModes.has(travelMode)) {
      return json({ error: "Invalid route request." }, 400);
    }

    if (haversineDistanceMeters(origin, destination) > maxRouteDistanceMeters) {
      return json({ error: "Route is too far for in-app navigation." }, 400);
    }

    const routeRequest: Record<string, unknown> = {
      origin: { location: { latLng: origin } },
      destination: { location: { latLng: destination } },
      travelMode,
      computeAlternativeRoutes: false,
      polylineQuality: "HIGH_QUALITY",
      polylineEncoding: "ENCODED_POLYLINE",
      languageCode: "en-IN",
      units: "METRIC",
    };

    if (travelMode === "DRIVE") {
      routeRequest.routingPreference = "TRAFFIC_AWARE_OPTIMAL";
    }

    const response = await fetch(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask": [
            "routes.duration",
            "routes.distanceMeters",
            "routes.polyline.encodedPolyline",
            "routes.legs.steps.distanceMeters",
            "routes.legs.steps.navigationInstruction.instructions",
          ].join(","),
        },
        body: JSON.stringify(routeRequest),
      },
    );

    const googleResponse = await response.json();
    if (!response.ok) {
      console.error("Google Routes API error", googleResponse);
      const fallbackRoute = await computeDirectionsApiRoute({
        apiKey,
        origin,
        destination,
        travelMode,
      });
      if (fallbackRoute) return json(fallbackRoute);
      return json({
        error:
          googleResponse?.error?.message ?? "Google could not calculate route.",
      }, response.status);
    }

    const route = googleResponse?.routes?.[0];
    if (!route) {
      const fallbackRoute = await computeDirectionsApiRoute({
        apiKey,
        origin,
        destination,
        travelMode,
      });
      if (fallbackRoute) return json(fallbackRoute);
      return json({ error: "No route was found." }, 404);
    }
    const encodedPolyline = route.polyline?.encodedPolyline?.toString() ?? "";
    if (!encodedPolyline) {
      const fallbackRoute = await computeDirectionsApiRoute({
        apiKey,
        origin,
        destination,
        travelMode,
      });
      if (fallbackRoute) return json(fallbackRoute);
      return json({ error: "No route path was found." }, 404);
    }

    const steps = (route.legs ?? [])
      .flatMap((leg: Record<string, unknown>) =>
        Array.isArray(leg.steps) ? leg.steps : []
      )
      .map((rawStep: unknown) => {
        const step = rawStep as Record<string, unknown>;
        const navigationInstruction =
          step.navigationInstruction as Record<string, unknown> | undefined;
        return {
          instruction:
            navigationInstruction?.instructions?.toString() ?? "",
          distanceMeters: Number(step.distanceMeters ?? 0),
        };
      })
      .filter((step: { instruction: string }) => step.instruction.length > 0);

    return json({
      distanceMeters: Number(route.distanceMeters ?? 0),
      durationSeconds: parseDuration(route.duration),
      encodedPolyline,
      steps,
    });
  } catch (error) {
    console.error("compute-route failed", error);
    return json({ error: "Could not calculate this route." }, 500);
  }
});

function firstConfiguredGoogleKey() {
  return Deno.env.get("GOOGLE_MAPS_ROUTES_API_KEY") ??
    Deno.env.get("GOOGLE_ROUTES_API_KEY") ??
    Deno.env.get("GOOGLE_MAPS_API_KEY") ??
    Deno.env.get("GOOGLE_MAPS_SERVER_KEY") ??
    "";
}

async function computeDirectionsApiRoute({
  apiKey,
  origin,
  destination,
  travelMode,
}: {
  apiKey: string;
  origin: { latitude: number; longitude: number };
  destination: { latitude: number; longitude: number };
  travelMode: string;
}) {
  const modeByTravelMode: Record<string, string> = {
    DRIVE: "driving",
    WALK: "walking",
    BICYCLE: "bicycling",
    TRANSIT: "transit",
  };
  const mode = modeByTravelMode[travelMode] ?? "driving";
  const url = new URL("https://maps.googleapis.com/maps/api/directions/json");
  url.searchParams.set("origin", `${origin.latitude},${origin.longitude}`);
  url.searchParams.set(
    "destination",
    `${destination.latitude},${destination.longitude}`,
  );
  url.searchParams.set("mode", mode);
  url.searchParams.set("alternatives", "false");
  url.searchParams.set("region", "in");
  url.searchParams.set("key", apiKey);

  try {
    const response = await fetch(url);
    const data = await response.json();
    if (!response.ok || data.status !== "OK") {
      console.error("Google Directions API fallback error", data);
      return null;
    }
    const route = data.routes?.[0];
    const leg = route?.legs?.[0];
    const encodedPolyline = route?.overview_polyline?.points ?? "";
    if (!route || !leg || !encodedPolyline) return null;

    const steps = (leg.steps ?? [])
      .map((step: Record<string, unknown>) => ({
        instruction: stripHtml(step.html_instructions?.toString() ?? ""),
        distanceMeters: Number(
          (step.distance as Record<string, unknown> | undefined)?.value ?? 0,
        ),
      }))
      .filter((step: { instruction: string }) => step.instruction.length > 0);

    return {
      distanceMeters: Number(
        (leg.distance as Record<string, unknown> | undefined)?.value ?? 0,
      ),
      durationSeconds: Number(
        (leg.duration as Record<string, unknown> | undefined)?.value ?? 0,
      ),
      encodedPolyline,
      steps,
    };
  } catch (error) {
    console.error("Directions fallback failed", error);
    return null;
  }
}

function stripHtml(value: string) {
  return value
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/\s+/g, " ")
    .trim();
}

async function requireAuthenticatedUser(request: Request) {
  const authorization = request.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return { ok: false, status: 401, error: "Authentication required." };
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !supabaseAnonKey) {
    return { ok: false, status: 503, error: "Auth verification is not configured." };
  }

  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      "Authorization": authorization,
      "apikey": supabaseAnonKey,
    },
  });

  if (!response.ok) {
    return { ok: false, status: 401, error: "Invalid or expired session." };
  }

  return { ok: true, status: 200, error: "" };
}

function parseCoordinate(value: unknown) {
  if (!value || typeof value !== "object") return null;
  const coordinate = value as Record<string, unknown>;
  const latitude = Number(coordinate.latitude);
  const longitude = Number(coordinate.longitude);
  if (
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    return null;
  }
  return { latitude, longitude };
}

function haversineDistanceMeters(
  origin: { latitude: number; longitude: number },
  destination: { latitude: number; longitude: number },
) {
  const earthRadiusMeters = 6_371_000;
  const toRadians = (degrees: number) => degrees * Math.PI / 180;
  const deltaLatitude = toRadians(destination.latitude - origin.latitude);
  const deltaLongitude = toRadians(destination.longitude - origin.longitude);
  const originLatitude = toRadians(origin.latitude);
  const destinationLatitude = toRadians(destination.latitude);
  const a = Math.sin(deltaLatitude / 2) ** 2 +
    Math.cos(originLatitude) * Math.cos(destinationLatitude) *
      Math.sin(deltaLongitude / 2) ** 2;
  return earthRadiusMeters * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function parseDuration(value: unknown) {
  const match = String(value ?? "").match(/^(\d+(?:\.\d+)?)s$/);
  return match ? Math.ceil(Number(match[1])) : 0;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
