// lib/screens/student/student_dashboard.dart
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/student_stats_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final StudentStatsService _statsService = StudentStatsService();
  late Future<StudentStats> _statsFuture;
  int _selectedIndex = 0;
  String _selectedFilter = 'Tout';

  @override
  void initState() {
    super.initState();
    _statsFuture = _statsService.getStudentStats();
  }

  void _onBottomNavTap(int index) {
    if (_selectedIndex != index) {
      switch (index) {
        case 0: // BORD
          setState(() => _selectedIndex = 0);
          break;
        case 1: // MES COURS
          Navigator.pushReplacementNamed(context, '/student/courses');
          break;
        case 2: // XCODE
          Navigator.pushReplacementNamed(context, '/student/xcode');
          break;
        case 3: // RANGS
          Navigator.pushReplacementNamed(context, '/student/ranks');
          break;
        case 4: // PROFILS
          Navigator.pushReplacementNamed(context, '/student/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FutureBuilder<StudentStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final stats = snapshot.data!;
            final statsCards = [
              {
                'title': 'COURS SUIVI',
                'count': stats.coursesInProgress.toString(),
                'icon': Icons.school,
                'color': AppColors.courseCard,
                'gradient': const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF246BFD), Color(0xFF1E5AE9)],
                ),
              },
              {
                'title': 'COURS TERMINE',
                'count': stats.completedCourses.toString(),
                'icon': Icons.task_alt,
                'color': AppColors.primaryBlue,
                'gradient': const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
                ),
              },
            ];

            return Column(
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
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                // Statistiques
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: statsCards.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: SizedBox(
                        width: 160,
                        child: _buildStatCard(statsCards[index]),
                      ),
                    ),
                  ),
                ),

                /* Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cours inscrits',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/student/courses');
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    'VOIR TOUS',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.blue),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('Tout'),
                              const SizedBox(width: 10),
                              _buildFilterChip('Informatique'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: stats.courses.length,
                            itemBuilder: (context, index) {
                              final course = stats.courses[index]['courses'];
                              return _buildCourseCard({
                                'title': course['name'],
                                'category': 'Informatique',
                                'instructor': 'Instructeur',
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ), */
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> card) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: card['gradient'],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: card['color'].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              card['icon'],
              color: Colors.white,
              size: 24,
            ),
          ),
          const Spacer(),
          Text(
            card['count'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card['title'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? label : 'Tout';
        });
      },
      backgroundColor: isSelected ? AppColors.accent : Colors.grey[100],
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
      elevation: isSelected ? 2 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
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
                    course['category'],
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      course['instructor'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.bookmark_outline),
                      color: AppColors.primaryBlue,
                      onPressed: () {},
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
}
