import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/ranks_service.dart';
import '../../services/student_stats_service.dart';

class StudentRanksScreen extends StatefulWidget {
  const StudentRanksScreen({super.key});

  @override
  State<StudentRanksScreen> createState() => _StudentRanksScreenState();
}

class _StudentRanksScreenState extends State<StudentRanksScreen> {
  final int _selectedIndex = 3;
  final RanksService _ranksService = RanksService();
  final StudentStatsService _studentStatsService = StudentStatsService();
  bool _loading = true;

  List<Map<String, dynamic>> _ranks = [];

  @override
  void initState() {
    super.initState();
    _loadRanks();
  }

  Future<void> _loadRanks() async {
    try {
      final ranks = await _ranksService.getStudentRanks();
      setState(() {
        _ranks = ranks;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de chargement des rangs')),
      );
    }
  }

  void _onBottomNavTap(int index) {
    if (_selectedIndex != index) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/student-dashboard');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/student/courses');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/student/xcode');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/admin-dashboard'),
        ),
        title: const Text(
          'Classement',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ranks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Pas encore de classement disponible',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Podium and Top 3 Section
                          SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Podium
                                Positioned(
                                  bottom: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildPodiumStep(
                                          '2', 120, Colors.indigo.shade100),
                                      const SizedBox(width: 2),
                                      _buildPodiumStep(
                                          '1', 160, Colors.indigo.shade100),
                                      const SizedBox(width: 2),
                                      _buildPodiumStep(
                                          '3', 80, Colors.indigo.shade100),
                                    ],
                                  ),
                                ),
                                // Top 3 students
                                if (_ranks.length > 1)
                                  Positioned(
                                    left: 20,
                                    bottom: 140,
                                    child: _buildTopThreeItem(_ranks[1], 180),
                                  ),
                                if (_ranks.isNotEmpty)
                                  Positioned(
                                    bottom: 180,
                                    child: _buildTopThreeItem(_ranks[0], 220),
                                  ),
                                if (_ranks.length > 2)
                                  Positioned(
                                    right: 20,
                                    bottom: 100,
                                    child: _buildTopThreeItem(_ranks[2], 160),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    // Autres rangs
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final rank = _ranks[index + 3];
                            return _buildRankListItem(rank, index + 4);
                          },
                          childCount: _ranks.length > 3 ? _ranks.length - 3 : 0,
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildTopThreeItem(Map<String, dynamic> user, double height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user['rank'] == 1)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.crop, color: Colors.white),
          ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 35,
          backgroundColor: _getBackgroundColor(user['rank']),
          child: const Icon(Icons.person, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 12),
        Text(
          user['full_name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.indigo.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '${user['total_points']}',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFF98FB98);
      case 2:
        return const Color(0xFFFFB6C1);
      case 3:
        return const Color(0xFFADD8E6);
      default:
        return const Color(0xFFE6E6FA);
    }
  }

  Widget _buildPodiumStep(String position, double height, Color color) {
    return Container(
      width: 100,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Center(
        child: Text(
          position,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

Widget _buildRankListItem(Map<String, dynamic> rank, int position) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
        ),
      ],
    ),
    child: Row(
      children: [
        // Position
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          child: Center(
            child: Text(
              '$position',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Avatar
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFE6E6FA),
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 15),
        // Nom et points
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rank['full_name'] ?? 'Inconnu',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${rank['total_points']} points',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
