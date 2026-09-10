import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  String _formatRelativeTime(dynamic createdAt) {
    if (createdAt == null) return 'recently';
    DateTime dt;
    if (createdAt is Timestamp) {
      dt = createdAt.toDate();
    } else if (createdAt is String) {
      dt = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else if (createdAt is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(createdAt);
    } else {
      return 'recently';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

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
        return const Color(0xFFfc8181);
      case 'medium':
        return const Color(0xFFf6ad55);
      case 'low':
      default:
        return const Color(0xFF68d391);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return const Color(0xFFf6ad55); // Orange
      case 'resolved':
        return const Color(0xFF68d391); // Green
      case 'false_closure':
        return const Color(0xFFfc8181); // Red
      case 'open':
      default:
        return const Color(0xFF63b3ed); // Blue
    }
  }

  Future<void> _submitVerificationPhoto(String reportId) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading verification photo...'),
          duration: Duration(seconds: 2),
        ),
      );

      final photo = File(pickedFile.path);
      final downloadUrl = await _storageService.uploadPhoto(
        photo,
        reportId,
        type: 'after',
      );

      await _firestoreService.updateReport(reportId, {
        'afterPhotoUrl': downloadUrl,
        'verificationStatus': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification photo submitted. AI is checking...'),
          backgroundColor: Color(0xFF68d391),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification upload failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF1a1a2e);
    const cardBg = Color(0xFF16213e);
    const accentBlue = Color(0xFF63b3ed);

    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CivicPulse Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: accentBlue),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading reports: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Report issues in your neighborhood to see them here',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final reportId = (report['reportId'] ?? '').toString();
              final issueType = (report['issueType'] ?? 'unknown').toString();
              final ward = (report['ward'] ?? 'Ward').toString();
              final severity = (report['severity'] ?? 'low').toString();
              final status = (report['status'] ?? 'open').toString();
              final relativeTime = _formatRelativeTime(report['createdAt']);
              final verifiedResolution = report['verifiedResolution'] as bool?;
              final photoUrl = report['photoUrl'] as String?;

              final severityColor = _getSeverityColor(severity);
              final statusColor = _getStatusColor(status);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header: icon + issue title + relative time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getIssueIcon(issueType),
                            color: accentBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${issueType.toUpperCase().replaceAll('_', ' ')} • $ward',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                relativeTime,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Photo preview if available
                    if (photoUrl != null && photoUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            photoUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),

                    // Chips Row: Severity & Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: severityColor,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor, width: 0.8),
                          ),
                          child: Text(
                            status.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Verification Actions / Chips
                    if (status.toLowerCase() == 'resolved' &&
                        verifiedResolution == null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _submitVerificationPhoto(reportId),
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.black87,
                          ),
                          label: const Text(
                            'Submit Verification Photo',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFf6e05e), // Yellow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],

                    if (verifiedResolution == true) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF68d391)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF68d391)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '✅ Verified Resolved',
                              style: TextStyle(
                                color: Color(0xFF68d391),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (verifiedResolution == false) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfc8181)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFfc8181)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '⚠️ False Closure',
                              style: TextStyle(
                                color: Color(0xFFfc8181),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'debugPipelineFab',
        backgroundColor: const Color(0xFF553C9A),
        icon: const Icon(Icons.bug_report, color: Colors.white),
        label: const Text(
          'Debug Pipeline',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          debugPrint('[DEBUG FAB] Fetching latest report from Firestore...');
          try {
            final snap = await FirebaseFirestore.instance
                .collection('reports')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get();

            if (snap.docs.isEmpty) {
              debugPrint('[DEBUG FAB] No reports found in Firestore.');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No reports found in Firestore'),
                  ),
                );
              }
              return;
            }

            final doc = snap.docs.first;
            final data = doc.data();
            final reportId = doc.id;
            final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
            final lon = (data['longitude'] as num?)?.toDouble() ?? 0.0;
            final issueType = (data['issueType'] ?? 'unknown').toString();
            final ward = (data['ward'] ?? 'unknown').toString();

            debugPrint('[DEBUG FAB] 📦 Most recent report: $reportId');
            debugPrint(
              '[DEBUG FAB] issueType=$issueType, ward=$ward, lat=$lat, lon=$lon',
            );

            await _firestoreService.triggerAgentPipeline(
              reportId,
              lat,
              lon,
              issueType,
              ward,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🚀 Pipeline triggered for $reportId — check logs',
                  ),
                  backgroundColor: const Color(0xFF553C9A),
                ),
              );
            }
          } catch (e) {
            debugPrint('[DEBUG FAB] ❌ Error: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Debug trigger failed: $e'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
