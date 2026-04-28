import 'dart:async';
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
    if (currentUser == null) return null;
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    if (!doc.exists) return null;
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
      await _firestore.collection('users').doc(uid).set(userModel.toMap());
      // Notify admins asynchronously
      DatabaseService().sendUserSignupNotification(
        userName: phone,
        userRole: role,
        userId: uid,
      ).catchError((_) {});
    }
  }

  // ─── Email Auth (legacy / admin) ────────────────────
  Future<auth.UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<auth.UserCredential> register(String email, String password, String role) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    
    final userModel = UserModel(
      id: cred.user!.uid,
      name: email.split('@')[0],
      firstName: '',
      lastName: '',
      phone: '',
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(cred.user!.uid).set(userModel.toMap());
    // Notify admins asynchronously
    DatabaseService().sendUserSignupNotification(
      userName: userModel.name,
      userRole: role,
      userId: cred.user!.uid,
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

      await docRef.set(userModel.toMap());
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
      // Trigger the authentication flow
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
      final auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Ensure user document exists in Firestore
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
          final userModel = UserModel(
            id: uid,
            name: userCredential.user!.displayName ?? googleUser.displayName ?? '',
            firstName: '',
            lastName: '',
            phone: userCredential.user!.phoneNumber ?? '',
            email: userCredential.user!.email ?? googleUser.email,
            role: defaultRole,
            profilePhoto: userCredential.user!.photoURL ?? googleUser.photoUrl,
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(uid).set(userModel.toMap());
            // Notify admins asynchronously
            DatabaseService().sendUserSignupNotification(
              userName: userModel.name.isNotEmpty ? userModel.name : googleUser.email,
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
