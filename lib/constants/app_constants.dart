/// App Constants for CivicPulse
class AppConstants {
  AppConstants._();

  // GCP & Firebase
  static const String gcpProjectId = 'civicpulse-507101';
  static const String gcpRegion = 'us-central1';
  static const String bigQueryDataset = 'civicpulse_data';

  // Firestore Collections
  static const String collectionReports = 'reports';
  static const String collectionDepartments = 'departments';
  static const String collectionPredictions = 'predictions';
}

/// Allowed Issue Types in CivicPulse
class IssueType {
  IssueType._();

  static const String pothole = 'pothole';
  static const String garbage = 'garbage';
  static const String streetlight = 'streetlight';
  static const String leakage = 'leakage';
  static const String roadDamage = 'road_damage';

  static const List<String> all = [
    pothole,
    garbage,
    streetlight,
    leakage,
    roadDamage,
  ];

  static String displayName(String issueType) {
    switch (issueType) {
      case pothole:
        return 'Pothole';
      case garbage:
        return 'Garbage / Dump';
      case streetlight:
        return 'Streetlight Issue';
      case leakage:
        return 'Water Leakage';
      case roadDamage:
        return 'Road Damage';
      default:
        return issueType;
    }
  }
}

/// Issue Severity Levels
class IssueSeverity {
  IssueSeverity._();

  static const String low = 'low';
  static const String medium = 'medium';
  static const String critical = 'critical';

  static const List<String> all = [low, medium, critical];

  static String displayName(String severity) {
    switch (severity) {
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case critical:
        return 'Critical';
      default:
        return severity;
    }
  }
}

/// Report Status Transitions
class ReportStatus {
  ReportStatus._();

  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String falseClosure = 'false_closure';

  static const List<String> all = [
    open,
    inProgress,
    resolved,
    falseClosure,
  ];

  static String displayName(String status) {
    switch (status) {
      case open:
        return 'Open';
      case inProgress:
        return 'In Progress';
      case resolved:
        return 'Resolved';
      case falseClosure:
        return 'False Closure';
      default:
        return status;
    }
  }
}
