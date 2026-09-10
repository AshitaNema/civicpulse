import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  Future<Map<String, dynamic>> classifyIssue(File photo) async {
    final defaultFallback = {
      'issueType': 'unknown',
      'severity': 'low',
      'confidence': 0.0,
      'description': 'Could not classify',
    };

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint(
          '[GeminiService] ❌ GEMINI_API_KEY is missing or empty in .env',
        );
        return defaultFallback;
      }
      debugPrint('[GeminiService] ✅ API key loaded (length: ${apiKey.length})');

      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey',
      );

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              },
              {
                'text': 'You are a civic issue classifier. Look at this image and return ONLY a valid JSON object with no markdown, no explanation, just JSON: {"issueType": "pothole|garbage|streetlight|leakage|road_damage", "severity": "low|medium|critical", "confidence": 0.0-1.0, "description": "max 15 words"}',
              },
            ],
          },
        ],
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[GeminiService] ❌ Gemini API error — status: ${response.statusCode}',
        );
        debugPrint('[GeminiService] ❌ Response body: ${response.body}');
        return defaultFallback;
      }
      debugPrint('[GeminiService] ✅ Gemini API responded 200 OK');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return defaultFallback;
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return defaultFallback;
      }

      var text = parts[0]['text'] as String? ?? '';
      text = text.trim();

      // Strip markdown code fences if present
      if (text.startsWith('```json')) {
        text = text.substring(7);
      } else if (text.startsWith('```')) {
        text = text.substring(3);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();

      final parsed = jsonDecode(text) as Map<String, dynamic>;
      return {
        'issueType': parsed['issueType'] ?? 'unknown',
        'severity': parsed['severity'] ?? 'low',
        'confidence': (parsed['confidence'] is num)
            ? (parsed['confidence'] as num).toDouble()
            : 0.8,
        'description': parsed['description'] ?? 'Civic issue detected',
      };
    } catch (e, stackTrace) {
      debugPrint('[GeminiService] ❌ Exception during classifyIssue: $e');
      debugPrint('[GeminiService] StackTrace: $stackTrace');
      return defaultFallback;
    }
  }
}
