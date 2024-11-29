import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Quiz Screen'),
      ),
      body: const Center(
        child: Text('Quiz Screen Content'),
      ),
    );
  }
}

/* class _StudentQuizScreenState extends State<StudentQuizScreen> {
  /* final _supabase = Supabase.instance.client;
  late Quiz quiz;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  final List<String?> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      final quizData = await _supabase.from('quizzes').select('''
           *,
           questions:questions(
             *,
             answers:answers(*)
           )
         ''').eq('id', widget.quizId).single();

      setState(() {
        quiz = Quiz(
          title: quizData['title'],
          description: quizData['description'],
          questions: (quizData['questions'] as List)
              .map((q) => Question(
                    id: q['id'],
                    text: q['text'],
                    answers: (q['answers'] as List)
                        .map((a) => Answer(
                              text: a['text'],
                              isCorrect: a['is_correct'],
                            ))
                        .toList(),
                  ))
              .toList(), moduleId: '', timeLimit: null,
        );
        _userAnswers.addAll(List.filled(quiz.questions.length, null));
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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final attemptResponse = await _supabase
          .from('quiz_attempts')
          .insert({
            'quiz_id': widget.quizId,
            'student_id': userId,
            'score': _calculateScore(),
          })
          .select()
          .single();

      for (var i = 0; i < _userAnswers.length; i++) {
        if (_userAnswers[i] != null) {
          await _supabase.from('question_responses').insert({
            'attempt_id': attemptResponse['id'],
            'question_id': quiz.questions[i].id,
            'answer_text': _userAnswers[i],
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

  int _calculateScore() {
    int score = 0;
    for (var i = 0; i < quiz.questions.length; i++) {
      if (_userAnswers[i] != null) {
        final correctAnswer =
            quiz.questions?[i].answer.firstWhere((answer) => answer.isCorrect);
        if (_userAnswers[i] == correctAnswer.text) {
          score++;
        }
      }
    }
    return score;
  }

  void _showResults() async {
    await _saveQuizAttempt();
    if (!mounted) return;

    final score = _calculateScore();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: score,
          totalQuestions: quiz.questions.length,
          userName: _supabase.auth.currentUser?.userMetadata?['name'] ??
              "Utilisateur",
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question : ${_currentQuestionIndex + 1}/${quiz.questions.length}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              question.text,
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

  Widget _buildAnswerOptions(Question question) {
    return Column(
      children: question.answers.map((answer) {
        final isSelected = _userAnswers[_currentQuestionIndex] == answer.text;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ElevatedButton(
            onPressed: () => _handleSelection(answer.text),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSelected ? AppColors.primaryBlue : Colors.white,
              foregroundColor: isSelected ? Colors.white : Colors.black87,
              elevation: 0,
              side: BorderSide(
                color:
                    isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              answer.text,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
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
  } */
} */
