import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppAuthProvider extends ChangeNotifier {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  Map<String, dynamic>? _userData;
  String? _token;
  bool _isAdmin = false;
  String? _errorMessage;
  bool _isLoading = false;

  User? get user => _user;

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
      _user = user;

      if (user != null) {
        try {
          _token = await user.getIdToken();
          final idTokenResult = await _auth.currentUser?.getIdTokenResult();
          _isAdmin = idTokenResult?.claims?['role'] == 'admin' ?? false;
        } catch (e) {
          _errorMessage = e.toString();
        }
      } else {
        _userData = null;
        _token = null;
        _isAdmin = false;
      }

      notifyListeners();
    });
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      final docSnapShot =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (docSnapShot.exists) {
        _userData = docSnapShot.data();
      }
    }
  }

  // Email/Password Registration
  Future<UserCredential> register({
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
        await _createUserDocument(credential.user!, role);
      }
      return credential;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _createUserDocument(User user, String role) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'username': user.displayName ?? '',
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
      });
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
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
        await _createUserDocument(userCredential.user!, 'user');
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

  // Password reset
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Check if welcome screen should be shown
  bool shouldShowWelcomeScreen() {
    return _user == null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
