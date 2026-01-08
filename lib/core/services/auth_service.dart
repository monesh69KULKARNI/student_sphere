import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'supabase_database_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = FirebaseService.auth;

  // Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? studentId,
    String? department,
    String? year,
    String? phone,
  }) async {
    try {
      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user');
      }

      // Create user model
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        role: role,
        studentId: studentId,
        department: department,
        year: year,
        phone: phone,
        createdAt: DateTime.now(),
      );

      // Save to Supabase (convert to snake_case)
      await SupabaseDatabaseService.createUser(_convertToSupabaseFormat(userModel.toMap()));

      return userModel;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Starting sign in for email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Sign in failed: No Firebase user returned');
      }

      debugPrint('✅ Firebase auth successful for UID: ${firebaseUser.uid}');

      // Get user data from Supabase
      debugPrint('🔍 Fetching user data from Supabase for UID: ${firebaseUser.uid}');
      final userData = await SupabaseDatabaseService.getUser(firebaseUser.uid);

      if (userData == null) {
        debugPrint('❌ User data not found in Supabase for UID: ${firebaseUser.uid}');
        debugPrint('💡 Creating missing user record in Supabase...');
        
        // Create a basic user record in Supabase
        final basicUserModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          name: firebaseUser.displayName ?? 'User',
          role: UserRole.student, // Default role
          createdAt: DateTime.now(),
        );
        
        await SupabaseDatabaseService.createUser(_convertToSupabaseFormat(basicUserModel.toMap()));
        debugPrint('✅ Created basic user record in Supabase');
        
        // Try fetching again
        final newUserData = await SupabaseDatabaseService.getUser(firebaseUser.uid);
        if (newUserData == null) {
          throw Exception('Failed to create user profile. Please try again or contact support.');
        }
        
        final userModel = UserModel.fromMap(_convertFromSupabaseFormat(newUserData));
        debugPrint('✅ User profile created and loaded: ${userModel.name}');
        
        return userModel;
      }

      debugPrint('✅ User data found in Supabase: ${userData['name']}');
      final userModel = UserModel.fromMap(_convertFromSupabaseFormat(userData));

      // Update last login
      try {
        await SupabaseDatabaseService.updateUser(
          firebaseUser.uid,
          {'last_login': DateTime.now().toIso8601String()},
        );
        debugPrint('✅ Last login updated in Supabase');
      } catch (e) {
        debugPrint('⚠️ Failed to update last login: $e');
        // Don't fail the login for this
      }

      return userModel;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // Get current user from Supabase
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;

    try {
      final userData = await SupabaseDatabaseService.getUser(firebaseUser.uid);
      if (userData == null) return null;

      return UserModel.fromMap(_convertFromSupabaseFormat(userData));
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? department,
    String? year,
    String? profileImageUrl,
  }) async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (department != null) updates['department'] = department;
    if (year != null) updates['year'] = year;
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

    if (updates.isNotEmpty) {
      await SupabaseDatabaseService.updateUser(firebaseUser.uid, updates);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Convert camelCase to snake_case for Supabase
  Map<String, dynamic> _convertToSupabaseFormat(Map<String, dynamic> data) {
    return {
      'uid': data['uid'],
      'email': data['email'],
      'name': data['name'],
      'role': data['role'],
      'student_id': data['studentId'],
      'department': data['department'],
      'year': data['year'],
      'phone': data['phone'],
      'profile_image_url': data['profileImageUrl'],
      'created_at': data['createdAt'],
      'last_login': data['lastLogin'],
      'additional_data': data['additionalData'],
    };
  }

  // Convert snake_case to camelCase from Supabase
  Map<String, dynamic> _convertFromSupabaseFormat(Map<String, dynamic> data) {
    return {
      'uid': data['uid'],
      'email': data['email'],
      'name': data['name'],
      'role': data['role'],
      'studentId': data['student_id'],
      'department': data['department'],
      'year': data['year'],
      'phone': data['phone'],
      'profileImageUrl': data['profile_image_url'],
      'createdAt': data['created_at'],
      'lastLogin': data['last_login'],
      'additionalData': data['additional_data'],
    };
  }
}

