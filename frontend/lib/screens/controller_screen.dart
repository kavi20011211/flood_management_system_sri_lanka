import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/screens/home_page.dart';
import 'package:http/http.dart' as http;

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  @override
  Widget build(BuildContext context) {
    bool isLoading = true;
    bool isSuccess = false;
    String? error;

    // API base URL - consider moving this to a config file
    const String baseUrl = 'http://192.168.8.172:5000';

    Future<void> sendFeedback(String feedback) async {
      setState(() {
        isLoading = true;
        error = null;
      });

      final uri = Uri.parse('$baseUrl/add-a-new-feedback');

      try {
        // Add timeout to HTTP request
        final response = await http
            .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({"feedback": feedback}),
        )
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (response.statusCode == 200) {
          debugPrint("SEND ${response.body}");
          setState(() {
            isLoading = false;
            isSuccess = true;
          });
        } else {
          setState(() {
            error = 'Failed to send feedback: ${response.statusCode}';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          error = 'Error sending feedback: ${e.toString()}';
          isLoading = false;
        });
        debugPrint("POST error: $e");
      }
    }

    void _showFeedbackDialog() {
      final TextEditingController _feedbackController = TextEditingController();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Enter Your Feedback about the service"),
            content: TextField(
              controller: _feedbackController,
              decoration:
                  const InputDecoration(hintText: "Enter your feedback here"),
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
                child: const Text("Send"),
                onPressed: () async {
                  await sendFeedback(_feedbackController.text.trim());
                  if (isSuccess) {
                    _feedbackController.text = "";
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Flood management app",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        actions: <Widget>[
          IconButton(
              onPressed: () {
                _showFeedbackDialog();
              },
              icon: Icon(
                Icons.feedback,
                color: Colors.white,
              ))
        ],
      ),
      body: HomePage(),
    );
  }
}
