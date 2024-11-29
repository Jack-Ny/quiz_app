import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, int>> getDashboardStats() async {
    try {
      // obtenir les compteurs pour chaque table
      final Map<String, dynamic> counts = {};

      // Compteur d'utilisateurs
      final usersData = await _supabase.from('users').select('id, user_type');
      counts['users'] = usersData.length;

      // Compteur de cours
      final coursesData =
          await _supabase.from('courses').select('id').eq('is_active', true);
      counts['courses'] = coursesData.length;

      // Compteur de TPs
      final tpsData =
          await _supabase.from('tps').select('id').eq('is_active', true);
      counts['tps'] = tpsData.length;

      // Compteur de Quiz
      final quizzesData =
          await _supabase.from('quizzes').select('id').eq('is_active', true);
      counts['quizzes'] = quizzesData.length;

      print('Statistiques obtenues: $counts');

      return {
        'users': counts['users'] ?? 0,
        'courses': counts['courses'] ?? 0,
        'tps': counts['tps'] ?? 0,
        'quizzes': counts['quizzes'] ?? 0,
      };
    } catch (e) {
      print('Erreur statistiques: $e');
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentCourses() async {
    try {
      final response = await _supabase.from('courses').select('''
        *,
        enrollments:course_enrollments!course_id (
          count
        ),
        teacher_courses (
          teacher:teachers (
            user:users (*)
          )
        )
      ''');
      print('Données reçues: $response'); // Debug

      if (response == null) {
        print('Réponse null de Supabase');
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur dans getRecentCourses: $e');
      return [];
    }
  }
}
