import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPhoto(
    File photo,
    String reportId, {
    String type = 'before',
  }) async {
    try {
      final path = 'reports/$reportId/$type.jpg';
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(
        photo,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo ($type): ${e.toString()}');
    }
  }
}
