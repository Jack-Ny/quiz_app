import 'package:app_school/config/supabase_config.dart';
import 'package:app_school/screens/student/quiz/student_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../services/student_stats_service.dart';
import 'student_tp_screen.dart';

class StudentCourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const StudentCourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState extends State<StudentCourseDetailScreen> {
  final _supabase = SupabaseConfig.client;
  bool _isLoading = true;
  final _studentStatsService = StudentStatsService();
  List<Map<String, dynamic>> _modules = [];
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      final studentId = await _studentStatsService.getCurrentStudentId();
      if (studentId == null) {
        throw Exception('Impossible de récupérer l\'ID de l\'étudiant');
      }

      // Charger les modules
      final modulesData = await _supabase
          .from('modules')
          .select('''
          *,
          quizzes:quizzes(
            id,
            title,
            time_limit,
            time_unit,
            passing_score,
            quiz_attempts!inner(
              id, 
              is_completed,
              score,
              student_id
            )
          ),
          tps:tps(
            id,
            title,
            description,
            due_date,
            max_points,
            file_urls,
            tp_submissions!inner(
              id,
              submitted_files,
              grade,
              submission_date,
              student_id
            )
          )
        ''')
          .eq('course_id', widget.courseId)
          .eq('is_active', true)
          .eq('quizzes.quiz_attempts.student_id', studentId)
          .eq('tps.tp_submissions.student_id', studentId)
          .order('order_index');

      // Charger les tentatives de quiz et soumissions de TP
      final quizAttempts = await _supabase
          .from('quiz_attempts')
          .select()
          .eq('student_id', studentId);

      final tpSubmissions = await _supabase
          .from('tp_submissions')
          .select()
          .eq('student_id', studentId);

      setState(() {
        _modules = List<Map<String, dynamic>>.from(modulesData);
        _calculateProgress(quizAttempts, tpSubmissions);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _calculateProgress(
      List<dynamic> quizAttempts, List<dynamic> tpSubmissions) {
    int totalItems = 0;
    int completedItems = 0;

    for (var module in _modules) {
      final quizzes = List<Map<String, dynamic>>.from(module['quizzes'] ?? []);
      final tps = List<Map<String, dynamic>>.from(module['tps'] ?? []);

      totalItems += quizzes.length + tps.length;

      for (var quiz in quizzes) {
        if (quizAttempts.any((attempt) => attempt['quiz_id'] == quiz['id'])) {
          completedItems++;
        }
      }

      for (var tp in tps) {
        if (tpSubmissions
            .any((submission) => submission['tp_id'] == tp['id'])) {
          completedItems++;
        }
      }
    }

    _progress = totalItems > 0 ? completedItems / totalItems : 0.0;
  }

  void _navigateToContent(
      String contentId, String type, bool isCompleted, String moduleTitle) {
    if (!isCompleted) {
      if (type == 'quiz') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentQuizScreen(
              quizId: contentId,
              moduleId: moduleTitle,
              moduleTitle: moduleTitle,
              courseTitle: widget.courseTitle,
            ),
          ),
        );
      } else if (type == 'tp') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentTPScreen(
              moduleTitle: moduleTitle,
              courseTitle: widget.courseTitle,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildModulesList(),
              if (_progress < 1.0) _buildContinueButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
            image: DecorationImage(
              image: AssetImage('assets/images/code_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.courseTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 4),
              Text(
                '${(_progress * 100).toInt()}% complété',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModulesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _modules.map((module) {
          final quizzes =
              List<Map<String, dynamic>>.from(module['quizzes'] ?? []);
          final tps = List<Map<String, dynamic>>.from(module['tps'] ?? []);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                module['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              ...quizzes.map((quiz) {
                final attempts = List<Map<String, dynamic>>.from(
                    quiz['quiz_attempts'] ?? []);
                final isCompleted =
                    attempts.any((a) => a['is_completed'] == true);

                return _buildContentItem(
                  quiz['id'],
                  quiz['title'],
                  'quiz',
                  isCompleted,
                  module['name'],
                  quiz,
                );
              }),
              ...tps.map((tp) {
                final submissions =
                    List<Map<String, dynamic>>.from(tp['tp_submissions'] ?? []);
                final isSubmitted = submissions.isNotEmpty;

                return _buildContentItem(
                  tp['id'],
                  tp['title'],
                  'tp',
                  isSubmitted,
                  module['name'],
                  tp,
                );
              }),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentItem(
    String id,
    String title,
    String type,
    bool isCompleted,
    String moduleTitle,
    Map<String, dynamic> itemData,
  ) {
    final DateTime? dueDate =
        type == 'tp' ? DateTime.tryParse(itemData['due_date'] ?? '') : null;

    return InkWell(
      onTap: () => _navigateToContent(id, type, isCompleted, moduleTitle),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'quiz' ? Icons.quiz : Icons.assignment,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isCompleted ? Colors.green : Colors.grey[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green)
              ],
            ),
            const SizedBox(height: 8),
            if (type == 'quiz')
              Text(
                'Temps limite: ${itemData['time_limit']} ${itemData['time_unit']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (type == 'tp' && dueDate != null)
              Text(
                'À rendre avant le ${_formatDate(dueDate)}',
                style: TextStyle(
                  color: _isOverdue(dueDate) ? Colors.red : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            if (isCompleted)
              Text(
                type == 'quiz'
                    ? 'Score: ${itemData['quiz_attempts']?[0]?['score']}%'
                    : 'Note: ${itemData['tp_submissions']?[0]?['grade']}/100',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          // Trouver le premier item non complété
          for (var module in _modules) {
            final quizzes =
                List<Map<String, dynamic>>.from(module['quizzes'] ?? []);
            final tps = List<Map<String, dynamic>>.from(module['tps'] ?? []);

            for (var quiz in quizzes) {
              if (!quiz['completed']) {
                _navigateToContent(quiz['id'], 'quiz', false, module['name']);
                return;
              }
            }

            for (var tp in tps) {
              if (!tp['completed']) {
                _navigateToContent(tp['id'], 'tp', false, module['name']);
                return;
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          _progress == 0 ? 'Commencer' : 'Continuer',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/student-dashboard');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/student/xcode');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/student/ranks');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/student/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'BORD'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'MES COURS'),
        BottomNavigationBarItem(icon: Icon(Icons.code), label: 'XCODE'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'RANGS'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILS'),
      ],
    );
  }
}
