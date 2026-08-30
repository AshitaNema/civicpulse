/// CivicPulse Department Routing Model
class DepartmentModel {
  final String deptId;
  final String name;
  final String contactEmail;
  final List<String> wardCoverage;
  final List<String> supportedCategories;

  const DepartmentModel({
    required this.deptId,
    required this.name,
    required this.contactEmail,
    required this.wardCoverage,
    required this.supportedCategories,
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return DepartmentModel(
      deptId: (id != null && id.isNotEmpty) ? id : (map['deptId'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      contactEmail: map['contactEmail'] as String? ?? '',
      wardCoverage: List<String>.from(map['wardCoverage'] as List? ?? []),
      supportedCategories: List<String>.from(map['supportedCategories'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deptId': deptId,
      'name': name,
      'contactEmail': contactEmail,
      'wardCoverage': wardCoverage,
      'supportedCategories': supportedCategories,
    };
  }
}
