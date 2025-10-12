import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isSuccess = false;
  String? error;

  // Mock feedback history - replace with actual API call
  List<Map<String, dynamic>> feedbackHistory = [];

  static const String baseUrl = 'http://192.168.1.100:5000';

  @override
  void initState() {
    super.initState();
    // _loadFeedbackHistory();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // Future<void> _loadFeedbackHistory() async {
  //   // TODO: Replace with actual API call to fetch user's feedback history
  //   // For now, using mock data
  //   setState(() {
  //     feedbackHistory = [
  //       {
  //         'feedback': 'Great service! Very helpful during emergency.',
  //         'date': '2025-10-10',
  //         'status': 'Reviewed'
  //       },
  //       {
  //         'feedback': 'Response time could be improved.',
  //         'date': '2025-10-08',
  //         'status': 'Pending'
  //       },
  //     ];
  //   });
  // }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      error = null;
      isSuccess = false;
    });

    final uri = Uri.parse('$baseUrl/add-a-new-feedback');

    try {
      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({"feedback": _feedbackController.text.trim()}),
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _feedbackController.clear();
        // _loadFeedbackHistory(); // Refresh feedback list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  "Share Your Feedback",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Help us improve our emergency response services",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Feedback Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Write your feedback",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _feedbackController,
                          maxLines: 6,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: "Tell us about your experience...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your feedback';
                            }
                            if (value.trim().length < 10) {
                              return 'Feedback must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    error!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _submitFeedback,
                            icon: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                                isLoading ? "Sending..." : "Submit Feedback"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Feedback Categories
                const Text(
                  "Quick Feedback",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickFeedbackChip(
                        "Excellent Service", Icons.thumb_up),
                    _buildQuickFeedbackChip("Fast Response", Icons.speed),
                    _buildQuickFeedbackChip("Very Helpful", Icons.favorite),
                    _buildQuickFeedbackChip(
                        "Needs Improvement", Icons.warning_amber),
                    _buildQuickFeedbackChip(
                        "Poor Experience", Icons.thumb_down),
                  ],
                ),

                const SizedBox(height: 32),

                // Feedback History
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     const Text(
                //       "Your Previous Feedback",
                //       style: TextStyle(
                //         fontSize: 18,
                //         fontWeight: FontWeight.bold,
                //         color: Colors.black87,
                //       ),
                //     ),
                //     TextButton(
                //       onPressed: _loadFeedbackHistory,
                //       child: const Text("Refresh"),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 12),

                // if (feedbackHistory.isEmpty)
                // Container(
                //   padding: const EdgeInsets.all(40),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(16),
                //   ),
                //   child: Center(
                //     child: Column(
                //       children: [
                //         Icon(
                //           Icons.feedback_outlined,
                //           size: 64,
                //           color: Colors.grey.shade300,
                //         ),
                //         const SizedBox(height: 16),
                //         Text(
                //           "No feedback history yet",
                //           style: TextStyle(
                //             fontSize: 16,
                //             color: Colors.grey.shade600,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // )
                // else
                //   ListView.builder(
                //     shrinkWrap: true,
                //     physics: const NeverScrollableScrollPhysics(),
                //     itemCount: feedbackHistory.length,
                //     itemBuilder: (context, index) {
                //       final feedback = feedbackHistory[index];
                //       return _buildFeedbackCard(
                //         feedback['feedback'],
                //         feedback['date'],
                //         feedback['status'],
                //       );
                //     },
                //   ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFeedbackChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        setState(() {
          _feedbackController.text = label;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$label" to your feedback'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildFeedbackCard(String feedback, String date, String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'reviewed':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                date,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
