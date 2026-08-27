import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../constants/app_constants.dart';
import '../../../services/firestore_service.dart';
import '../models/device_token_model.dart';

abstract class DeviceTokenRemoteDataSource {
  Future<void> upsertDevice({
    required String userId,
    required DeviceTokenModel token,
  });

  Future<void> deactivateDevice({
    required String userId,
    required String deviceId,
  });
}

@LazySingleton(as: DeviceTokenRemoteDataSource)
class DeviceTokenRemoteDataSourceImpl implements DeviceTokenRemoteDataSource {
  DeviceTokenRemoteDataSourceImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> upsertDevice({
    required String userId,
    required DeviceTokenModel token,
  }) async {
    final key = FirestorePaths.deviceRecordKey(userId, token.deviceId);
    final existing = await _record(key);

    final record = <String, dynamic>{
      ...token.toJson(),
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (existing == null) {
      record['createdAt'] = FieldValue.serverTimestamp();
    } else {
      record['createdAt'] = existing['createdAt'];
    }

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.devices,
      {key: record},
      merge: true,
    );
  }

  @override
  Future<void> deactivateDevice({
    required String userId,
    required String deviceId,
  }) async {
    final key = FirestorePaths.deviceRecordKey(userId, deviceId);
    final existing = await _record(key);
    if (existing == null) return;

    existing['isActive'] = false;
    existing['updatedAt'] = FieldValue.serverTimestamp();

    await _firestoreService.setDocument(
      FirestorePaths.root,
      FirestorePaths.devices,
      {key: existing},
      merge: true,
    );
  }

  Future<Map<String, dynamic>?> _record(String key) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.root,
      FirestorePaths.devices,
    );
    final raw = doc.data()?[key];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }
}
