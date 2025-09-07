import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FlooedAreasScreen extends StatefulWidget {
  final String severity;
  const FlooedAreasScreen({super.key, required this.severity});

  @override
  State<FlooedAreasScreen> createState() => _FlooedAreasScreenState();
}

class _FlooedAreasScreenState extends State<FlooedAreasScreen> {
  GoogleMapController? mapController;
  bool isLoading = true;
  String? error;
  final LatLng _center = const LatLng(7.8731, 80.7718); // Sri Lanka center
  final Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {}; // Added for route drawing
  List<dynamic> floodProneAreas = [];
  String? userCurrentLocation;
  bool showRouteInfo = false; // Flag to show route information

  // API base URL - consider moving this to a config file
  static const String baseUrl = 'http://192.168.1.100:5000';

  // JSON data for safe routes
  final Map<String, dynamic> safeRoutesData = {
    "high": [
      {
        "Kaduwela": {
          "route": [
            6.949239,
            79.991673,
            6.949790,
            79.992783,
            6.949905,
            79.992996,
            6.950004,
            79.993176,
            6.950093,
            79.993272,
            6.950195,
            79.993360,
            6.950323,
            79.993459,
            6.950502,
            79.993562,
            6.950690,
            79.993661,
            6.951893,
            79.994015,
            6.952064,
            79.994048,
            6.952222,
            79.994066,
            6.952496,
            79.994071,
            6.952655,
            79.994063,
            6.952974,
            79.994051,
            6.953021,
            79.995135,
            6.953048,
            79.995322,
            6.953021,
            79.995408,
            6.952931,
            79.995741,
            6.952910,
            79.995912,
            6.952894,
            79.996127,
            6.952856,
            79.996299,
            6.952803,
            79.996476,
            6.952760,
            79.996610,
            6.952723,
            79.996717,
            6.952723,
            79.996867,
            6.952760,
            79.997307,
            6.952782,
            79.997822,
            6.952782,
            79.997978,
            6.952760,
            79.998123,
            6.952766,
            79.998423,
            6.952782,
            79.998772,
            6.952787,
            79.998916,
            6.952819,
            79.999029,
            6.952851,
            79.999169,
            6.952947,
            79.999351,
            6.953011,
            79.999496,
            6.953016,
            79.999561,
            6.953026,
            79.999695,
            6.953181,
            79.999593,
            6.953165,
            80.000312,
            6.953159,
            80.000408,
            6.953255,
            80.000456,
            6.953345,
            80.000504,
            6.953413,
            80.000559,
            6.953405,
            80.000640,
            6.953396,
            80.000665,
            6.953240,
            80.001180,
            6.953192,
            80.001255,
            6.953085,
            80.001260,
            6.952856,
            80.001217,
            6.952750,
            80.001239,
            6.952713,
            80.001277,
            6.952244,
            80.001733,
            6.952159,
            80.001818,
            6.952100,
            80.001920,
            6.951392,
            80.003379,
            6.951344,
            80.003497,
            6.951333,
            80.003524,
            6.951371,
            80.004077,
            6.951530,
            80.004130,
            6.952723,
            80.004458,
            6.952830,
            80.004474,
            6.952862,
            80.004458,
            6.952920,
            80.004356,
            6.953185,
            80.003407,
            6.957606,
            80.004683,
            6.958024,
            80.004912,
            6.958403,
            80.005275,
            6.960846,
            80.009421,
            6.961083,
            80.010100,
            6.961097,
            80.010148,
            6.962440,
            80.009713,
            6.962582,
            80.009627,
            6.962686,
            80.009474,
            6.962757,
            80.009316,
            6.962776,
            80.009096,
            6.962738,
            80.008905,
            6.961472,
            80.004953,
            6.961268,
            80.004064,
            6.961263,
            80.003347,
            6.961396,
            80.002525,
            6.961648,
            80.000127,
            6.961568,
            79.996147,
            6.962329,
            79.996514,
            6.963245,
            79.996831,
            6.963836,
            79.996984,
            6.964024,
            79.997070,
            6.964261,
            79.997151,
            6.965041,
            79.997588,
            6.965282,
            79.997760,
            6.965479,
            79.997949,
            6.965757,
            79.998292,
            6.965882,
            79.998464,
            6.965985,
            79.998599,
            6.966147,
            79.998698,
            6.966379,
            79.998820,
            6.966563,
            79.998928,
            6.967488,
            79.999392,
            6.967699,
            79.999536,
            6.967874,
            79.999703,
            6.967981,
            79.999847,
            6.968165,
            80.000037,
            6.968259,
            80.000122,
            6.968621,
            80.000285,
            6.968926,
            80.000411
          ]
        }
      }
    ]
  };

  Future<void> getFloodProneAreas() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    debugPrint("====SEVERITY==== ${widget.severity}");
    final uri =
        Uri.parse('$baseUrl/get-flood-prone-areas?severity=${widget.severity}');
    debugPrint(
        "====URL==== $baseUrl/get-flood-prone-areas?severity=${widget.severity}");
    try {
      // Add timeout to HTTP request
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            floodProneAreas = data;
            isLoading = false;
          });

          debugPrint("Flood Prone areas: $floodProneAreas");
          await _floodProneAreaMarkers();

          // Draw safe route if conditions are met
          await _drawSafeRoute();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        setState(() {
          error = 'Failed to fetch data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching safe areas: ${e.toString()}';
        isLoading = false;
      });
      debugPrint("Fetch error: $e");
    }
  }

  Future<void> _drawSafeRoute() async {
    // Check if we should draw the safe route
    if (widget.severity.toLowerCase() == 'high' &&
        userCurrentLocation?.toLowerCase() == 'kaduwela') {
      debugPrint("Drawing safe route for Kaduwela - High severity");

      // Get route data for Kaduwela
      final highSeverityRoutes = safeRoutesData['high'] as List;
      Map<String, dynamic>? kaduwelaRoute;

      for (var routeData in highSeverityRoutes) {
        if (routeData.containsKey('Kaduwela')) {
          kaduwelaRoute = routeData['Kaduwela'];
          break;
        }
      }

      if (kaduwelaRoute != null && kaduwelaRoute.containsKey('route')) {
        List<dynamic> routeCoordinates = kaduwelaRoute['route'];
        List<LatLng> polylinePoints = [];

        // Convert coordinate pairs to LatLng points
        for (int i = 0; i < routeCoordinates.length; i += 2) {
          if (i + 1 < routeCoordinates.length) {
            double lat = routeCoordinates[i].toDouble();
            double lng = routeCoordinates[i + 1].toDouble();
            polylinePoints.add(LatLng(lat, lng));
          }
        }

        // Create polyline
        final Polyline safeRoutePolyline = Polyline(
          polylineId: const PolylineId('safe_route_kaduwela'),
          points: polylinePoints,
          color: Colors.green,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dashed line
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        );

        // Add start and end markers
        if (polylinePoints.isNotEmpty) {
          _markers.add(Marker(
            markerId: const MarkerId('route_start'),
            position: polylinePoints.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(
              title: 'Safe Route Start',
              snippet: 'Kaduwela - High Severity',
            ),
          ));

          _markers.add(Marker(
            markerId: const MarkerId('route_end'),
            position: polylinePoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(
              title: 'Safe Route End',
              snippet: 'Kaduwela - High Severity',
            ),
          ));
        }

        setState(() {
          _polylines.add(safeRoutePolyline);
          showRouteInfo = true;
        });

        // Fit the route in view
        if (polylinePoints.isNotEmpty && mapController != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _fitRouteInView(polylinePoints);
          });
        }

        debugPrint("Safe route drawn with ${polylinePoints.length} points");
      }
    } else {
      debugPrint(
          "Conditions not met for drawing safe route. Severity: ${widget.severity}, Location: $userCurrentLocation");
    }
  }

  // Fit route points in camera view
  void _fitRouteInView(List<LatLng> points) {
    if (points.isEmpty || mapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Add some padding to bounds
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        100.0, // padding
      ),
    );
  }

  Future<void> _floodProneAreaMarkers() async {
    // Keep track of used coordinates to offset duplicates
    Map<String, int> coordinateCount = {};

    for (int i = 0; i < floodProneAreas.length; i++) {
      var proneArea = floodProneAreas[i];

      double? latitude =
          double.tryParse(proneArea['latitude']?.toString() ?? '');
      double? longitude =
          double.tryParse(proneArea['longitude']?.toString() ?? '');

      if (latitude != null && longitude != null) {
        // Create a key for this coordinate pair
        String coordKey =
            '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';

        // Check if we've seen this coordinate before
        int count = coordinateCount[coordKey] ?? 0;
        coordinateCount[coordKey] = count + 1;

        // Apply small offset for duplicate coordinates
        double offsetLat = latitude;
        double offsetLng = longitude;

        if (count > 0) {
          // Offset in a circular pattern around the original point
          double offsetDistance = 0.001 * count; // ~100m per duplicate
          double angle = (count * 60) * (math.pi / 180); // 60 degrees apart
          offsetLat += offsetDistance * math.cos(angle);
          offsetLng += offsetDistance * math.sin(angle);
        }

        _circles.add(Circle(
          circleId: CircleId('flood_prone_area_${proneArea['id']}'),
          center: LatLng(offsetLat, offsetLng),
          radius: 100, // radius in meters
          fillColor: (proneArea['severity'] == 'high'
                  ? Colors.red
                  : proneArea['severity'] == 'moderate'
                      ? Colors.orange
                      : Colors.yellow)
              .withOpacity(0.3),
          // strokeColor: proneArea['severity'] == 'high'
          //     ? Colors.red
          //     : proneArea['severity'] == 'moderate'
          //         ? Colors.orange
          //         : Colors.yellow,
          // strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () {
            // Handle tap
            print('Tapped flood area: ${proneArea['severity']}');
          },
        ));
      }
    }

    if (mounted) setState(() {});

    if (_markers.isNotEmpty && mapController != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _fitMarkersInView();
      });
    }
  }

  // Fit all markers in camera view
  void _fitMarkersInView() {
    if (_markers.isEmpty || mapController == null) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      minLat =
          minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat =
          maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude
          ? minLng
          : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude
          ? maxLng
          : marker.position.longitude;
    }

    // Add some padding to bounds
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        100.0, // padding
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    // If we already have markers loaded, fit them in view
    if (_markers.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _fitMarkersInView();
      });
    }
  }

  Future<void> _getUserCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userCurrentLocation = prefs.getString('location');
    });
    debugPrint("User current location: $userCurrentLocation");
  }

  @override
  void initState() {
    super.initState();
    // Get user location first, then call the API
    _getUserCurrentLocation().then((_) {
      getFloodProneAreas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 7.0,
            ),
            markers: _markers,
            circles: _circles,
            polylines: _polylines, // Added polylines to the map
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Route information banner
          if (showRouteInfo)
            Positioned(
              bottom: 100,
              left: 10,
              right: 10,
              child: Card(
                color: Colors.green[50],
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.route, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Safe Route Available',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This is the safe route for Kaduwela region when the flood severity is high',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => showRouteInfo = false),
                        icon: Icon(Icons.close, color: Colors.green[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading flood prone areas...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (error != null)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => error = null),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
