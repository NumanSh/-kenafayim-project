import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';

class ImageService {
  Future<String?> uploadImage(String imagePath) async {
    try {
      final XFile imageFile = XFile(imagePath);
      final String? cloudUrl = await _uploadToFirebaseStorage(
        imageFile,
        'lesson_image_${DateTime.now().millisecondsSinceEpoch}',
      );
      return cloudUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading image: $e');
      }
      return null;
    }
  }

  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ENHANCED: Pick and save image with cloud sync + local cache
  static Future<String?> pickAndSaveImage({
    required String lessonId,
    ImageSource source = ImageSource.gallery,
    bool uploadToCloud = true, // New parameter for cloud upload
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (uploadToCloud) {
          // NEW: Upload to Firebase Storage for cross-device sync
          final String? cloudUrl = await _uploadToFirebaseStorage(
            pickedFile,
            lessonId,
          );
          if (cloudUrl != null) {
            // Also save locally for offline access
            await _saveImageToAppDirectory(pickedFile, lessonId);
            if (kDebugMode) {
              print('✅ Image uploaded to cloud: $cloudUrl');
            }
            return cloudUrl; // Return cloud URL
          }
        }

        // Fallback: Save locally only
        final String localPath = await _saveImageToAppDirectory(
          pickedFile,
          lessonId,
        );
        if (kDebugMode) {
          print('✅ Image saved locally: $localPath');
        }
        return localPath;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      return null;
    }
  }

  // NEW: Upload image to Firebase Storage
  static Future<String?> _uploadToFirebaseStorage(
    XFile imageFile,
    String lessonId,
  ) async {
    try {
      print('🔍 IMAGE: Starting upload for lesson: $lessonId');

      // Create unique file name
      final String fileName =
          'lesson_${lessonId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'lesson_images/$fileName';

      // Create storage reference
      final Reference ref = _storage.ref().child(filePath);

      // Upload file
      UploadTask uploadTask;

      if (kIsWeb) {
        // For web: upload as bytes
        final Uint8List imageBytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // For mobile: upload as file
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadURL = await snapshot.ref.getDownloadURL();

      print('🔍 IMAGE: Upload successful. URL: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('🔍 IMAGE: Upload failed: $e');
      return null;
    }
  }

  // EXISTING: Save image to local app directory (for caching)
  static Future<String> _saveImageToAppDirectory(
    XFile pickedFile,
    String lessonId,
  ) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory lessonImagesDir = Directory(
      '${appDocDir.path}/lesson_images',
    );

    // Create directory if it doesn't exist
    if (!await lessonImagesDir.exists()) {
      await lessonImagesDir.create(recursive: true);
    }

    // Clean lesson ID for filename
    final cleanLessonId = lessonId.replaceAll(RegExp(r'[^\w\-_]'), '_');
    final String fileExtension = path.extension(pickedFile.path);
    final String fileName = 'lesson_${cleanLessonId}_bg$fileExtension';
    final String savedPath = '${lessonImagesDir.path}/$fileName';

    // Delete existing image if it exists
    final File existingFile = File(savedPath);
    if (await existingFile.exists()) {
      await existingFile.delete();
    }

    // Copy file to app directory
    final File sourceFile = File(pickedFile.path);
    await sourceFile.copy(savedPath);

    if (kDebugMode) {
      print('✅ Image cached locally: $savedPath');
    }

    return savedPath;
  }

  // ENHANCED: Delete image (both cloud and local)
  static Future<bool> deleteImage(String imagePath) async {
    try {
      bool success = true;

      // If it's a Firebase URL, delete from cloud
      if (imagePath.contains('firebasestorage.googleapis.com')) {
        try {
          final Reference ref = _storage.refFromURL(imagePath);
          await ref.delete();
          print('✅ Image deleted from cloud');
        } catch (e) {
          print('❌ Error deleting from cloud: $e');
          success = false;
        }
      } else {
        // Delete local file
        final File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
          print('✅ Local image deleted');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting image: $e');
      }
      return false;
    }
  }

  // ENHANCED: Check if image exists (cloud or local)
  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;

    try {
      if (imagePath.contains('firebasestorage.googleapis.com')) {
        // For cloud images, assume they exist (Firebase handles this)
        return true;
      } else {
        // Check local file
        final File imageFile = File(imagePath);
        return await imageFile.exists();
      }
    } catch (e) {
      return false;
    }
  }

  // NEW: Download and cache cloud image locally
  static Future<String?> downloadAndCacheImage(
    String cloudUrl,
    String lessonId,
  ) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory lessonImagesDir = Directory(
        '${appDocDir.path}/lesson_images',
      );

      if (!await lessonImagesDir.exists()) {
        await lessonImagesDir.create(recursive: true);
      }

      final cleanLessonId = lessonId.replaceAll(RegExp(r'[^\w\-_]'), '_');
      final String fileName = 'lesson_${cleanLessonId}_cached.jpg';
      final String localPath = '${lessonImagesDir.path}/$fileName';

      // Download from Firebase Storage
      final Reference ref = _storage.refFromURL(cloudUrl);
      final File localFile = File(localPath);

      await ref.writeToFile(localFile);

      print('✅ Image cached locally from cloud: $localPath');
      return localPath;
    } catch (e) {
      print('❌ Error caching image: $e');
      return null;
    }
  }

  // NEW: Profile image methods
  static Future<String?> pickAndSaveProfileImage({
    required String userId,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        // Upload profile image to cloud
        final String? cloudUrl = await _uploadProfileToFirebaseStorage(
          pickedFile,
          userId,
        );
        if (cloudUrl != null) {
          print('✅ Profile image uploaded: $cloudUrl');
          return cloudUrl;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error picking profile image: $e');
      return null;
    }
  }

  static Future<String?> _uploadProfileToFirebaseStorage(
    XFile imageFile,
    String userId,
  ) async {
    try {
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'profile_images/$fileName';

      final Reference ref = _storage.ref().child(filePath);

      UploadTask uploadTask;
      if (kIsWeb) {
        final Uint8List imageBytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('❌ Profile upload failed: $e');
      return null;
    }
  }

  // EXISTING: Get app images directory
  static Future<Directory> getImagesDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory lessonImagesDir = Directory(
      '${appDocDir.path}/lesson_images',
    );

    if (!await lessonImagesDir.exists()) {
      await lessonImagesDir.create(recursive: true);
    }

    return lessonImagesDir;
  }
}
