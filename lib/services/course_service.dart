import 'dart:io' as io;
import 'package:app_school/models/module.dart';
import 'package:app_school/services/auth_service.dart';
import 'module_service.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show File, FileOptions;

class CourseService {
  final _supabase = SupabaseConfig.client;
  final AuthService _authService = AuthService();
  late final ModuleService _moduleService;

  // Récupérer tous les cours
  Future<List<Map<String, dynamic>>> getAllCourses() async {
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
      print('Response from Supabase: $response'); // Debug
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cours: $e');
    }
  }

  // Récupérer tous les formateurs
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    try {
      final response = await _supabase.from('users').select('''
            id,
            name,
            teachers!inner (
              id,
              specialization
            )
          ''').eq('user_type', 'teacher');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération des formateurs: $e');
    }
  }

  Future<Map<String, dynamic>> createCourseWithModules({
    required String name,
    required String description,
    required String createdBy,
    required List<Module> modules,
  }) async {
    try {
      // Créer le cours
      final courseData = {
        'name': name,
        'description': description,
        'created_by': createdBy,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insérer le cours dans la BD
      final courseResponse =
          await _supabase.from('courses').insert(courseData).select().single();

      if (courseResponse == null) {
        throw Exception('Échec de la création du cours');
      }

      final courseId = courseResponse['id'];

      // Créer les modules associés
      for (var module in modules) {
        final moduleData = {
          'course_id': courseId,
          'name': module.name,
          'description': module.description,
          'order_index': module.orderIndex,
          'is_active': module.isActive
        };

        final moduleResponse = await _supabase
            .from('modules')
            .insert(moduleData)
            .select()
            .single();

        if (moduleResponse == null) {
          throw Exception('Échec de la création du module');
        }

        final moduleId = moduleResponse['id'];

        // Créer les quiz associés
        for (var quiz in module.quizzes) {
          final quizData = {
            'module_id': moduleId,
            'title': quiz.title,
            'time_limit': quiz.timeLimit,
            'time_unit': quiz.timeUnit,
            'passing_score': quiz.passingScore,
            'is_active': quiz.isActive,
          };

          final quizResponse = await _supabase
              .from('quizzes')
              .insert(quizData)
              .select()
              .single();

          if (quizResponse == null) {
            throw Exception('Échec de la création du quiz');
          }

          final quizId = quizResponse['id'];

          // Créer les questions associées
          for (var question in quiz.questions) {
            final questionData = {
              'quiz_id': quizId,
              'question_text': question.questionText,
              'question_type': question.questionType,
              'answer': question.answer,
              'points': question.points,
              'choices': question.choices,
            };
            await _supabase.from('questions').insert(questionData);
          }
        }

        // Créer les TPs
        for (var tp in module.tps) {
          List<String> uploadedUrls = [];
          // Upload des fichiers si présents
          if (tp.files != null && tp.files!.isNotEmpty) {
            for (var file in tp.files!) {
              final fileExt = file.path.split('.').last;
              final fileName =
                  '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
              final filePath = 'tps/$fileName';

              try {
                // Upload du fichier
                await uploadFile(filePath, file);

                // Récupération de l'URL publique
                final fileUrl =
                    _supabase.storage.from('tp_files').getPublicUrl(filePath);

                uploadedUrls.add(fileUrl);
              } catch (e) {
                print('Erreur upload fichier: $e');
                continue;
              }
            }
          }
          final tpData = {
            'module_id': moduleId,
            'title': tp.title,
            'description': tp.description,
            'due_date': tp.dueDate?.toIso8601String(),
            'max_points': tp.maxPoints,
            'is_active': tp.isActive,
            'file_urls': uploadedUrls.isEmpty ? tp.fileUrls : uploadedUrls,
          };

          await _supabase.from('tps').insert(tpData);
        }
      }

      return courseResponse;
    } catch (e) {
      throw Exception('Erreur lors de la création du cours : $e');
    }
  }

  // Supprimer un cours
  Future<void> deleteCourse(String courseId) async {
    try {
      await _supabase.from('courses').delete().eq('id', courseId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du cours: $e');
    }
  }

  // Mettre à jour un cours
  Future<Map<String, dynamic>> updateCourseWithModules({
    required String courseId,
    required String name,
    required String description,
    required String createdBy,
    required List<Module> modules,
  }) async {
    try {
      // Mise à jour du cours
      final courseData = {
        'name': name,
        'description': description,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final courseResponse = await _supabase
          .from('courses')
          .update(courseData)
          .eq('id', courseId)
          .select()
          .single();

      // Récupérer les modules existants
      final existingModules = await _supabase
          .from('modules')
          .select('id')
          .eq('course_id', courseId);

      final existingModuleIds = existingModules.map((m) => m['id']).toList();

      // Traiter chaque module
      for (var module in modules) {
        if (existingModuleIds.contains(module.id)) {
          // Mise à jour module existant
          final moduleData = {
            'name': module.name,
            'description': module.description,
            'order': module.orderIndex,
            'is_active': module.isActive,
          };

          await _supabase
              .from('modules')
              .update(moduleData)
              .eq('id', module.id);

          // Mise à jour des quiz
          for (var quiz in module.quizzes) {
            final quizData = {
              'title': quiz.title,
              'time_limit': quiz.timeLimit,
              'time_unit': quiz.timeUnit,
              'passing_score': quiz.passingScore,
              'is_active': quiz.isActive,
            };

            await _supabase.from('quizzes').update(quizData).eq('id', quiz.id);

            // Supprimer anciennes questions
            await _supabase.from('questions').delete().eq('quiz_id', quiz.id);

            // Créer nouvelles questions
            for (var question in quiz.questions) {
              final questionData = {
                'quiz_id': quiz.id,
                'question_text': question.questionText,
                'question_type': question.questionType,
                'answer': question.answer,
                'points': question.points,
                'choices': question.choices,
              };

              await _supabase.from('questions').insert(questionData);
            }
          }

          // Mise à jour des TPs
          for (var tp in module.tps) {
            List<String> uploadedUrls = [...tp.fileUrls];

            // Gérer nouveaux fichiers
            if (tp.files != null && tp.files!.isNotEmpty) {
              for (var file in tp.files!) {
                final fileExt = file.path.split('.').last;
                final fileName =
                    '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
                final filePath = 'tps/$fileName';

                try {
                  await uploadFile(filePath, file);

                  final fileUrl = await _supabase.storage
                      .from('tp_files')
                      .getPublicUrl(filePath);

                  uploadedUrls.add(fileUrl);
                } catch (e) {
                  print('Erreur upload fichier: $e');
                }
              }
            }

            final tpData = {
              'title': tp.title,
              'description': tp.description,
              'due_date': tp.dueDate?.toIso8601String(),
              'max_points': tp.maxPoints,
              'is_active': tp.isActive,
              'file_urls': uploadedUrls,
            };

            await _supabase.from('tps').update(tpData).eq('id', tp.id);
          }
        } else {
          final moduleData = {
            'course_id': courseId,
            'name': module.name,
            'description': module.description,
            'order': module.orderIndex,
            'is_active': module.isActive,
          };

          final moduleResponse = await _supabase
              .from('modules')
              .insert(moduleData)
              .select()
              .single();

          final moduleId = moduleResponse['id'];
        }
      }

      // Supprimer modules qui ne sont plus présents
      final newModuleIds =
          modules.where((m) => m.id != null).map((m) => m.id).toList();

      final modulesToDelete =
          existingModuleIds.where((id) => !newModuleIds.contains(id)).toList();

      if (modulesToDelete.isNotEmpty) {
        await _supabase.from('modules').delete().in_('id', modulesToDelete);
      }

      return courseResponse;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du cours: $e');
    }
  }

  // Assigner un formateur à un cours
  Future<void> assignTeacherToCourse(String courseId, String teacherId) async {
    try {
      await _supabase.from('teacher_courses').insert({
        'course_id': courseId,
        'teacher_id': teacherId,
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation du formateur: $e');
    }
  }

  // Uploader un fichier
  Future<void> uploadFile(String filePath, io.File ioFile) async {
    final bytes = await ioFile.readAsBytes();

    await _supabase.storage.from('tp_files').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/octet-stream',
          ),
        );
  }
}
