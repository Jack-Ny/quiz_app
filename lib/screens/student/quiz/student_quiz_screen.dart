import 'dart:convert';

import 'package:app_school/config/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../constants/colors.dart';
import '../../../models/quiz.dart';
import '../../../models/question.dart';
import '../../../models/teacher.dart';
import 'quiz_result_screen.dart';

class StudentQuizScreen extends StatefulWidget {
  final String moduleId;
  final String quizId;
  final String moduleTitle;
  final String courseTitle;

  const StudentQuizScreen({
    super.key,
    required this.moduleId,
    required this.quizId,
    required this.moduleTitle,
    required this.courseTitle,
  });

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
final _supabase = SupabaseConfig.client;
final Map<int, TextEditingController> _answerControllers = {};
  late Quiz quiz;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  final List<String?> _userAnswers = [];
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      final quizData = await _supabase
          .from('quizzes')
          .select('''
          id,
          module_id,
          title,
          time_limit,
          time_unit,
          passing_score,
          is_active,
          created_at,
          questions(
            id,
            quiz_id,
            question_text,
            question_type,
            answer,
            points,
            choices,
            created_at
          )
        ''')
        .eq('id', widget.quizId)
        .single();

           // Correction du parsing des questions et leurs choix
    final questions = (quizData['questions'] as List).map((q) {
      // Gestion correcte du champ choices qui est un JSONB
      List<String> choicesList = [];
      if (q['choices'] != null) {
        if (q['choices'] is String) {
          // Si c'est une chaîne JSON
          choicesList = List<String>.from(jsonDecode(q['choices']));
        } else if (q['choices'] is List) {
          // Si c'est déjà une liste
          choicesList = List<String>.from(q['choices']);
        }
      }
      return Question(
        id: q['id'],
        quizId: q['quiz_id'],
        questionText: q['question_text'],
        questionType: q['question_type'],
        answer: q['answer'],
        points: q['points'],
        choices: choicesList,
        createdAt: DateTime.parse(q['created_at']),
      );
    }).toList();

    if (questions.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ce quiz ne contient aucune question.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
        return;
    }

      setState(() {
      quiz = Quiz(
        id: quizData['id'],
        moduleId: quizData['module_id'],
        title: quizData['title'],
        timeLimit: quizData['time_limit'],
        timeUnit: quizData['time_unit'],
        passingScore: quizData['passing_score'],
        questions: questions,
      );
      _userAnswers.addAll(List.filled(questions.length, null));
      _isLoading = false;
    });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du quiz: $e')),
        );
      }
    }
  }

  void _handleSelection(String answer) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _handleNext() {
    if (_userAnswers[_currentQuestionIndex] != null) {
      setState(() {
        if (_currentQuestionIndex == quiz.questions.length - 1) {
          _showResults();
        } else {
          _currentQuestionIndex++;
        }
      });
    }
  }

  void _handlePrevious() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter le quiz ?'),
            content: const Text(
              'Êtes-vous sûr de vouloir quitter ? Votre progression ne sera pas sauvegardée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Non'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Oui, quitter'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _saveQuizAttempt() async {
    try {
      // Récupérer l'ID utilisateur connecté
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('connected_user_id');
      if (userId == null) throw Exception('Utilisateur non connecté');

      final studentData = await _supabase
        .from('students')
        .select('id')
        .eq('user_id', userId)
        .single();
    
    if (studentData == null) {
      throw Exception('Profil étudiant non trouvé');
    }

    final studentId = studentData['id'];

      final score = _calculateScore();

      final attemptData = await _supabase
          .from('quiz_attempts')
          .insert({
            'quiz_id': widget.quizId,
            'student_id': studentId,
            'start_time': _startTime!.toIso8601String(),
            'end_time': DateTime.now().toIso8601String(),
            'score': score,
            'is_completed': true,
          })
          .select()
          .single();

      for (var i = 0; i < _userAnswers.length; i++) {
        if (_userAnswers[i] != null) {
          // Normaliser les réponses pour la comparaison
        final isCorrect = _verifyAnswer(_userAnswers[i]!, quiz.questions[i]);

          await _supabase.from('question_responses').insert({
            'attempt_id': attemptData['id'],
            'question_id': quiz.questions[i].id,
            'student_answer': _userAnswers[i],
            'is_correct': isCorrect,
            'points_earned': isCorrect ? quiz.questions[i].points : 0,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  int _calculateCorrectAnswers() {
  int correctAnswers = 0;
  for (var i = 0; i < quiz.questions.length; i++) {
    if (_userAnswers[i] != null) {
      final userAnswer = _userAnswers[i]?.trim().toLowerCase() ?? '';
      final correctAnswer = quiz.questions[i].answer.trim().toLowerCase();
      if (userAnswer == correctAnswer) {
        correctAnswers++;
      }
    }
  }
  return correctAnswers;
}

  int _calculateScore() {
  int totalPoints = 0;
  int earnedPoints = 0;

  for (var i = 0; i < quiz.questions.length; i++) {
    if (_userAnswers[i] != null) {
      final userAnswer = _userAnswers[i]?.trim().toLowerCase() ?? '';
      final correctAnswer = quiz.questions[i].answer.trim().toLowerCase();
      
      if (userAnswer == correctAnswer) {
        earnedPoints += quiz.questions[i].points;
      }
      totalPoints += quiz.questions[i].points;
    }
  }

  return totalPoints > 0 ? (earnedPoints * 100 ~/ totalPoints) : 0;
}

  void _showResults() async {
    await _saveQuizAttempt();
    if (!mounted) return;

    final score = _calculateScore();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          correctAnswers: _calculateCorrectAnswers(),
          totalQuestions: quiz.questions.length,
          onReturnPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = quiz.questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => _onWillPop().then((value) {
              if (value) Navigator.pop(context);
            }),
          ),
          title: Text(
            quiz.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / quiz.questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: _buildQuestionCard(currentQuestion),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1}/${quiz.questions.length}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildAnswerOptions(question),
          ],
        ),
      ),
    );
  }

  bool _verifyAnswer(String userAnswer, Question question) {
    final normalizedUserAnswer = userAnswer.trim().toLowerCase();
    final normalizedCorrectAnswer = question.answer.trim().toLowerCase();

    switch (question.questionType) {
      case 'trueFalse':
        return normalizedUserAnswer == normalizedCorrectAnswer;
      case 'singleAnswer':
        return normalizedUserAnswer == normalizedCorrectAnswer;
      case 'selection':
        // Pour les questions à choix multiples
        final userChoices = normalizedUserAnswer.split(',').map((e) => e.trim()).toSet();
        final correctChoices = normalizedCorrectAnswer.split(',').map((e) => e.trim()).toSet();
        return userChoices.difference(correctChoices).isEmpty && 
               correctChoices.difference(userChoices).isEmpty;
      default:
        return false;
    }
  }

  Widget _buildAnswerOptions(Question question) {
    switch (question.questionType) {
      case 'trueFalse':
        return Column(
          children: ['Vrai', 'Faux'].map((option) {
            final isSelected = _userAnswers[_currentQuestionIndex] == option;
            return _buildAnswerButton(option, isSelected);
          }).toList(),
        );
      case 'singleAnswer':
      _answerControllers.putIfAbsent(
          _currentQuestionIndex,
          () => TextEditingController(text: _userAnswers[_currentQuestionIndex] ?? ''),
        );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _answerControllers[_currentQuestionIndex],
          decoration: InputDecoration(
            hintText: 'Saisissez votre réponse',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          onChanged: (value) {
            setState(() {
              _userAnswers[_currentQuestionIndex] = value;
            });
          },
        ),
      );
      case 'selection':
        return Column(
          children: question.choices.map((choice) {
            final selectedAnswers = _userAnswers[_currentQuestionIndex]?.split(',') ?? [];
            final isSelected = selectedAnswers.contains(choice);
            return CheckboxListTile(
              title: Text(choice),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  List<String> currentAnswers = 
                      _userAnswers[_currentQuestionIndex]?.split(',') ?? [];
                  if (value ?? false) {
                    currentAnswers.add(choice);
                  } else {
                    currentAnswers.remove(choice);
                  }
                  _userAnswers[_currentQuestionIndex] = 
                      currentAnswers.where((e) => e.isNotEmpty).join(',');
                });
              },
            );
          }).toList(),
        );
      default:
        return const Text('Type de question non supporté');
    }
  }

  Widget _buildAnswerButton(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: () => _handleSelection(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primaryBlue : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentQuestionIndex > 0)
            ElevatedButton(
              onPressed: _handlePrevious,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Précédent'),
            )
          else
            const SizedBox(width: 100),
          ElevatedButton(
            onPressed: _userAnswers[_currentQuestionIndex] != null
                ? _handleNext
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: Text(
              _currentQuestionIndex == quiz.questions.length - 1
                  ? 'Terminer'
                  : 'Suivant',
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    // Nettoyer les controllers
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
