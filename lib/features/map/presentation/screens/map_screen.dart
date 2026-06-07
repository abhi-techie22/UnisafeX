import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  final TourismPlace? selectedPlace;

  const MapScreen({
    super.key,
    this.selectedPlace,
  });

  @override
  ConsumerState<MapScreen> createState() =>
      _MapScreenState();
}

class _MapScreenState
    extends ConsumerState<MapScreen> {
  MapLibreMapController? _controller;

  TourismPlace? _selectedPlace;

  bool _mapReady = false;
  bool _markersAdded = false;

  final Map<String, TourismPlace>
      _symbolPlaces = {};

  static const String _mapStyle =
      'https://demotiles.maplibre.org/style.json';

  @override
  Widget build(BuildContext context) {
    final location =
        ref.watch(locationProvider);

    final placesAsync =
        ref.watch(popularPlacesProvider);

    final latitude =
        widget.selectedPlace?.latitude ??
            location.value?.latitude ??
            AppConstants.defaultLatitude;

    final longitude =
        widget.selectedPlace?.longitude ??
            location.value?.longitude ??
            AppConstants.defaultLongitude;

    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: _mapStyle,

            initialCameraPosition:
                CameraPosition(
              target: LatLng(
                latitude,
                longitude,
              ),
              zoom:
                  widget.selectedPlace !=
                          null
                      ? 14
                      : 5.5,
            ),

            onMapCreated:
                _onMapCreated,

            onStyleLoadedCallback:
                () async {
              debugPrint(
                  'STYLE LOADED');

              _mapReady = true;

              final places =
                  placesAsync.value ??
                      [];

              if (widget
                      .selectedPlace !=
                  null) {
                await _addSinglePlaceMarker(
                  widget.selectedPlace!,
                );
              } else {
                await _addMarkers(
                  places,
                );
              }

              if (mounted) {
                setState(() {});
              }
            },

            compassEnabled: true,
            rotateGesturesEnabled:
                true,
            scrollGesturesEnabled:
                true,
            zoomGesturesEnabled:
                true,

            myLocationEnabled:
                !kIsWeb,
          ),

          if (!_mapReady)
            Container(
              color: Theme.of(
                      context)
                  .scaffoldBackgroundColor,
              child:
                  const Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.pop();
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .arrow_back,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        GestureDetector(
                      onTap: () {
                        context.push(
                          AppRoutes
                              .search,
                        );
                      },
                      child:
                          Container(
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors
                                  .white,
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child:
                            const Row(
                          children: [
                            SizedBox(
                                width:
                                    16),
                            Icon(Icons
                                .search),
                            SizedBox(
                                width:
                                    12),
                            Text(
                              'Search places...',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedPlace !=
              null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 30,
              child: _PlaceCard(
                place:
                    _selectedPlace!,
              ),
            ),

          Positioned(
            right: 16,
            bottom: 130,
            child:
                FloatingActionButton(
              heroTag: 'loc',
              backgroundColor:
                  Colors.white,
              onPressed:
                  _goToMyLocation,
              child: const Icon(
                Icons.my_location,
                color: AppColors
                    .primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(
    MapLibreMapController
        controller,
  ) {
    _controller = controller;

    debugPrint(
        'MAP CREATED');

    controller.onSymbolTapped.add(
      _onSymbolTapped,
    );
  }

  Future<void> _addMarkers(
    List<TourismPlace> places,
  ) async {
    if (_controller == null) return;
    if (_markersAdded) return;

    debugPrint(
      'Loaded places: ${places.length}',
    );

    for (final place
        in places) {
      if (place.latitude ==
              0 ||
          place.longitude ==
              0) {
        continue;
      }

      try {
        final symbol =
            await _controller!
                .addSymbol(
          SymbolOptions(
            geometry: LatLng(
              place.latitude,
              place.longitude,
            ),
            iconImage:
                "circle-15",
            iconSize: 2.0,
            iconColor:
                "#1A6B4A",
            textField:
                place.name,
            textSize: 12,
            textOffset:
                const Offset(
              0,
              1.5,
            ),
            textAnchor:
                "top",
          ),
        );

        _symbolPlaces[
            symbol.id] = place;
      } catch (e) {
        debugPrint(
          'Marker error: $e',
        );
      }
    }

    _markersAdded = true;

    debugPrint(
      'Markers added successfully',
    );
  }

  Future<void>
      _addSinglePlaceMarker(
    TourismPlace place,
  ) async {
    if (_controller == null)
      return;

    try {
      final symbol =
          await _controller!
              .addSymbol(
        SymbolOptions(
          geometry: LatLng(
            place.latitude,
            place.longitude,
          ),
          iconImage:
              "circle-15",
          iconSize: 2.5,
          iconColor:
              "#1A6B4A",
          textField:
              place.name,
          textSize: 14,
          textOffset:
              const Offset(
            0,
            1.5,
          ),
          textAnchor: "top",
        ),
      );

      _symbolPlaces[
          symbol.id] = place;

      setState(() {
        _selectedPlace =
            place;
      });

      await _controller!
          .animateCamera(
        CameraUpdate
            .newLatLngZoom(
          LatLng(
            place.latitude,
            place.longitude,
          ),
          14,
        ),
      );
    } catch (e) {
      debugPrint(
        e.toString(),
      );
    }
  }

  void _onSymbolTapped(
    Symbol symbol,
  ) async {
    final place =
        _symbolPlaces[
            symbol.id];

    if (place == null)
      return;

    setState(() {
      _selectedPlace =
          place;
    });

    await _controller
        ?.animateCamera(
      CameraUpdate
          .newLatLngZoom(
        LatLng(
          place.latitude,
          place.longitude,
        ),
        14,
      ),
    );
  }

  Future<void>
      _goToMyLocation() async {
    final location =
        ref
            .read(
              locationProvider,
            )
            .value;

    if (location == null)
      return;

    await _controller
        ?.animateCamera(
      CameraUpdate
          .newLatLngZoom(
        LatLng(
          location.latitude,
          location.longitude,
        ),
        12,
      ),
    );
  }
}

class _PlaceCard
    extends StatelessWidget {
  final TourismPlace place;

  const _PlaceCard({
    required this.place,
  });

  @override
  Widget build(
      BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          AppRoutes.placeDetail,
          extra: place,
        );
      },
      child: Material(
        elevation: 8,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child: Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius
                    .circular(
              20,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
                child:
                    Image.network(
                  place
                      .primaryImage,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                    _,
                    __,
                    ___,
                  ) {
                    return Container(
                      width:
                          90,
                      height:
                          90,
                      color: Colors
                          .grey
                          .shade200,
                      child:
                          const Icon(
                        Icons
                            .image,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      place.name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                        fontSize:
                            17,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '${place.city}, ${place.state}',
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      '⭐ ${place.rating}',
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .arrow_forward_ios,
              ),
            ],
          ),
        ),
      ),
    );
  }
}