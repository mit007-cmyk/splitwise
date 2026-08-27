import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class CurrentUserIdProvider {
  String? get userId;
}

@LazySingleton(as: CurrentUserIdProvider)
class FirebaseCurrentUserIdProvider implements CurrentUserIdProvider {
  @override
  String? get userId {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return null;
      return uid;
    } catch (_) {
      return null;
    }
  }
}
