/// CivicPulse BigQuery ML Risk Zone Prediction Model
class PredictionModel {
  final String predId;
  final String ward;
  final double riskScore;
  final String predictedIssueType;
  final DateTime generatedAt;

  const PredictionModel({
    required this.predId,
    required this.ward,
    required this.riskScore,
    required this.predictedIssueType,
    required this.generatedAt,
  });

  factory PredictionModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      try {
        if (value.toDate != null) {
          return value.toDate() as DateTime;
        }
      } catch (_) {}
      return DateTime.now();
    }

    return PredictionModel(
      predId: (id != null && id.isNotEmpty) ? id : (map['predId'] as String? ?? ''),
      ward: map['ward'] as String? ?? '',
      riskScore: (map['riskScore'] as num?)?.toDouble() ?? 0.0,
      predictedIssueType: map['predictedIssueType'] as String? ?? '',
      generatedAt: parseDate(map['generatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'predId': predId,
      'ward': ward,
      'riskScore': riskScore,
      'predictedIssueType': predictedIssueType,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
