import 'package:flutter/foundation.dart';
import '../services/auth_service.dart'; // ADD THIS LINE

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;

  User? get user => _user;

  AuthProvider() {
    // Listen for auth changes (THIS MAKES PERSISTENCE WORK)
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (kDebugMode) {
        print('Auth changed: ${user?.email ?? "null"}');
      }
      notifyListeners();
    });

    // Check immediately
    _user = _authService.currentUser;
    if (kDebugMode) {
      print('Startup user: ${_authService.currentUser?.email}');
    }
  }
}
