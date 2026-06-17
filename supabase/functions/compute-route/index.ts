const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const allowedTravelModes = new Set(["DRIVE", "WALK", "BICYCLE", "TRANSIT"]);

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  const apiKey = Deno.env.get("GOOGLE_MAPS_ROUTES_API_KEY");
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
      routeRequest.routingPreference = "TRAFFIC_AWARE";
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
      return json(
        {
          error:
            googleResponse?.error?.message ?? "Google could not calculate route.",
        },
        response.status,
      );
    }

    const route = googleResponse?.routes?.[0];
    if (!route) {
      return json({ error: "No route was found." }, 404);
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
      encodedPolyline: route.polyline?.encodedPolyline ?? "",
      steps,
    });
  } catch (error) {
    console.error("compute-route failed", error);
    return json({ error: "Could not calculate this route." }, 500);
  }
});

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
