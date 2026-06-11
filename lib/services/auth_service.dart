import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  auth.User? get currentUser => _auth.currentUser;
  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // ─── Phone Auth ─────────────────────────────────────
  String? _verificationId;
  int? _resendToken;

  /// Start phone number verification. Firebase sends an SMS OTP.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(auth.PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (auth.PhoneAuthCredential credential) async {
        // Auto-verification on Android
        if (onAutoVerified != null) {
          onAutoVerified(credential);
        }
      },
      verificationFailed: (auth.FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed. Please try again.');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Sign in using the SMS code sent to the phone
  Future<auth.UserCredential> signInWithOTP(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('No verification in progress. Please request a code first.');
    }
    final credential = auth.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with an auto-resolved credential (Android only)
  Future<auth.UserCredential> signInWithPhoneCredential(auth.PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  /// Create or update user document for phone-auth users
  Future<void> createUserIfNotExists(String uid, String phone, String role) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      final db = DatabaseService();
      final existingByPhone = await db.getUserByPhone(phone);
      if (existingByPhone != null) {
        // Pre-created user exists! Migrate it to this UID.
        await db.migrateUserDocument(existingByPhone.id, uid);
        return;
      }

      final userModel = UserModel(
        id: uid,
        name: '',
        firstName: '',
        lastName: '',
        phone: phone,
        email: '',
        role: role,
        createdAt: DateTime.now(),
      );
      final map = userModel.toMap();
      map['authProvider'] = 'phone';
      await _firestore.collection('users').doc(uid).set(map);
      // Notify admins asynchronously
      db.sendUserSignupNotification(
        userName: phone,
        userRole: role,
        userId: uid,
      ).catchError((_) {});
    }
  }

  // ─── Email Auth (legacy / admin) ────────────────────
  Future<auth.UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
              
          if (querySnapshot.docs.isEmpty) {
            throw Exception('No account found with this email. Please register first.');
          }
          
          final userData = querySnapshot.docs.first.data();
          final provider = userData['authProvider'] ?? userData['signInProvider'];
          
          if (provider == 'google' || (provider == null && userData['profilePhoto'] != null)) {
            throw Exception(
              'This email is linked to a Google account. Please tap "Continue with Google" to sign in.'
            );
          } else if (provider == 'phone') {
            throw Exception(
              'This email is linked to a phone number account. Please sign in with your phone number.'
            );
          }
        } catch (dbError) {
          if (dbError is Exception && dbError.toString().contains('Please')) {
            rethrow;
          }
        }
        throw Exception('Incorrect email or password. Please try again.');
      } else if (e.code == 'account-exists-with-different-credential') {
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
              
          if (querySnapshot.docs.isNotEmpty) {
            final userData = querySnapshot.docs.first.data();
            final provider = userData['authProvider'] ?? userData['signInProvider'];
            if (provider == 'google' || (provider == null && userData['profilePhoto'] != null)) {
              throw Exception(
                'This email is already linked to a Google account. Please tap "Continue with Google" to sign in.'
              );
            }
          }
        } catch (innerE) {
          if (innerE is Exception && innerE.toString().contains('Please')) rethrow;
        }
        throw Exception('An account with this email already exists using a different sign-in method.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many failed attempts. Please try again later or reset your password.');
      } else if (e.code == 'network-request-failed') {
        throw Exception('No internet connection. Please check your network and try again.');
      }
      throw Exception(e.message ?? 'Sign-in failed. Please try again.');
    }
  }

  Future<auth.UserCredential> register(String email, String password, String role) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    
    final user = cred.user;
    if (user == null) throw Exception('Registration failed: User is null');
    
    final userModel = UserModel(
      id: user.uid,
      name: email.split('@')[0],
      firstName: '',
      lastName: '',
      phone: '',
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );

    final map = userModel.toMap();
    map['authProvider'] = 'email';
    await _firestore.collection('users').doc(user.uid).set(map);
    // Notify admins asynchronously
    DatabaseService().sendUserSignupNotification(
      userName: userModel.name,
      userRole: role,
      userId: user.uid,

    ).catchError((_) {});
    return cred;
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    _verificationId = null;
    _resendToken = null;
    await _auth.signOut();
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<String> registerUserByAgent({
    required String email,
    required String password,
    required String role,
    required String agentId,
    required Map<String, dynamic> profileData,
  }) async {
    // 1. Initialize secondary app so Admin doesn't get signed out
    FirebaseOptions options = Firebase.app().options;
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'AgentCreationApp',
      options: options,
    );

    try {
      // 2. Create user in Firebase Auth with the secondary app
      auth.UserCredential cred = await auth.FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = cred.user!.uid;
      final docRef = _firestore.collection('users').doc(uid);
      
      final userModel = UserModel.fromMap({
        ...profileData,
        'email': email,
        'role': role,
        'agentId': agentId,
        'isProfileComplete': true,
        'isVerified': true,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      }, uid);

      final map = userModel.toMap();
      map['authProvider'] = 'email';
      await docRef.set(map);
      // Notify admins asynchronously (skip for Agent creating themselves)
      DatabaseService().sendUserSignupNotification(
        userName: profileData['name'] ?? email,
        userRole: role,
        userId: uid,
      ).catchError((_) {});
      return uid;
    } finally {
      // 3. Clean up the secondary app
      await secondaryApp.delete();
    }
  }

  // --- Google Auth ---
  Future<auth.UserCredential?> signInWithGoogle({String defaultRole = 'Buyer'}) async {
    try {
      auth.UserCredential userCredential;
      String userName = '';
      String userEmail = '';
      String? userPhoto;
      String? userPhone;

      if (kIsWeb) {
        // Web flow using Firebase Auth Popup (avoids client ID configuration issues)
        final auth.GoogleAuthProvider googleProvider = auth.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        userCredential = await _auth.signInWithPopup(googleProvider);
        
        final user = userCredential.user;
        if (user == null) throw Exception('Google Sign-In failed: User is null');

        userName = user.displayName ?? '';
        userEmail = user.email ?? '';
        userPhoto = user.photoURL;
        userPhone = user.phoneNumber;
      } else {
        // Trigger the authentication flow for mobile
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // The user canceled the sign-in

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final auth.OAuthCredential credential = auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase Auth with the Google credential
        userCredential = await _auth.signInWithCredential(credential);
        
        final user = userCredential.user;
        if (user == null) throw Exception('Google Sign-In failed: User is null');

        userName = user.displayName ?? googleUser.displayName ?? '';
        userEmail = user.email ?? googleUser.email;
        userPhoto = user.photoURL ?? googleUser.photoUrl;
        userPhone = user.phoneNumber;
      }
      
      // Ensure user document exists in Firestore
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
          final userModel = UserModel(
            id: uid,
            name: userName,
            firstName: '',
            lastName: '',
            phone: userPhone ?? '',
            email: userEmail,
            role: defaultRole,
            profilePhoto: userPhoto,
            createdAt: DateTime.now(),
          );
          final map = userModel.toMap();
          map['authProvider'] = 'google';
          await _firestore.collection('users').doc(uid).set(map);
          // Notify admins asynchronously
          DatabaseService().sendUserSignupNotification(
            userName: userModel.name.isNotEmpty ? userModel.name : userEmail,
            userRole: defaultRole,
            userId: uid,
          ).catchError((_) {});
        }
      }
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
}
