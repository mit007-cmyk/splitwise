import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'app_logger.dart';

@singleton
class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final AppLogger _logger;

  StorageService(this._logger);

  /// Uploads a local [File] to the specified storage path and returns its download URL
  Future<String> uploadFile({
    required String storagePath,
    required File file,
    Map<String, String>? metadata,
  }) async {
    try {
      _logger.d('Starting upload for file to storage path: $storagePath');
      final ref = _storage.ref().child(storagePath);
      
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(customMetadata: metadata),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.d('File upload successful. Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      _logger.e('Firebase Storage uploadFile failed: $storagePath', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a file from Storage by its direct path or download URL
  Future<void> deleteFile(String urlOrPath) async {
    try {
      Reference ref;
      if (urlOrPath.startsWith('http') || urlOrPath.startsWith('gs://')) {
        ref = _storage.refFromURL(urlOrPath);
      } else {
        ref = _storage.ref().child(urlOrPath);
      }
      
      _logger.d('Deleting storage item: ${ref.fullPath}');
      await ref.delete();
    } catch (e, stackTrace) {
      _logger.e('Firebase Storage deleteFile failed: $urlOrPath', e, stackTrace);
      rethrow;
    }
  }
}
