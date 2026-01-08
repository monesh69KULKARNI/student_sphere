import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  UserModel? get currentUser => _currentUser;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 🔥 LOAD USER FROM DATABASE (Supabase or Firestore)
      final user = await _authService.fetchUserProfile(firebaseUser.uid);

      _currentUser = user;
      _isLoading = false;
      notifyListeners();

      debugPrint('Logged in as: ${user?.email}');
    });
  }
}
