import 'package:flutter/material.dart';
import 'package:frontend/screens/flooed_areas_screen.dart';
import 'package:frontend/screens/safe_area_display_screen.dart';
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
      // Only fetch prediction if location exists
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
                  // Fetch prediction after saving location
                  await fetchPrediction();
                }
              },
            ),
          ],
        );
      },
    );
  }

  //Fetch severity
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

    // Build the URL with query parameters
    final url = Uri.parse(
        'http://192.168.117.1:5000/get-risk-prediction?area=$currentLocation');

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

        print("Date: ${data['date']}");
        print("Area: ${data['area']}");
        print("Risk Prediction: ${data['risk_prediction']}");

        final features = data['features_used'];
        print("Rainfall: ${features['rainfall']}");
        print("River Level: ${features['river_level']}");
        print("Soil Moisture: ${features['soil_moisture']}");
        print("Elevation: ${features['elevation']}");
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

    // Check if weatherFeatures is available
    if (weatherFeatures == null) {
      setState(() {
        error = 'Weather data not available. Please fetch weather data first.';
        isLoading = false;
      });
      return "";
    }

    final url = Uri.parse('http://192.168.117.1:5000/generate-risk-summary');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "area": currentLocation,
          "latitude": "6.92", // Corrected order: latitude first
          "longitude": "79.98", // Then longitude
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

        print("Generated summary: $summary");
        return summary;
      } else {
        debugPrint("Failed to generate text");
        setState(() {
          error =
              'Failed to generate text: ${response.statusCode} - ${response.body}';
          isLoading = false;
        });
        return "";
      }
    } catch (e) {
      debugPrint("Failed to generate text ${e}");
      setState(() {
        error = 'Error fetching generated text: $e';
        isLoading = false;
      });
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final width = MediaQuery.sizeOf(context).width;
    final String formattedDate =
        DateFormat('yyyy-MM-dd – kk:mm:ss').format(DateTime.now());

    // final String generatedText = _generateRiskMessage();

    Color riskColor;
    Icon riskIcon;
    String riskMessage;

    switch (riskLevel.toLowerCase()) {
      case 'low':
        riskColor = Colors.green.shade700;
        riskIcon = const Icon(Icons.check, color: Colors.white);
        riskMessage = "Your area is safe";
        break;
      case 'moderate':
        riskColor = Colors.amber;
        riskIcon = const Icon(Icons.warning, color: Colors.white);
        riskMessage = "Your area can be dangerous";
        break;
      case 'high':
        riskColor = Colors.red.shade900;
        riskIcon = const Icon(Icons.dangerous, color: Colors.white);
        riskMessage = "Your area is not safe, please follow the guidelines";
        break;
      default:
        riskColor = Colors.grey.shade600;
        riskIcon = const Icon(Icons.help, color: Colors.white);
        riskMessage = "Unable to determine risk level";
        break;
    }

    return Container(
      height: height,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header
          Container(
            height: 80,
            width: width,
            color: Colors.amber.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "Hello User!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_pin, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        location.isNotEmpty ? location : "Unknown",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Loading or Error State
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            Container(
              width: width,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    "Error: $error",
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: fetchPrediction,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          else ...[
            // Date Info
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 10),
              child: Text(
                "Flood risk update for today: $formattedDate",
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),

            // Risk Level Banner
            if (riskLevel.isNotEmpty)
              Container(
                width: width,
                color: riskColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  children: [
                    riskIcon,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        riskMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Generated Info + Button if High Risk
            if (generatedText.isNotEmpty)
              Container(
                width: width,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      generatedText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    if (riskLevel.toLowerCase() == 'high') ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const SafeAreaDisplayScreen()),
                          );
                        },
                        icon: const Icon(Icons.place),
                        label: const Text("Please find the safe zones here"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(
                      height: 8,
                    ),

                    // Flood prone areas button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FlooedAreasScreen(
                                    severity:
                                        '${riskLevel.toLowerCase().toString()}',
                                  )),
                        );
                      },
                      icon: const Icon(Icons.place),
                      label: const Text(
                          "Please find the flooded prone areas here"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Refresh Button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: fetchPrediction,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Data"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
