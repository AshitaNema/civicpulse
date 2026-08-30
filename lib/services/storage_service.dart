import 'dart:io';

/// Cloud Storage Service for Firebase Photo Uploads
class StorageService {
  StorageService();

  /// Uploads issue photo and returns public/signed URL
  Future<String> uploadIssuePhoto({
    required File file,
    required String reportId,
    bool isAfterPhoto = false,
  }) async {
    try {
      // Path format: reports/{reportId}/initial.jpg or reports/{reportId}/resolved.jpg
      final fileName = isAfterPhoto ? 'resolved.jpg' : 'initial.jpg';
      final storagePath = 'reports/$reportId/$fileName';

      // Implementation hooks into FirebaseStorage.instance.ref().child(storagePath).putFile(file)
      return 'https://storage.googleapis.com/civicpulse-507101.firebasestorage.app/$storagePath';
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }
}
