import 'package:app_school/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course.dart';

class StudentStats {
  final int coursesInProgress;
  final int completedCourses;
  final List<dynamic> courses;

  StudentStats({
    required this.coursesInProgress,
    required this.completedCourses,
    required this.courses,
  });
}

class StudentStatsService {
  final supabase = SupabaseConfig.client;

  Future<StudentStats> getStudentStats() async {
    try {
      // Récupérer l'ID utilisateur connecté
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('connected_user_id');

      // Récupérer l'ID étudiant correspondant
      final studentData = await supabase
          .from('students')
          .select()
          .eq('user_id', userId)
          .single();

      final studentId = studentData['id'];

      // Cours en cours (non complétés)
      final coursesInProgress = await supabase
          .from('course_enrollments')
          .select('*, courses(*)')
          .eq('student_id', studentId)
          .eq('completed', false);

      // Cours terminés
      final completedCourses = await supabase
          .from('course_enrollments')
          .select('*, courses(*)')
          .eq('student_id', studentId)
          .eq('completed', true);

      return StudentStats(
        coursesInProgress: coursesInProgress.length,
        completedCourses: completedCourses.length,
        courses: [...coursesInProgress, ...completedCourses],
      );
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getEnrolledCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('connected_user_id');

      // Récupérer l'ID étudiant
      final studentData = await supabase
          .from('students')
          .select()
          .eq('user_id', userId)
          .single();

      final studentId = studentData['id'];

      // Récupérer les cours avec leurs détails
      final enrolledCourses =
          await supabase.from('course_enrollments').select('''
          *,
          courses (
            id,
            name,
            description,
            created_by,
            users!courses_created_by_fkey (
              id,
              name
            )
          )
        ''').eq('student_id', studentId);

      return List<Map<String, dynamic>>.from(
          enrolledCourses.map((e) => e['courses']));
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cours: $e');
    }
  }

  Future<bool> updateCourseProgress(String courseId, bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('connected_user_id');

      final studentData = await supabase
          .from('students')
          .select()
          .eq('user_id', userId)
          .single();

      await supabase
          .from('course_enrollments')
          .update({
            'completed': completed,
            'completion_date':
                completed ? DateTime.now().toIso8601String() : null
          })
          .eq('student_id', studentData['id'])
          .eq('course_id', courseId);

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du cours: $e');
    }
  }

  Future<int> _getEnrolledStudentsCount(String courseId) async {
    final response = await supabase
        .from('course_enrollments')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('course_id', courseId);

    return response.count ?? 0;
  }

  Future<String?> getCurrentStudentId() async {
    try {
      // Récupérer l'ID utilisateur depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('connected_user_id');

      if (userId == null) return null;

      // Récupérer l'ID étudiant depuis Supabase
      final studentData = await supabase
          .from('students')
          .select()
          .eq('user_id', userId)
          .single();

      return studentData['id'].toString();
    } catch (e) {
      print('Erreur lors de la récupération de l\'ID étudiant: $e');
      return null;
    }
  }
}
