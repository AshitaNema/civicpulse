/// CivicPulse Citizen Report Model
class ReportModel {
  final String reportId;
  final String citizenId;
  final String photoUrl;
  final String? afterPhotoUrl;
  final double latitude;
  final double longitude;
  final String ward;
  final String issueType; // pothole | garbage | streetlight | leakage | road_damage
  final String severity; // low | medium | critical
  final String status; // open | in_progress | resolved | false_closure
  final String department;
  final bool isDuplicate;
  final String? parentReportId;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final bool? verifiedResolution;
  final String? verificationNotes;

  const ReportModel({
    required this.reportId,
    required this.citizenId,
    required this.photoUrl,
    this.afterPhotoUrl,
    required this.latitude,
    required this.longitude,
    required this.ward,
    required this.issueType,
    required this.severity,
    required this.status,
    required this.department,
    this.isDuplicate = false,
    this.parentReportId,
    required this.createdAt,
    this.resolvedAt,
    this.verifiedResolution,
    this.verificationNotes,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      // Handle Firestore Timestamp like object dynamically
      try {
        if (value.toDate != null) {
          return value.toDate() as DateTime;
        }
      } catch (_) {}
      return DateTime.now();
    }

    DateTime? parseNullableTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      try {
        if (value.toDate != null) {
          return value.toDate() as DateTime;
        }
      } catch (_) {}
      return null;
    }

    return ReportModel(
      reportId: (id != null && id.isNotEmpty) ? id : (map['reportId'] as String? ?? ''),
      citizenId: map['citizenId'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      afterPhotoUrl: map['afterPhotoUrl'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ward: map['ward'] as String? ?? '',
      issueType: map['issueType'] as String? ?? 'pothole',
      severity: map['severity'] as String? ?? 'low',
      status: map['status'] as String? ?? 'open',
      department: map['department'] as String? ?? 'unassigned',
      isDuplicate: map['isDuplicate'] as bool? ?? false,
      parentReportId: map['parentReportId'] as String?,
      createdAt: parseTimestamp(map['createdAt']),
      resolvedAt: parseNullableTimestamp(map['resolvedAt']),
      verifiedResolution: map['verifiedResolution'] as bool?,
      verificationNotes: map['verificationNotes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'citizenId': citizenId,
      'photoUrl': photoUrl,
      'afterPhotoUrl': afterPhotoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'ward': ward,
      'issueType': issueType,
      'severity': severity,
      'status': status,
      'department': department,
      'isDuplicate': isDuplicate,
      'parentReportId': parentReportId,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'verifiedResolution': verifiedResolution,
      'verificationNotes': verificationNotes,
    };
  }

  ReportModel copyWith({
    String? reportId,
    String? citizenId,
    String? photoUrl,
    String? afterPhotoUrl,
    double? latitude,
    double? longitude,
    String? ward,
    String? issueType,
    String? severity,
    String? status,
    String? department,
    bool? isDuplicate,
    String? parentReportId,
    DateTime? createdAt,
    DateTime? resolvedAt,
    bool? verifiedResolution,
    String? verificationNotes,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      citizenId: citizenId ?? this.citizenId,
      photoUrl: photoUrl ?? this.photoUrl,
      afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ward: ward ?? this.ward,
      issueType: issueType ?? this.issueType,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      department: department ?? this.department,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      parentReportId: parentReportId ?? this.parentReportId,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      verifiedResolution: verifiedResolution ?? this.verifiedResolution,
      verificationNotes: verificationNotes ?? this.verificationNotes,
    );
  }
}
