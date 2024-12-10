import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' as io;
import 'dart:io';
import '../config/supabase_config.dart';
import '../models/module.dart';

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

  // supprimer un cours
  Future<void> deleteCourse(String courseId) async {
    try {
      await _supabase.from('courses').delete().eq('id', courseId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du cours: $e');
    }
  }

  // creer un cours
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

    // Insérer le cours et obtenir la réponse
    final courseResponse = await _supabase
        .from('courses')
        .insert(courseData)
        .select()
        .single();

    if (courseResponse == null) {
      throw Exception('Échec de la création du cours');
    }

    final courseId = courseResponse['id'];

    // Créer la relation professeur-cours
    await _supabase.from('teacher_courses').insert({
      'teacher_id': createdBy,
      'course_id': courseId,
    });

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
            final fileName = 
                '${DateTime.now().millisecondsSinceEpoch}_${file.name.split('/').last}';
            final filePath = 'tps/$fileName';

            try {
              await uploadFile(filePath, file);
              final fileUrl = _supabase.storage
                  .from('tp_files')
                  .getPublicUrl(filePath);
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
    throw Exception('Erreur lors de la création du cours: $e');
  }
}

// Uploader un fichier
  Future<void> uploadFile(String filePath, PlatformFile file) async {
    try {
      Uint8List? bytes;

      // Pour le web, utilisez directement les bytes
      if (kIsWeb && file.bytes != null) {
        bytes = file.bytes;
      }

      // Pour les autres plateformes, lisez les bytes du fichier
      else if (!kIsWeb && file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      } else {
        throw Exception('Impossible de lire le fichier sur cette plateforme.');
      }

      await _supabase.storage.from('tp_files').uploadBinary(
            filePath,
            bytes!,
            fileOptions: const FileOptions(
              contentType: 'application/octet-stream',
              upsert: true,
            ),
          );
      print('Fichier uploadé avec succès !');
    } catch (e) {
      print('Détails de l\'erreur d\'upload : $e');
      rethrow;
    }
  }
}
