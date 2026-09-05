import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateReportId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomSuffix = List.generate(
      4,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'CP-$timestamp-$randomSuffix';
  }

  Future<String> createReport(Map<String, dynamic> data) async {
    try {
      final reportId = _generateReportId();
      final reportData = Map<String, dynamic>.from(data);
      reportData['reportId'] = reportId;

      await _firestore.collection('reports').doc(reportId).set(reportData);
      return reportId;
    } catch (e) {
      throw Exception('Failed to create report in Firestore: ${e.toString()}');
    }
  }

  Future<void> triggerAgentPipeline(
    String reportId,
    double lat,
    double lon,
    String issueType,
    String ward,
  ) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080';
      final url = Uri.parse('$baseUrl/webhook/new-report');
      final payload = {
        'message': {
          'data': base64Encode(
            utf8.encode(
              json.encode({
                'reportId': reportId,
                'latitude': lat,
                'longitude': lon,
                'issueType': issueType,
                'ward': ward,
              }),
            ),
          ),
        },
      };
      debugPrint('[FirestoreService] 🚀 Triggering agent pipeline for reportId: $reportId');
      debugPrint('[FirestoreService] 🌐 POST → $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      debugPrint('[FirestoreService] ✅ Pipeline response — status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[FirestoreService] ❌ Pipeline failure body: ${response.body}');
      }
    } catch (e) {
      // Gracefully handle offline or network delays
      debugPrint('[FirestoreService] ❌ Pipeline trigger exception: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['reportId'] = doc.id;
            return data;
          }).toList();
        });
  }

  Future<void> updateReport(String reportId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('reports').doc(reportId).update(data);
    } catch (e) {
      throw Exception('Failed to update report $reportId: ${e.toString()}');
    }
  }
}
