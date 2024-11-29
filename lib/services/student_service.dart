import '../config/supabase_config.dart';

class StudentService {
  final _supabase = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> getEnrolledStudents(
      String courseId) async {
    final response = await _supabase.from('course_enrollments').select('''
        *,
        student:students!inner (
          *,
          user:users!students_user_id_fkey (*)
        )
      ''').eq('course_id', courseId);
    return List<Map<String, dynamic>>.from(response);
  }

// obtenir les etudiants associer
  Future<List<Map<String, dynamic>>> getAvailableStudents(
      String courseId) async {
    // D'abord, récupérer les IDs des étudiants déjà inscrits
    final enrolledStudentsQuery = await _supabase
        .from('course_enrollments')
        .select('student_id')
        .eq('course_id', courseId);

    // Extraire les IDs dans une liste
    final enrolledStudentIds = List<String>.from(
        enrolledStudentsQuery.map((row) => row['student_id']));

    // Ensuite, récupérer tous les étudiants qui ne sont pas dans cette liste
    final response = await _supabase.from('students').select('''
        *,
        user:users!students_user_id_fkey (*)
      ''').not('id', 'in', enrolledStudentIds);

    return List<Map<String, dynamic>>.from(response);
  }

// inscrire un étudiant à un cours
  Future<void> enrollStudent(String courseId, String studentId) async {
    await _supabase.from('course_enrollments').insert({
      'course_id': courseId,
      'student_id': studentId,
    });
  }

// retirer un étudiant d'un cours
  Future<void> unenrollStudent(String courseId, String studentId) async {
    await _supabase
        .from('course_enrollments')
        .delete()
        .match({'course_id': courseId, 'student_id': studentId});
  }
}
