import 'package:app_school/config/supabase_config.dart';

class RanksService {
  final _supabase = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> getStudentRanks() async {
    try {
      final response =
          await _supabase.rpc('calculate_student_rankings').select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rangs: $e');
    }
  }
}
