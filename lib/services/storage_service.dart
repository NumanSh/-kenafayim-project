import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();

  StorageService({FirebaseStorage? storage}) 
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadFile(File file, String path) async {
    try {
      final fileName = '${_uuid.v4()}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$path/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<String> uploadProfileImage({required File file, required String userId}) async {
    return uploadFile(file, 'profile_images/$userId');
  }

  Future<String> uploadReportAttachment(File file, String reportId) async {
    return uploadFile(file, 'report_attachments/$reportId');
  }

  Future<String> uploadMessageAttachment(File file, String messageId) async {
    return uploadFile(file, 'message_attachments/$messageId');
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  Future<List<String>> getFilesInFolder(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final result = await ref.listAll();
      
      final urls = <String>[];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Failed to get files in folder: $e');
    }
  }

  Future<String?> pickAndUploadImage({
    required String userId,
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      final file = File(pickedFile.path);
      return await uploadProfileImage(file: file, userId: userId);
    } catch (e) {
      throw Exception('Failed to pick and upload image: $e');
    }
  }
}
