import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/dashboard_service.dart';
import '../../services/teacher_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final DashboardService _dashboardService = DashboardService();
  final TeacherService _teacherService = TeacherService();
  int _selectedIndex = 0;
  bool _isLoading = true;

  Map<String, int> _stats = {
    'courses': 0,
    'students': 0,
    'tps': 0,
    'quizzes': 0,
  };

  List<Map<String, dynamic>> _teacherCourses = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherDashboard();
  }

  Future<void> _loadTeacherDashboard() async {
    setState(() => _isLoading = true);
    try {
      // Récupérer l'ID de l'enseignant
      final teacherId = await _teacherService.getCurrentTeacherId();
      if (teacherId == null) throw Exception('ID enseignant non trouvé');

      // Charger les statistiques et cours de l'enseignant
      final stats = await _teacherService.getTeacherStats(teacherId);
      final courses = await _teacherService.getTeacherCourses(teacherId);

      if (mounted) {
        setState(() {
          _stats = stats;
          _teacherCourses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _teacherCourses = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final List<Map<String, dynamic>> _statsCards = [
    {
      'title': 'MES COURS',
      'statKey': 'courses',
      'icon': Icons.school,
      'gradient': const LinearGradient(
        colors: [Color(0xFF246BFD), Color(0xFF1E5AE9)],
      ),
    },
    {
      'title': 'ÉTUDIANTS',
      'statKey': 'students',
      'icon': Icons.people,
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
      ),
    },
    {
      'title': 'TPS',
      'statKey': 'tps',
      'icon': Icons.assignment,
      'gradient': const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
      ),
    },
    {
      'title': 'QUIZ',
      'statKey': 'quizzes',
      'icon': Icons.quiz,
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFB74D), Color(0xFFFFA000)],
      ),
    },
  ];

  void _onBottomNavTap(int index) {
    if (_selectedIndex != index) {
      switch (index) {
        case 0:
          setState(() => _selectedIndex = 0);
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/teacher/courses');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/teacher/assignments');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/teacher/students');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/teacher/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _statsCards.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: SizedBox(
                    width: 160,
                    child: _buildStatCard(_statsCards[index]),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mes cours récents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _teacherCourses.isEmpty
                              ? const Center(
                                  child: Text('Aucun cours trouvé'),
                                )
                              : ListView.builder(
                                  itemCount: _teacherCourses.length,
                                  itemBuilder: (context, index) =>
                                      _buildCourseCard(_teacherCourses[index]),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'BORD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'COURS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'DEVOIRS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'ÉLÈVES',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'PROFIL',
          ),
        ],
      ),
    );
  }

  // Widgets existants adaptés au contexte enseignant
  Widget _buildStatCard(Map<String, dynamic> card) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: card['gradient'],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(card['icon'], color: Colors.white, size: 24),
          const Spacer(),
          Text(
            _stats[card['statKey']]?.toString() ?? '0',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            card['title'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.school, color: Colors.white),
        ),
        title: Text(
          course['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${course['students_count']} étudiants',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/teacher/course-detail',
              arguments: course['id'],
            );
          },
        ),
      ),
    );
  }
}
