import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civicpulse/screens/home_screen.dart';
import 'package:civicpulse/screens/success_screen.dart';
import 'package:civicpulse/models/report_model.dart';

void main() {
  testWidgets('HomeScreen renders with branding and navigation buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    expect(find.text('CivicPulse'), findsOneWidget);
    expect(find.text('Report. Predict. Verify.'), findsOneWidget);
    expect(find.text('Report an Issue'), findsOneWidget);
    expect(find.text('View Reports'), findsOneWidget);
  });

  testWidgets('SuccessScreen displays classification and report info', (
    WidgetTester tester,
  ) async {
    final mockClassification = {
      'issueType': 'pothole',
      'severity': 'critical',
      'confidence': 0.94,
      'description': 'Severe deep asphalt pothole on main road.',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: SuccessScreen(
          reportId: 'CP-1725460000000-TEST',
          classification: mockClassification,
        ),
      ),
    );

    expect(find.text('Report Submitted!'), findsOneWidget);
    expect(find.text('CP-1725460000000-TEST'), findsOneWidget);
    expect(find.text('POTHOLE'), findsOneWidget);
    expect(find.text('CRITICAL'), findsOneWidget);
    expect(find.text('AI Confidence: 94%'), findsOneWidget);
    expect(find.text('Report Another Issue'), findsOneWidget);
    expect(find.text('View All Reports'), findsOneWidget);
  });

  test('ReportModel serializes and deserializes properly', () {
    final now = DateTime.now();
    final model = ReportModel(
      reportId: 'CP-12345-ABCD',
      citizenId: 'user_001',
      photoUrl: 'https://example.com/photo.jpg',
      latitude: 37.422,
      longitude: -122.084,
      ward: 'Ward_4',
      issueType: 'garbage',
      severity: 'medium',
      status: 'open',
      department: 'Sanitation Dept',
      createdAt: now,
    );

    final map = model.toMap();
    expect(map['reportId'], 'CP-12345-ABCD');
    expect(map['issueType'], 'garbage');
    expect(map['severity'], 'medium');

    final parsed = ReportModel.fromMap(map, 'CP-12345-ABCD');
    expect(parsed.reportId, 'CP-12345-ABCD');
    expect(parsed.ward, 'Ward_4');
    expect(parsed.issueType, 'garbage');
  });
}
