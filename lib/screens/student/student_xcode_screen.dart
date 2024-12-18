import 'package:app_school/main.dart';
import 'package:flutter/material.dart';
import 'package:flython/flython.dart';
import '../../config/jdoodle.dart';
import '../../constants/colors.dart';

class StudentXCodeScreen extends StatefulWidget {
  const StudentXCodeScreen({super.key});

  @override
  State<StudentXCodeScreen> createState() => _StudentXCodeScreenState();
}

class _StudentXCodeScreenState extends State<StudentXCodeScreen> {
  final int _selectedIndex = 2;
  final TextEditingController _codeController = TextEditingController();
  String _outputResult = '';
  final Flython _flython = Flython();
  final PythonCompiler _pythonCompiler = PythonCompiler();

  @override
  void initState() {
    super.initState();
    _initializePython();
  }

  Future<void> _initializePython() async {
    try {
      await _flython.initialize(
        'python',
        'main.py',
        true,
      );
      print('Initialisation de Flython réussie');
    } catch (e) {
      print('Détails complets de l\'erreur : $e');
      print('Trace de la pile : ${StackTrace.current}');
      setState(() {
        _outputResult = 'Erreur d\'initialisation : $e';
      });
    }
  }

  Future<void> _executePythonCode() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir du code Python')),
      );
      return;
    }

    try {
      final result = await _pythonCompiler.executeCode(_codeController.text);
      setState(() {
        _outputResult = result['output'] ?? 'Exécution terminée';
      });
    } catch (e) {
      setState(() {
        _outputResult = 'Erreur d\'exécution : $e';
      });
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/student-dashboard'),
        ),
        title: const Text(
          'XCODE',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Zone de saisie de code
              TextField(
                controller: _codeController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: 'Saisissez votre code Python ici...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton d'exécution
              ElevatedButton(
                onPressed: _executePythonCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Exécuter le code',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 16),

              // Zone de résultat
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _outputResult.isEmpty
                      ? 'Les résultats s\'afficheront ici'
                      : _outputResult,
                  style: TextStyle(
                    fontSize: 16,
                    color: _outputResult.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ],
          ),
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
}

// Classe personnalisée pour l'exécution de Python
class PythonCompiler extends Flython {
  static const int CMD_EXECUTE_CODE = 1;

  Future<dynamic> executeCode(String pythonCode) async {
    var command = {"cmd": CMD_EXECUTE_CODE, "code": pythonCode};
    return await runCommand(command);
  }
}
