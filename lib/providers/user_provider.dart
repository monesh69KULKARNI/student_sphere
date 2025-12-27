import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _userService.getCurrentUser();
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(User user) async {
    await _userService.setCurrentUser(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _userService.clearCurrentUser();
    _currentUser = null;
    notifyListeners();
  }
}

