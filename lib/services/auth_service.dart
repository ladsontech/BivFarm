import 'dart:async';
import '../models/user_model.dart';

class User {
  final String uid = 'demo_uid';
}

class UserCredential {
  final User? user = User();
}

class AuthService {
  User? get currentUser => null;
  Stream<User?> get authStateChanges => Stream.value(null);

  Future<UserModel?> getCurrentUserModel() async => null;

  Future<UserCredential> signIn(String email, String password) async {
    return UserCredential();
  }

  Future<UserCredential> register(String email, String password, String role) async {
    return UserCredential();
  }

  Future<void> resetPassword(String email) async {}
  Future<void> signOut() async {}
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {}

  Future<String> registerUserByAgent({
    required String email,
    required String password,
    required String role,
    required String agentId,
    required Map<String, dynamic> profileData,
  }) async {
    return 'demo_uid';
  }
}
