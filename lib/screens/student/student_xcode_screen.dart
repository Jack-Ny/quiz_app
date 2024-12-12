import 'package:flutter/material.dart';
import '../../config/jdoodle.dart';
import '../../constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentXCodeScreen extends StatefulWidget {
  const StudentXCodeScreen({super.key});

  @override
  State<StudentXCodeScreen> createState() => _StudentXCodeScreenState();
}

class _StudentXCodeScreenState extends State<StudentXCodeScreen> {
  final int _selectedIndex = 2; // Pour la bottomNavigationBar (XCODE)

  String _selectedLanguage = 'python3';
  final TextEditingController _codeController = TextEditingController();
  String _output = '';
  bool _isRunning = false;

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

  Future<String> getAuthToken() async {
    final url = Uri.parse('https://api.jdoodle.com/v1/auth-token');
    final headers = {'Content-Type': 'application/json'};

    final body = json.encode({
      'clientId': JDoodleConfig.clientId,
      'clientSecret': JDoodleConfig.clientSecret,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['statusCode'] == 200) {
          return responseData['output'];
        } else {
          throw Exception(
              'Failed to obtain auth token: ${responseData['statusCode']}');
        }
      } else {
        throw Exception(
            'Failed to get auth token with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> _executeCode() async {
    setState(() {
      _isRunning = true;
      _output = ''; // Reset previous output
    });

    try {
      String result =
          await executeCode(_codeController.text, _selectedLanguage);
      setState(() {
        _output = result;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _output = 'Error executing code : $e';
        print('Error: $e');
        _isRunning = false;
      });
    }
  }

  Future<String> executeCode(String code, String language) async {
    final authToken = await getAuthToken();
    final url = Uri.parse(JDoodleConfig.apiUrl);
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = json.encode({
      'script': code,
      'stdin': '',
      'language': language,
      'versionIndex': '3',
      'compileOnly': false,
      'clientId': JDoodleConfig.clientId,
      'clientSecret': JDoodleConfig.clientSecret,
      'authToken': authToken,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['statusCode'] == 200) {
          return responseData['output'];
        } else {
          throw Exception(
              'API returned error: ${responseData['statusCode']} - ${responseData['status']}.');
        }
      } else {
        throw Exception(
            'Failed to execute code with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
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
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Card responsive
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity, // S'adapte à la taille de l'écran
                  child: Column(
                    children: [
                      // Row avec le Select et le bouton Run
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Select Language
                          DropdownButton<String>(
                            value: _selectedLanguage,
                            items: const [
                              DropdownMenuItem(
                                  value: 'python3', child: Text('Python')),
                              DropdownMenuItem(
                                  value: 'java', child: Text('Java')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedLanguage = value!;
                              });
                            },
                          ),
                          // Button Run
                          IconButton(
                            icon: Icon(Icons.play_arrow),
                            onPressed: _isRunning ? null : _executeCode,
                          ),
                        ],
                      ),
                      // Code input
                      TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your code here...',
                          border: OutlineInputBorder(),
                          labelText: 'Code',
                        ),
                        maxLines: 10,
                      ),
                    ],
                  ),
                ),
              ),
              // Résultat en bas (fenêtre modale)
              if (_output.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(blurRadius: 10, color: Colors.black26)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Output:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(_output),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _output =
                                  ''; // Ferme la fenêtre en réinitialisant le résultat
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ]
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
