import 'package:uuid/uuid.dart';

import 'quiz.dart';

class Question {
  String id;
  String? quizId;
  String questionText;
  String questionType;
  String answer;
  int points;
  List<String> choices;
  DateTime createdAt;
  static const List<String> validTypes = [
    'trueFalse',
    'singleAnswer',
    'selection'
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case 'trueFalse':
        return 'Vrai/Faux';
      case 'singleAnswer':
        return 'Réponse unique';
      case 'selection':
        return 'Sélection multiple';
      default:
        return type;
    }
  }

  // Relations
  Quiz? quiz;

  Question({
    String? id,
    this.quizId,
    required this.questionText,
    required String questionType,
    required this.answer,
    required this.points,
    DateTime? createdAt,
    this.quiz,
    List<String>? choices,
  })  : id = id ?? const Uuid().v4(),
        questionType = questionType,
        createdAt = createdAt ?? DateTime.now(),
        choices = choices ?? [] {
    if (!validTypes.contains(this.questionType)) {
      throw ArgumentError(
          'Type de question invalide: $questionType. Les types valides sont: $validTypes');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': questionType,
      'answer': answer,
      'points': points,
      'choices': choices,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      answer: json['answer'],
      points: json['points'],
      choices: List<String>.from(json['choices'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
