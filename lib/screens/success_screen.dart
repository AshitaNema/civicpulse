import 'package:flutter/material.dart';

import 'report_screen.dart';
import 'reports_list_screen.dart';

class SuccessScreen extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> classification;

  const SuccessScreen({
    super.key,
    required this.reportId,
    required this.classification,
  });

  IconData _getIssueIcon(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'pothole':
        return Icons.radio_button_unchecked;
      case 'garbage':
        return Icons.delete_outline;
      case 'streetlight':
        return Icons.lightbulb_outline;
      case 'leakage':
        return Icons.water_drop_outlined;
      case 'road_damage':
        return Icons.warning_amber_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFfc8181); // Red
      case 'medium':
        return const Color(0xFFf6ad55); // Orange
      case 'low':
      default:
        return const Color(0xFF68d391); // Green
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF1a1a2e);
    const cardBg = Color(0xFF16213e);
    const accentBlue = Color(0xFF63b3ed);
    const successGreen = Color(0xFF68d391);

    final issueType = (classification['issueType'] ?? 'unknown').toString();
    final severity = (classification['severity'] ?? 'low').toString();
    final confidenceNum = (classification['confidence'] is num)
        ? (classification['confidence'] as num).toDouble()
        : 0.0;
    final confidencePercent = (confidenceNum * 100).toInt();
    final description = (classification['description'] ?? 'No description').toString();

    final severityColor = _getSeverityColor(severity);

    return Scaffold(
      backgroundColor: primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(),

              // Green checkmark
              const Icon(
                Icons.check_circle,
                size: 80,
                color: successGreen,
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Report Submitted!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your civic report is being routed to municipal teams',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Report ID Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag, color: accentBlue, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      reportId,
                      style: const TextStyle(
                        color: accentBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Classification Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white10,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getIssueIcon(issueType),
                              color: accentBlue,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              issueType.toUpperCase().replaceAll('_', ' '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: severityColor),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFf6e05e),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Confidence: $confidencePercent%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '"$description"',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Report Another Issue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsListScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View All Reports',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
