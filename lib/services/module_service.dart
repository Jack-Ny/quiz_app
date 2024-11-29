import 'package:app_school/config/supabase_config.dart';
import '../models/module.dart';
import '../models/quiz.dart';
import '../models/tp.dart';

class ModuleService {
  final _supabase = SupabaseConfig.client;

  Future<Module> createModule({
    required String courseId,
    required String name,
    String? description,
    int orderIndex = 0,
    List<Quiz> quizzes = const [],
    List<TP> tps = const [],
  }) async {
    try {
      // Créer le module
      final moduleResponse = await _supabase
          .from('modules')
          .insert({
            'course_id': courseId,
            'name': name,
            'description': description,
            'order_index': orderIndex,
            'is_active': true,
          })
          .select()
          .single();

      final moduleId = moduleResponse['id'];

      // Créer les quiz associés
      for (var quiz in quizzes) {
        final quizResponse = await _supabase
            .from('quizzes')
            .insert({
              'module_id': moduleId,
              'title': quiz.title,
              'time_limit': quiz.timeLimit,
              'time_unit': quiz.timeUnit,
              'passing_score': quiz.passingScore,
            })
            .select()
            .single();

        final quizId = quizResponse['id'];

        // Créer les questions pour chaque quiz
        /* for (var question in quiz.questions) {
          await _supabase.from('questions').insert({
            'quiz_id': quizId,
            'question_text': question.questionText,
            'question_type': question.questionType,
            'answer': question.answer,
            'points': question.points,
            'choices': question.choices,
          });
        } */
      }

      // Créer les TPs associés
      for (var tp in tps) {
        await _supabase.from('tps').insert({
          'module_id': moduleId,
          'title': tp.title,
          'description': tp.description,
          'due_date': tp.dueDate?.toIso8601String(),
          'max_points': tp.maxPoints,
        });
      }

      return Module.fromJson(moduleResponse);
    } catch (e) {
      throw Exception('Erreur lors de la création du module : $e');
    }
  }

  Future<List<Module>> getModulesByCourse(String courseId) async {
    try {
      final response = await _supabase.from('modules').select('''
            *,
            quizzes(*),
            tps(*)
          ''').eq('course_id', courseId).order('order_index');

      return List<Module>.from(
          response.map((module) => Module.fromJson(module)));
    } catch (e) {
      throw Exception('Erreur lors de la récupération des modules : $e');
    }
  }

  Future<void> deleteModule(String moduleId) async {
    try {
      await _supabase.from('modules').delete().eq('id', moduleId);
    } catch (e) {
      throw Exception('Erreur lors de la suppresion des modules : $e');
    }
  }
}
