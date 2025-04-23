import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learn_hub/models/user.dart';
class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  AppUser? _appUser;
  Map<String, dynamic>? _userData;
  String? _token;
  bool _isAdmin = false;
  String? _errorMessage;
  bool _isLoading = false;

  User? get user => _user;

  AppUser? get appUser => _appUser;

  Map<String, dynamic>? get userData => _userData;

  String? get token => _token;

  bool get isAdmin => _isAdmin;

  String? get errorMessage => _errorMessage;

  bool get isLoading => _isLoading;

  bool get isAuthed => _user != null;

  AppAuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _auth.authStateChanges().listen((User? user) async {
      _isLoading = true;
      notifyListeners();

      try {
        _user = user;

        if (user != null) {
          _token = await user.getIdToken();
          final idTokenResult = await user.getIdTokenResult();
          _isAdmin = idTokenResult.claims?['role'] == 'admin';

          await _fetchUserData();
        } else {
          _userData = null;
          _token = null;
          _isAdmin = false;
        }
      } catch (e) {
        _errorMessage = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        final docSnapShot = await _firestore.collection('users').doc(_user!.uid).get();
        if (docSnapShot.exists) {
          _userData = docSnapShot.data() ?? {};

          if (_user!.displayName != null) {
            _userData!['displayName'] = _user!.displayName;
          }

          _appUser = AppUser.fromJson(_userData!);

          // print("AppUser created: ${_appUser?.toJson()}");
        } else {
          print("User document doesn't exist for uid: ${_user!.uid}");
        }
      } catch (e) {
        print("Error fetching user data: $e");
        _errorMessage = e.toString();
      } finally {
        notifyListeners();
      }
    }
  }

  Future<UserCredential> register({
    required String username,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserDocument(username, credential.user!, role);
      }
      return credential;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _createUserDocument(String username, User user, String role) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'uid': user.uid,
        'email': user.email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': user.photoURL,
        'preferences': {'darkMode': false, 'notifications': true},
        'credits': 0,
        'isVIP': false,
        'VIPExpiration': null,
        'freeCreditsLastReset': null,
        'birthday': null,
        'gender': null,
        'phoneNumber': null,
      });
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> updates) async {
    if (_user == null || _userData == null || _appUser == null) {
      _errorMessage = "Cannot update user data: User is not logged in";
      notifyListeners();
      return;
    }

    try {
      // Update Firestore document
      if (updates.containsKey('photoURL')) {
        final localPhotoURL = updates['photoURL'];
        _auth.currentUser?.updatePhotoURL(localPhotoURL);
      }

      await _firestore.collection('users').doc(_user!.uid).update(updates);

      // Update local user data
      _userData!.addAll(updates);
      _appUser = AppUser.fromJson(_userData!);

      // Update Firebase Authentication displayName if changed
      if (updates.containsKey('displayName')) {
        await _user!.updateDisplayName(updates['displayName']);
      }

      // Notify listeners about the changes
      notifyListeners();
    } catch (e) {
      _errorMessage = "Error updating user data: $e";
      notifyListeners();
      throw Exception("Failed to update user data: $e");
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(_generateRandomUsername(), userCredential.user!, 'user');
      }

      return userCredential;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _user = null;
      _userData = null;
      _token = null;
      _isAdmin = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      if (_user != null) {
        return await _user!.getIdToken(forceRefresh);
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  bool shouldShowWelcomeScreen() {
    return _user == null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _generateRandomUsername() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

}

