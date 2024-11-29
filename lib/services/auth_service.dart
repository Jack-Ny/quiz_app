import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final _supabase = SupabaseConfig.client;

  // Récupérer l'utilisateur actuellement connecté
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Récupérer l'utilisateur actuel complet
  //User? getCurrentUser() {
  //return _supabase.auth.currentUser;
  //}

  // Vérifier si un utilisateur est connecté
  bool isLoggedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Inscription
  Future<AppUser> register({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw AuthException('Échec de l\'inscription');
      }

      final userData = {
        'id': authResponse.user!.id,
        'email': email,
        'name': name,
        'user_type': userType,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').insert(userData);

      switch (userType) {
        case 'student':
          await _supabase.from('students').insert({
            'user_id': authResponse.user!.id,
            'registration_number':
                'STD${DateTime.now().millisecondsSinceEpoch}',
            'class_level': 'Nouveau',
          });
          break;
        case 'teacher':
          await _supabase.from('teachers').insert({
            'user_id': authResponse.user!.id,
            'specialization': 'À définir',
          });
          break;
        case 'parent':
          await _supabase.from('parents').insert({
            'user_id': authResponse.user!.id,
          });
          break;
      }

      return AppUser.fromJson(userData);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'inscription: $e');
      }
      throw AuthException('Erreur lors de l\'inscription: $e');
    }
  }

  // Connexion
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Échec de la connexion');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('connected_user_id', response.user!.id);

      // Optionnel : Afficher un message de succès
      print("Connexion réussie pour l'utilisateur : ${response.user!.email}");

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return AppUser.fromJson(userData);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur de connexion: $e');
      }
      throw AuthException('Email ou mot de passe incorrect');
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Vérifier si l'utilisateur est connecté
  Future<AppUser?> getCurrentUser() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .single();

      return AppUser.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // Stream pour l'état de l'authentification
  Stream<AppUser?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;

      try {
        final userData =
            await _supabase.from('users').select().eq('id', user.id).single();
        return AppUser.fromJson(userData);
      } catch (e) {
        return null;
      }
    });
  }

  // Obtenir la route initiale selon le type d'utilisateur
  String getInitialRoute(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin':
        return '/admin-dashboard';
      case 'student':
        return '/student-dashboard';
      case 'teacher':
        return '/teacher-dashboard';
      case 'parent':
        return '/parent-dashboard';
      default:
        return '/login';
    }
  }

  // Validation de l'email
  bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validation du mot de passe
  bool validatePassword(String password) {
    return password.length >= 6;
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Mettre à jour le profil utilisateur
  Future<AppUser?> updateUserProfile({
    required String userId,
    String? name,
    String? profilePicture,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (profilePicture != null) updates['profile_picture'] = profilePicture;

      if (updates.isNotEmpty) {
        await _supabase.from('users').update(updates).eq('id', userId);
      }

      final userData =
          await _supabase.from('users').select().eq('id', userId).single();

      return AppUser.fromJson(userData);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du profil: $e');
      }
      rethrow;
    }
  }
}
