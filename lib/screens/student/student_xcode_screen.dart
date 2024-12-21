import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/all.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/colors.dart';
import 'package:flutter_highlight/themes/monokai.dart';


class StudentXCodeScreen extends StatefulWidget {
  const StudentXCodeScreen({super.key});

  @override
  State<StudentXCodeScreen> createState() => _StudentXCodeScreenState();
}

class _StudentXCodeScreenState extends State<StudentXCodeScreen> {
  final int _selectedIndex = 2;
  late CodeController _codeController;
  String _outputResult = '';
  String _selectedLanguage = 'python3';
  bool _isLoading = false;

  final Map<String, String> languageOptions = {
    'python3': 'Python',
    'java': 'Java',
    'c': 'C',
    'php': 'PHP',
  };

  @override
  void initState() {
    super.initState();
     _codeController = CodeController(
      text: '',
      language: allLanguages["python"],
      patternMap: vsTheme,
    );
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _executeCode() async {
    setState(() {
      _isLoading = true;
      _outputResult = 'Exécution en cours...';
    });

    try {
      final response = await http.post(
        Uri.parse('https://online-code-compiler.p.rapidapi.com/v1/'),
        headers: {
          'X-RapidAPI-Key': 'a2394e3d71msh5fb5bf71f03db37p107ca3jsn09fb71304518',
          'X-RapidAPI-Host': 'online-code-compiler.p.rapidapi.com',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'language': _selectedLanguage,
          'version': 'latest',
          'code': _codeController.text,
          'input': null,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _outputResult = result['output'] ?? 'Aucune sortie';
        });
      } else {
        setState(() {
          _outputResult = 'Erreur lors de l\'exécution: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _outputResult = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changeLanguage(String? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
        _codeController.language = allLanguages[newLanguage.replaceAll('3', '')];
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
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/student-dashboard'),
        ),
        title: const Text(
          'XCODE Editor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF252526),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 900;
          
          return Row(
            children: [
              Expanded(
                flex: isWideScreen ? 2 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Language selector and Run button row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF333333),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedLanguage,
                                  dropdownColor: const Color(0xFF333333),
                                  style: const TextStyle(color: Colors.white),
                                  items: languageOptions.entries
                                      .map((e) => DropdownMenuItem(
                                            value: e.key,
                                            child: Text(e.value),
                                          ))
                                      .toList(),
                                  onChanged: _changeLanguage,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _executeCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: Text(_isLoading ? 'Exécution...' : 'Exécuter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Code editor
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: CodeField(
                            controller: _codeController,
                            textStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      
                      if (!isWideScreen) ...[
                        const SizedBox(height: 16),
                        // Output section for mobile/narrow screens
                        Container(
                          height: 150,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252526),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _outputResult.isEmpty
                                  ? 'Les résultats s\'afficheront ici'
                                  : _outputResult,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isWideScreen)
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252526),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Console Output',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _outputResult.isEmpty
                                  ? 'Les résultats s\'afficheront ici'
                                  : _outputResult,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF252526),
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