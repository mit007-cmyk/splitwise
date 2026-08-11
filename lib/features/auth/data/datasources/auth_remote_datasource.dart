import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/app_logger.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../friends/data/datasources/friends_remote_datasource.dart';
import '../../../../core/utils/friend_code_generator.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// Sign in user remotely
  Future<UserModel> login({required String email, required String password});

  /// Sign in user remotely via Google
  Future<UserModel> loginWithGoogle();

  /// Sign up user remotely
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Sign out user remotely
  Future<void> logout();

  /// Retrieve current remote authenticated user (if any)
  Future<UserModel?> getCurrentUser();

  /// Observe remote auth status stream changes
  Stream<UserModel?> watchAuthState();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final HiveService _hiveService;
  final AppLogger _logger;
  final FirestoreService _firestoreService;
  final FriendsRemoteDataSource _friendsRemoteDataSource;

  // Use a lazy getter to prevent startup crashes when Firebase is not active
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Web OAuth 2.0 client ID (client_type 3 from google-services.json)
  // Required by google_sign_in_web on Flutter Web
  static const _webClientId =
      '1094838385635-st86qptmi9spiuceiqffdjigc272j8q9.apps.googleusercontent.com';

  GoogleSignIn get _googleSignIn => GoogleSignIn(
        clientId: kIsWeb ? _webClientId : null,
        scopes: ['email', 'profile'],
      );

  // Key to store mock users database locally when Firebase is disabled
  static const String _mockDbBox = 'settings_box';
  static const String _mockUsersKey = 'mock_users_list';
  
  // Stream controller to broadcast mock auth state changes
  final StreamController<UserModel?> _mockAuthStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentMockUser;

  AuthRemoteDataSourceImpl(
    this._hiveService,
    this._logger,
    this._firestoreService,
    this._friendsRemoteDataSource,
  );

  bool get _isFirebaseActive {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    
    if (_isFirebaseActive) {
      try {
        _logger.d('AuthRemoteDataSource: Login via FirebaseAuth -> $cleanEmail');
        final credential = await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        
        final user = credential.user;
        if (user == null) {
          throw const AuthException(message: 'Authentication failed');
        }
        
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? cleanEmail,
          name: user.displayName ?? cleanEmail.split('@')[0],
          photoUrl: user.photoURL,
        );

        // Sync to Firestore 'Splitwise/users' document as a merged field
        await _firestoreService.setDocument(
          'Splitwise',
          'users',
          {
            userModel.id: {
              ...userModel.toJson(),
              'updatedAt': FieldValue.serverTimestamp(),
            }
          },
          merge: true,
        );

        await _friendsRemoteDataSource.linkPendingContactsForUser(
          userId: userModel.id,
          email: userModel.email,
        );

        return _friendsRemoteDataSource.ensureFriendCodeForUser(userModel);
      } on FirebaseAuthException catch (e) {
        _logger.e('FirebaseAuth login failed', e);
        throw AuthException(message: e.message ?? 'Login failed', code: e.code);
      }
    } else {
      // Mock Local Failover
      _logger.d('AuthRemoteDataSource: Login via Mock Local Failover -> $cleanEmail');
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay
      
      final users = _getMockUsers();
      final userMap = users[cleanEmail];
      
      if (userMap == null || userMap['password'] != password) {
        throw const AuthException(message: 'Invalid email or password.');
      }
      
      final user = await _ensureMockFriendCode(
        UserModel.fromJson(Map<String, dynamic>.from(userMap)),
        cleanEmail,
        users,
        userMap['password'] as String,
      );
      _currentMockUser = user;
      _mockAuthStateController.add(user);
      return user;
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    if (_isFirebaseActive) {
      try {
        _logger.d('AuthRemoteDataSource: Google Sign-In init (web=$kIsWeb)');

        User? user;

        if (kIsWeb) {
          // Sign out of Firebase first so Google doesn't auto-reuse the previous session.
          // This forces Chrome to show the full account picker every time.
          await _auth.signOut();

          final provider = GoogleAuthProvider()
            ..addScope('email')
            ..addScope('profile')
            ..setCustomParameters({
              'prompt': 'select_account',
            });
          final credentialResult = await _auth.signInWithPopup(provider);
          user = credentialResult.user;
        } else {
          // On mobile: use google_sign_in package
          // Sign out first to force account picker on next sign-in
          await _googleSignIn.signOut();
          final googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            throw const AuthException(message: 'Google Sign-in cancelled by user');
          }
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final credentialResult = await _auth.signInWithCredential(credential);
          user = credentialResult.user;
        }

        if (user == null) {
          throw const AuthException(message: 'Google login failed');
        }

        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Google User',
          photoUrl: user.photoURL,
        );

        // Sync to Firestore 'Splitwise/users' document as a merged field
        await _firestoreService.setDocument(
          'Splitwise',
          'users',
          {
            userModel.id: {
              ...userModel.toJson(),
              'updatedAt': FieldValue.serverTimestamp(),
            }
          },
          merge: true,
        );

        await _friendsRemoteDataSource.linkPendingContactsForUser(
          userId: userModel.id,
          email: userModel.email,
        );

        return _friendsRemoteDataSource.ensureFriendCodeForUser(userModel);
      } on FirebaseAuthException catch (e) {
        _logger.e('FirebaseAuth Google login failed', e);
        throw AuthException(message: e.message ?? 'Google Sign-in failed', code: e.code);
      } catch (e) {
        _logger.e('Google Sign-in exception', e);
        throw AuthException(message: e.toString());
      }
    } else {
      _logger.e('AuthRemoteDataSource: Google Sign-In failed because Firebase is not active.');
      throw const AuthException(
        message: 'Google Sign-In is unavailable because Firebase is not configured.',
      );
    }
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    
    if (_isFirebaseActive) {
      try {
        _logger.d('AuthRemoteDataSource: Sign Up via FirebaseAuth -> $cleanEmail');
        final credential = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        
        final user = credential.user;
        if (user == null) {
          throw const AuthException(message: 'User registration failed');
        }
        
        await user.updateDisplayName(name);
        
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? cleanEmail,
          name: name,
        );

        // Sync to Firestore 'Splitwise/users' document as a merged field
        await _firestoreService.setDocument(
          'Splitwise',
          'users',
          {
            userModel.id: {
              ...userModel.toJson(),
              'updatedAt': FieldValue.serverTimestamp(),
            }
          },
          merge: true,
        );

        await _friendsRemoteDataSource.linkPendingContactsForUser(
          userId: userModel.id,
          email: userModel.email,
        );

        return _friendsRemoteDataSource.ensureFriendCodeForUser(userModel);
      } on FirebaseAuthException catch (e) {
        _logger.e('FirebaseAuth sign up failed', e);
        throw AuthException(message: e.message ?? 'Sign up failed', code: e.code);
      }
    } else {
      // Mock Local Failover
      _logger.d('AuthRemoteDataSource: Sign Up via Mock Local Failover -> $cleanEmail');
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay
      
      final users = _getMockUsers();
      if (users.containsKey(cleanEmail)) {
        throw const AuthException(message: 'An account with this email already exists.');
      }
      
      final uid = const Uuid().v4();
      final code = FriendCodeGenerator.generate();
      final newUser = UserModel(
        id: uid,
        email: cleanEmail,
        name: name.trim(),
        friendCode: code,
        friendCodeVersion: 1,
      );
      
      // Save mock user credentials
      final userData = newUser.toJson();
      userData['password'] = password;
      users[cleanEmail] = userData;
      
      await _hiveService.put(_mockDbBox, _mockUsersKey, users);
      
      _currentMockUser = newUser;
      _mockAuthStateController.add(newUser);
      return newUser;
    }
  }
  @override
  Future<void> logout() async {
    if (_isFirebaseActive) {
      _logger.d('AuthRemoteDataSource: Logout via FirebaseAuth and GoogleSignIn');
      await _auth.signOut();
      try {
        await _googleSignIn.signOut();
      } catch (e, stackTrace) {
        _logger.e('Failed to sign out of GoogleSignIn', e, stackTrace);
      }
    } else {
      _logger.d('AuthRemoteDataSource: Logout via Mock Local Failover');
      _currentMockUser = null;
      _mockAuthStateController.add(null);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_isFirebaseActive) {
      final user = _auth.currentUser;
      if (user == null) return null;
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        photoUrl: user.photoURL,
      );
    } else {
      return _currentMockUser;
    }
  }

  @override
  Stream<UserModel?> watchAuthState() {
    if (_isFirebaseActive) {
      return _auth.authStateChanges().map((user) {
        if (user == null) return null;
        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          photoUrl: user.photoURL,
        );
      });
    } else {
      return _mockAuthStateController.stream;
    }
  }

  // Retrieve local map from Hive simulating a database
  Map<String, dynamic> _getMockUsers() {
    final raw = _hiveService.get<Map<dynamic, dynamic>>(_mockDbBox, _mockUsersKey);
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));
  }

  Future<UserModel> _ensureMockFriendCode(
    UserModel user,
    String emailKey,
    Map<String, dynamic> users,
    String password,
  ) async {
    if (user.friendCode != null && user.friendCode!.isNotEmpty) {
      return user;
    }

    final enriched = user.copyWith(
      friendCode: FriendCodeGenerator.generate(),
      friendCodeVersion: 1,
    );
    final stored = enriched.toJson();
    stored['password'] = password;
    users[emailKey] = stored;
    await _hiveService.put(_mockDbBox, _mockUsersKey, users);
    return enriched;
  }
}
