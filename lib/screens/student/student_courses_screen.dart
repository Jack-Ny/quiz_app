import 'package:app_school/screens/student/student_course_detail_screen.dart';
import 'package:app_school/services/student_stats_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final StudentStatsService _studentService = StudentStatsService();
  final int _selectedIndex = 1; // Pour la Bottom Navigation Bar
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      // Récupérer les cours inscrits pour l'étudiant
      final courses = await _studentService.getEnrolledCourses();

      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (_selectedIndex != index) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/student-dashboard');
          break;
        case 1:
          // Déjà sur la page des cours
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/student-dashboard'),
        ),
        title: const Text(
          'Mes Cours',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return _buildCourseCard(course);
              },
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    // Données disponibles
    final teacherName = course['users']?['name'] ?? 'Inconnu';
    final enrollmentsCount = course['enrollments'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image ou icône du cours
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              color: Colors.blue.withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                Icons.book,
                size: 40,
                color: Colors.blue.shade300,
              ),
            ),
          ),

          // Contenu du cours
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Catégorie du cours
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course['category'] ?? 'Non catégorisé',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Nom du cours
                Text(
                  course['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),

                // Infos supplémentaires
                Row(
                  children: [
                    // Nom de l'enseignant
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 4),
                        Text(teacherName),
                      ],
                    ),
                    const Spacer(),

                    // Nombre d'élèves inscrits
                    /* Row(
                      children: [
                        const Icon(Icons.people, size: 16),
                        const SizedBox(width: 4),
                        Text('$enrollmentsCount élèves'),
                      ],
                    ), */
                  ],
                ),

                // Bouton pour accéder aux détails du cours
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if (course['id'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentCourseDetailScreen(
                            courseTitle: course['name'] ?? 'Sans nom',
                            courseId: course['id'].toString(),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Voir les détails'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: Colors.grey,
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
