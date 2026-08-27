import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class AuthUserIdChanges {
  Stream<String?> get userIds;
}

@LazySingleton(as: AuthUserIdChanges)
class FirebaseAuthUserIdChanges implements AuthUserIdChanges {
  @override
  Stream<String?> get userIds {
    try {
      return FirebaseAuth.instance.authStateChanges().map((user) {
        final uid = user?.uid;
        if (uid == null || uid.isEmpty) return null;
        return uid;
      });
    } catch (_) {
      return const Stream<String?>.empty();
    }
  }
}
