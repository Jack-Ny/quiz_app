import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _isLoading = true;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  void setUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _user = await _authService.getCurrentUser();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation de l\'auth: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Écouter les changements d'état d'authentification
    _authService.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> login({required String email, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.login(
        email: email,
        password: password,
      );

      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la déconnexion: $e');
      }
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? profilePicture,
  }) async {
    try {
      _user = await _authService.updateUserProfile(
        userId: userId,
        name: name,
        profilePicture: profilePicture,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du profil: $e');
      }
      rethrow;
    }
  }
}
