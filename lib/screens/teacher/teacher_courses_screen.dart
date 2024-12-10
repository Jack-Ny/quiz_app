
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/colors.dart';
import '../../services/course_service.dart';
import '../../services/teacher_service.dart';
import '../courses/course_students_screen.dart';
import '../courses/edit_course_screen.dart';

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  final TeacherService _courseService = TeacherService();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _filteredCourses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterData);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      
      final teacherId = await _courseService.getCurrentTeacherId();
      if (teacherId == null) throw Exception('ID enseignant non trouvé');

      // Modify CourseService to add this method
      final courses = await _courseService.getTeacherCourses(teacherId);
      setState(() {
        _courses = courses;
        _filteredCourses = courses;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourses = _courses.where((course) {
        return course['name'].toString().toLowerCase().contains(query) ||
            course['category'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/teacher-dashboard');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/teacher/assignments');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/teacher/ranks');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/teacher/profile');
    }
  }

  void _navigateToEditCourse(String courseId) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => TeacherEditCourseScreen(courseId: courseId),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pushReplacementNamed(context, '/teacher-dashboard'),
        ),
        title: const Text(
          'Mes Cours',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(child: _buildCoursesView()),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/teacher/courses/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Reuse the same widgets from CoursesScreen but simplified for teacher context
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
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
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.search, color: Colors.grey),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Recherche .......',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/admin/courses/add');
            },
            icon: const Icon(Icons.add, color: AppColors.primaryBlue),
            label: const Text(
              'Ajouter un cours',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
          Expanded(
            child: _filteredCourses.isEmpty
                ? const Center(child: Text('Aucun cours trouvé'))
                : ListView.builder(
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) =>
                        _buildCourseCard(_filteredCourses[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final teacherData = course['teacher_courses']?.isNotEmpty == true
        ? course['teacher_courses'][0]['teacher']['user']
        : null;
    final enrollmentsCount =
        (course['enrollments'] as List?)?.isNotEmpty == true
            ? course['enrollments'][0]['count']
            : 0;

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
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              color: Colors.blue.withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                Icons.code,
                size: 40,
                color: Colors.blue.shade300,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  course['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (course['id'] != null) {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => TeacherCourseStudentsScreen(
                          //       courseName: course['name'] ?? 'Sans nom',
                          //       courseId: course['id'].toString(),
                          //     ),
                          //   ),
                          // );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$enrollmentsCount Élèves',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _navigateToEditCourse(course['id']),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                      ),
                      child: const Text('Modifier'),
                    ),
                    TextButton(
                      onPressed: () => _confirmDeleteCourse(course['id']),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Supprimer'),
                    ),
                  ],
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
      currentIndex: 1,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'BORD'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'MES COURS'),
        BottomNavigationBarItem(icon: Icon(Icons.code), label: 'DEVOIRS'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'RANGS'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILS'),
      ],
    );
  }

  Future<void> _confirmDeleteCourse(String courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce cours ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _courseService.deleteCourse(courseId);
        await _loadData(); // Recharger les données
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}