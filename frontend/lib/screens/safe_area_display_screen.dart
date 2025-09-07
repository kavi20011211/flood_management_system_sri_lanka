import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class SafeAreaDisplayScreen extends StatefulWidget {
  const SafeAreaDisplayScreen({super.key});

  @override
  State<SafeAreaDisplayScreen> createState() => _SafeAreaDisplayScreenState();
}

class _SafeAreaDisplayScreenState extends State<SafeAreaDisplayScreen> {
  GoogleMapController? mapController;
  bool isLoading = true;
  String? error;
  String location = "";
  List<dynamic> safeAreaDetails = [];
  Position? currentPosition;
  bool isLocationLoading = false;
  bool isRequestLoading = false;

  final LatLng _center = const LatLng(7.8731, 80.7718); // Sri Lanka center
  final Set<Marker> _markers = {};

  // API base URL - consider moving this to a config file
  static const String baseUrl = 'http://192.168.1.100:5000';

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await getCurrentLocation();
    await fetchSafeAreaDetails();
  }

  // Check location permissions and get current location
  Future<void> getCurrentLocation() async {
    setState(() {
      isLocationLoading = true;
      error = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          error = 'Location services are disabled. Please enable GPS.';
          isLocationLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            error = 'Location permissions are denied';
            isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          error =
              'Location permissions are permanently denied. Please enable in settings.';
          isLocationLoading = false;
        });
        return;
      }

      // Get current position with better error handling
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Increased timeout
      );

      setState(() {
        currentPosition = position;
        isLocationLoading = false;
      });

      // Add user location marker
      _addUserLocationMarker();

      // Move camera to user location
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14.0,
          ),
        );
      }

      debugPrint(
          "Current location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      setState(() {
        error = 'Failed to get location: ${e.toString()}';
        isLocationLoading = false;
      });
      debugPrint("Location error: $e");
    }
  }

  // Add user's current location marker
  void _addUserLocationMarker() {
    if (currentPosition == null) return;

    // Remove existing user location marker if it exists
    _markers.removeWhere((marker) => marker.markerId.value == 'user_location');

    // Add new user location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current GPS position',
        ),
      ),
    );

    if (mounted) setState(() {}); // Check if widget is still mounted
  }

  // Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Fetch safe area details with better error handling
  Future<void> fetchSafeAreaDetails() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? currentLocation = prefs.getString('location');

      if (currentLocation == null || currentLocation.isEmpty) {
        setState(() {
          error = 'Location not found';
          isLoading = false;
        });
        return;
      }

      setState(() {
        location = currentLocation;
      });

      final uri = Uri.parse('$baseUrl/get-safe-areas?area=$currentLocation');

      // Add timeout to HTTP request
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Validate response data
        if (data is List) {
          setState(() {
            safeAreaDetails = data;
            isLoading = false;
          });

          debugPrint("Location Data: $safeAreaDetails");
          await _loadSafeAreaMarkers();
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

  // Send request for safe areas with improved error handling
  Future<void> sendRequestToTheSafeArea(
    String safeAreaId,
    String username,
    String requestType,
    String count,
  ) async {
    if (currentPosition == null) {
      _showErrorSnackBar('Location not available');
      return;
    }

    // Input validation
    if (username.isEmpty || requestType.isEmpty || count.isEmpty) {
      _showErrorSnackBar('Please fill all fields');
      return;
    }

    // Validate count is a number
    if (int.tryParse(count) == null || int.parse(count) <= 0) {
      _showErrorSnackBar('Please enter a valid number of people');
      return;
    }

    setState(() {
      isRequestLoading = true;
    });

    try {
      final userLat = currentPosition!.latitude;
      final userLong = currentPosition!.longitude;

      final uri = Uri.parse("$baseUrl/request-safe-area");

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "safe_area_id": safeAreaId,
          "user": username,
          "latitude": userLat,
          "longitude": userLong,
          "count": count,
          "request": requestType,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      setState(() {
        isRequestLoading = false;
      });

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close the dialog
        _showSuccessSnackBar('Request sent successfully!');
      } else {
        _showErrorSnackBar('Failed to send request: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isRequestLoading = false;
      });
      _showErrorSnackBar('Error sending request: ${e.toString()}');
      debugPrint("Request error: $e");
    }
  }

  void _showRequestForm(String safeAreaId) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController requestTypeController = TextEditingController();
    final TextEditingController peopleCountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Send a request to the safe area"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          hintText: "Enter your name",
                          labelText: "Name",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: peopleCountController,
                        decoration: const InputDecoration(
                          hintText: "Enter number of people",
                          labelText: "Number of People",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter number of people';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: requestTypeController,
                        decoration: const InputDecoration(
                          hintText: "Enter your request type",
                          labelText: "Request Type",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your request';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isRequestLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isRequestLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            await sendRequestToTheSafeArea(
                              safeAreaId,
                              usernameController.text.trim(),
                              requestTypeController.text.trim(),
                              peopleCountController.text.trim(),
                            );
                          }
                        },
                  child: isRequestLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Send"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Load markers from fetched safe area data
  Future<void> _loadSafeAreaMarkers() async {
    // Clear existing safe area markers but keep user location marker
    _markers.removeWhere((marker) => marker.markerId.value != 'user_location');

    // Keep track of used coordinates to offset duplicates
    Map<String, int> coordinateCount = {};

    for (int i = 0; i < safeAreaDetails.length; i++) {
      var safeArea = safeAreaDetails[i];
      double? latitude =
          double.tryParse(safeArea['latitude']?.toString() ?? '');
      double? longitude =
          double.tryParse(safeArea['longitude']?.toString() ?? '');

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

        _markers.add(
          Marker(
            markerId: MarkerId('safe_area_${safeArea['safe_area_id']}'),
            position: LatLng(offsetLat, offsetLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title:
                  '${safeArea['safe_area'] ?? 'Safe Area'}${count > 0 ? ' (${count + 1})' : ''}',
              snippet: _getMarkerSnippet(safeArea, offsetLat, offsetLng),
            ),
            onTap: () {
              _showSafeAreaDetails(safeArea);
            },
          ),
        );
      }
    }

    if (mounted) setState(() {}); // Check if widget is still mounted

    // Adjust camera to show all markers if we have data and map is ready
    if (_markers.isNotEmpty && mapController != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _fitMarkersInView();
      });
    }
  }

  // Get marker snippet with distance info
  String _getMarkerSnippet(
      Map<String, dynamic> safeArea, double lat, double lng) {
    String snippet =
        'Capacity: ${safeArea['capacity'] ?? 'Unknown'}\nArea: ${safeArea['area'] ?? 'Unknown'}';

    if (currentPosition != null) {
      double distance = calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        lat,
        lng,
      );

      if (distance < 1000) {
        snippet += '\nDistance: ${distance.toStringAsFixed(0)}m';
      } else {
        snippet += '\nDistance: ${(distance / 1000).toStringAsFixed(1)}km';
      }
    }

    return snippet;
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

  // Show safe area details in a bottom sheet
  void _showSafeAreaDetails(Map<String, dynamic> safeArea) {
    double? lat = double.tryParse(safeArea['latitude']?.toString() ?? '');
    double? lng = double.tryParse(safeArea['longitude']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safeArea['safe_area'] ?? 'Safe Area',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Area: ${safeArea['area'] ?? 'Unknown'}'),
              Text('Capacity: ${safeArea['capacity'] ?? 'Unknown'}'),
              Text(
                  'Coordinates: ${safeArea['latitude']}, ${safeArea['longitude']}'),

              // Show distance if we have user location
              if (currentPosition != null && lat != null && lng != null)
                Builder(
                  builder: (context) {
                    double distance = calculateDistance(
                      currentPosition!.latitude,
                      currentPosition!.longitude,
                      lat,
                      lng,
                    );
                    return Text(
                      'Distance: ${distance < 1000 ? '${distance.toStringAsFixed(0)}m' : '${(distance / 1000).toStringAsFixed(1)}km'} from your location',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    );
                  },
                ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showRequestForm(safeArea['safe_area_id'].toString());
                      },
                      child: const Text('Send Request'),
                    ),
                  ),
                  if (lat != null && lng != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          if (mapController != null) {
                            mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(lat, lng),
                                16.0,
                              ),
                            );
                          }
                        },
                        child: const Text('Go to Location'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safe Areas${location.isNotEmpty ? ' - $location' : ''}'),
        actions: [
          IconButton(
            icon: isLocationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            onPressed: isLocationLoading ? null : getCurrentLocation,
            tooltip: 'Get Current Location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : fetchSafeAreaDetails,
            tooltip: 'Refresh Safe Areas',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 7.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
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
                        Text('Loading safe areas...'),
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
          if (!isLoading && safeAreaDetails.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Found ${safeAreaDetails.length} safe area(s)${location.isNotEmpty ? ' in $location' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
