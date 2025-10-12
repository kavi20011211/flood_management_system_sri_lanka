import 'package:flutter/material.dart';
import 'package:frontend/screens/flooed_areas_screen.dart';
import 'package:frontend/screens/safe_area_display_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables to store API response
  String riskLevel = "";
  String location = "";
  String generatedText = "";
  Map<String, dynamic>? weatherFeatures;
  bool isLoading = true;
  String? error;
  GoogleMapController? _mapController;
  final LatLng _sriLankaCenter = const LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptLocation();
    });
  }

  Future<void> _checkAndPromptLocation() async {
    bool hasLocation = await _loadData();
    if (!hasLocation) {
      _showLocationDialog();
    } else {
      await fetchPrediction();
      await fetchGeneratedText();
    }
  }

  Future<bool> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('location');

    if (data != null && data.isNotEmpty) {
      setState(() {
        location = data;
      });
      return true;
    }
    return false;
  }

  void _showLocationDialog() {
    final TextEditingController _locationController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Your Location"),
          content: TextField(
            controller: _locationController,
            decoration:
                const InputDecoration(hintText: "Enter your city or area"),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isLoading = false;
                });
              },
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                final newLocation = _locationController.text.trim();
                if (newLocation.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('location', newLocation);
                  setState(() {
                    location = newLocation;
                  });
                  Navigator.of(context).pop();
                  await fetchPrediction();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchPrediction() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    String? currentLocation = prefs.getString('location');

    if (currentLocation == null || currentLocation.isEmpty) {
      setState(() {
        error = 'Location not found';
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
        'http://192.168.1.100:5000/get-risk-prediction?area=$currentLocation');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          riskLevel = data['risk_prediction'] ?? '';
          location = data['area'] ?? currentLocation;
          weatherFeatures = data['features_used'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching prediction: $e';
        isLoading = false;
      });
    }
  }

  Future<String> fetchGeneratedText() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    String? currentLocation = prefs.getString('location');

    if (currentLocation == null || currentLocation.isEmpty) {
      setState(() {
        error = 'Location not found';
        isLoading = false;
      });
      return "";
    }

    if (weatherFeatures == null) {
      setState(() {
        error = 'Weather data not available. Please fetch weather data first.';
        isLoading = false;
      });
      return "";
    }

    final url = Uri.parse('http://192.168.1.100:5000/generate-risk-summary');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "area": currentLocation,
          "latitude": "6.92",
          "longitude": "79.98",
          "river_level": weatherFeatures!['river_level'],
          "severity": riskLevel,
          "elevation": weatherFeatures!['elevation']
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String summary = data['summary'] ?? '';

        setState(() {
          generatedText = summary;
          isLoading = false;
        });

        return summary;
      } else {
        setState(() {
          error =
              'Failed to generate text: ${response.statusCode} - ${response.body}';
          isLoading = false;
        });
        return "";
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching generated text: $e';
        isLoading = false;
      });
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _buildErrorView()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        if (generatedText.isNotEmpty) _buildAlertCard(),
                        const SizedBox(height: 16),
                        if (generatedText.isNotEmpty) _buildMapPreview(),
                        const SizedBox(height: 16),
                        _buildRiskLevelCard(),
                        const SizedBox(height: 24),
                        _buildPopularServices(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.red, size: 18),
                const SizedBox(width: 4),
                Text(
                  location.isNotEmpty ? location : "Unknown",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard() {
    return Container(
      height: 350,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Weather Alert",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  riskLevel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            generatedText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlooedAreasScreen(
                      severity: riskLevel.toLowerCase().toString(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text(
                "Find Effected Areas",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlooedAreasScreen(
              severity: riskLevel.toLowerCase(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _sriLankaCenter,
                  zoom: 7.0,
                ),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),
              // Overlay with gradient and text
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View Affected Areas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to see detailed map',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskLevelCard() {
    Color riskColor;
    IconData riskIcon;
    String riskMessage;
    double riskPercentage;

    switch (riskLevel.toLowerCase()) {
      case 'low':
        riskColor = Colors.green.shade600;
        riskIcon = Icons.check_circle;
        riskMessage = "You are well prepared for an emergency";
        riskPercentage = 0.35;
        break;
      case 'moderate':
        riskColor = Colors.orange.shade600;
        riskIcon = Icons.warning_amber_rounded;
        riskMessage = "You are moderately prepared for an emergency";
        riskPercentage = 0.60;
        break;
      case 'high':
        riskColor = Colors.red.shade600;
        riskIcon = Icons.dangerous;
        riskMessage = "Emergency preparedness needed";
        riskPercentage = 0.85;
        break;
      default:
        riskColor = Colors.grey.shade600;
        riskIcon = Icons.help;
        riskMessage = "Unable to determine risk level";
        riskPercentage = 0.0;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  riskMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                riskLevel.toUpperCase(),
                style: TextStyle(
                  color: riskColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // Row(
          //   children: [
          //     Text(
          //       "Risk Level",
          //       style: TextStyle(
          //         color: Colors.grey.shade600,
          //         fontSize: 13,
          //       ),
          //     ),
          //     const Spacer(),
          //     Text(
          //       "${(riskPercentage * 100).toInt()}%",
          //       style: TextStyle(
          //         color: Colors.grey.shade800,
          //         fontSize: 13,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 8),
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(10),
          //   child: LinearProgressIndicator(
          //     value: riskPercentage,
          //     backgroundColor: Colors.grey.shade200,
          //     valueColor: AlwaysStoppedAnimation<Color>(riskColor),
          //     minHeight: 8,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildPopularServices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "POPULAR SERVICES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.home,
                  label: "Safe\nZones",
                  color: Colors.red.shade400,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SafeAreaDisplayScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.local_hospital,
                  label: "Hospitals\nnearby",
                  color: Colors.red.shade400,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.phone,
                  label: "Emergency\nnumbers",
                  color: Colors.red.shade400,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: fetchPrediction,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Refresh Data"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? "Unknown error",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchPrediction,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
