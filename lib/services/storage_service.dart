import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image to Firebase Storage
  /// 
  /// [file] - The image file to upload
  /// [path] - Storage path (e.g., 'recipes/user123/image.jpg')
  /// Returns the download URL of the uploaded image
  Future<String> uploadImage(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploaded': DateTime.now().toIso8601String()},
        ),
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      if (kDebugMode) {
        print('✅ Image uploaded successfully: $downloadUrl');
      }
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading image: $e');
      }
      rethrow;
    }
  }

  /// Upload a recipe image
  /// Automatically organizes by userId and generates unique filename
  Future<String> uploadRecipeImage(File file, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'recipe_$timestamp.jpg';
    final path = 'recipes/$userId/$filename';
    
    return await uploadImage(file, path);
  }

  /// Upload a user profile picture
  Future<String> uploadProfilePicture(File file, String userId) async {
    final path = 'profiles/$userId/profile.jpg';
    return await uploadImage(file, path);
  }

  /// Delete an image from Firebase Storage
  /// 
  /// [url] - The download URL of the image to delete
  Future<void> deleteImageByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      
      if (kDebugMode) {
        print('✅ Image deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting image: $e');
      }
      rethrow;
    }
  }

  /// Delete an image by path
  /// 
  /// [path] - Storage path (e.g., 'recipes/user123/image.jpg')
  Future<void> deleteImageByPath(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      
      if (kDebugMode) {
        print('✅ Image deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting image: $e');
      }
      rethrow;
    }
  }

  /// List all images in a directory
  /// 
  /// [path] - Directory path (e.g., 'recipes/user123/')
  /// Returns a list of download URLs
  Future<List<String>> listImages(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();
      
      final urls = <String>[];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error listing images: $e');
      }
      rethrow;
    }
  }

  /// Get metadata for an image
  Future<FullMetadata> getMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getMetadata();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting metadata: $e');
      }
      rethrow;
    }
  }
}
