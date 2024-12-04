import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';

class TeacherService {
  final _supabase = SupabaseConfig.client;

  // Récupérer l'ID de l'enseignant connecté
  Future<String?> getCurrentTeacherId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('connected_user_id');

      if (userId == null) return null;

      final teacherData = await _supabase
          .from('teachers')
          .select()
          .eq('user_id', userId)
          .single();

      return teacherData['id'];
    } catch (e) {
      print('Erreur lors de la récupération de l\'ID enseignant: $e');
      return null;
    }
  }

  // Récupérer les statistiques de l'enseignant
  Future<Map<String, int>> getTeacherStats(String teacherId) async {
    try {
      // Compteur de cours du professeur
      final coursesData = await _supabase
          .from('courses')
          .select('id')
          .eq('created_by', teacherId)
          .eq('is_active', true);
      final coursesCount = coursesData.length;

      // Compteur d'étudiants inscrits aux cours du professeur
      final studentsData = await _supabase
          .from('course_enrollments')
          .select('id, course!inner(created_by)')
          .eq('course.created_by', teacherId);
      final studentsCount = studentsData.length;

      // Compteur de TPs des cours du professeur
      final tpsData = await _supabase
          .from('tps')
          .select('id, module!inner(course!inner(created_by))')
          .eq('module.course.created_by', teacherId);
      final tpsCount = tpsData.length;

      // Compteur de quiz des cours du professeur
      final quizzesData = await _supabase
          .from('quizzes')
          .select('id, module!inner(course!inner(created_by))')
          .eq('module.course.created_by', teacherId);
      final quizzesCount = quizzesData.length;

      return {
        'courses': coursesCount,
        'students': studentsCount,
        'tps': tpsCount,
        'quizzes': quizzesCount,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {
        'courses': 0,
        'students': 0,
        'tps': 0,
        'quizzes': 0,
      };
    }
  }

  // Récupérer les cours de l'enseignant
  Future<List<Map<String, dynamic>>> getTeacherCourses(String teacherId) async {
    try {
      final courses = await _supabase
          .from('courses')
          .select('''
            *,
            modules (
              id,
              name,
              quizzes (id),
              tps (id)
            ),
            course_enrollments (
              student:students (
                id,
                user:users (
                  name
                )
              )
            )
          ''')
          .eq('created_by', teacherId)
          .order('created_at', ascending: false);

      return courses;
    } catch (e) {
      print('Erreur lors de la récupération des cours: $e');
      return [];
    }
  }

  // Récupérer les étudiants d'un cours
  Future<List<Map<String, dynamic>>> getCourseStudents(String courseId) async {
    try {
      final students = await _supabase.from('course_enrollments').select('''
            student:students (
              id,
              user:users (
                id,
                name,
                email
              )
            )
          ''').eq('course_id', courseId);

      return students;
    } catch (e) {
      print('Erreur lors de la récupération des étudiants: $e');
      return [];
    }
  }

  // Gérer les soumissions de TP
  Future<List<Map<String, dynamic>>> getTPSubmissions(String tpId) async {
    try {
      final submissions = await _supabase.from('tp_submissions').select('''
            *,
            student:students (
              user:users (
                name
              )
            )
          ''').eq('tp_id', tpId);

      return submissions;
    } catch (e) {
      print('Erreur lors de la récupération des soumissions: $e');
      return [];
    }
  }

  // Noter une soumission de TP
  Future<void> gradeTPSubmission(String submissionId, int grade) async {
    try {
      final teacherId = await getCurrentTeacherId();
      if (teacherId == null) throw Exception('ID enseignant non trouvé');

      await _supabase.from('tp_submissions').update({
        'grade': grade,
        'graded_by': teacherId,
        'graded_at': DateTime.now().toIso8601String(),
      }).eq('id', submissionId);
    } catch (e) {
      print('Erreur lors de la notation du TP: $e');
      throw e;
    }
  }
}
