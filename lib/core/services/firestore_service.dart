import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'app_logger.dart';

@singleton
class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseFirestore get firestore => _firestore;
  final AppLogger _logger;

  FirestoreService(this._logger);

  /// Get a single document by its path
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collectionPath,
    String documentId,
  ) async {
    try {
      return await _firestore.collection(collectionPath).doc(documentId).get();
    } catch (e, stackTrace) {
      _logger.e(
        'Firestore getDocument failed: $collectionPath/$documentId (${_describeError(e)})',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  String _describeError(Object error) {
    if (error is FirebaseException) {
      return '${error.code}: ${error.message ?? error.toString()}';
    }
    return error.toString();
  }

  /// Create or overwrite a document
  Future<void> setDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      await _firestore
          .collection(collectionPath)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));
    } catch (e, stackTrace) {
      _logger.e('Firestore setDocument failed: $collectionPath/$documentId', e, stackTrace);
      rethrow;
    }
  }

  /// Add a document with auto-generated ID
  Future<DocumentReference<Map<String, dynamic>>> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _firestore.collection(collectionPath).add(data);
    } catch (e, stackTrace) {
      _logger.e('Firestore addDocument failed: $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  /// Update an existing document
  Future<void> updateDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).update(data);
    } catch (e, stackTrace) {
      _logger.e('Firestore updateDocument failed: $collectionPath/$documentId', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String collectionPath, String documentId) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).delete();
    } catch (e, stackTrace) {
      _logger.e('Firestore deleteDocument failed: $collectionPath/$documentId', e, stackTrace);
      rethrow;
    }
  }

  /// Listen to document changes in real-time
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(
    String collectionPath,
    String documentId,
  ) {
    return _firestore.collection(collectionPath).doc(documentId).snapshots();
  }

  /// Query a collection and retrieve documents
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    String collectionPath, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return await query.get();
    } catch (e, stackTrace) {
      _logger.e('Firestore getCollection failed: $collectionPath', e, stackTrace);
      rethrow;
    }
  }

  /// Listen to collection changes in real-time
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collectionPath, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  /// Run a transaction
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) updateFunction) {
    return _firestore.runTransaction(updateFunction);
  }

  /// Run a write batch
  WriteBatch batch() => _firestore.batch();
}
