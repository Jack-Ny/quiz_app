import 'package:uuid/uuid.dart';

import 'question.dart';
import 'quiz_attempt.dart';

class QuestionResponse {
  String id;
  String? attemptId;
  String? questionId;
  String studentAnswer;
  bool isCorrect;
  int pointsEarned;

  // Relations
  QuizAttempt? attempt;
  Question? question;

  QuestionResponse({
    String? id,
    this.attemptId,
    this.questionId,
    required this.studentAnswer,
    required this.isCorrect,
    required this.pointsEarned,
    this.attempt,
    this.question,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'student_answer': studentAnswer,
      'is_correct': isCorrect,
      'points_earned': pointsEarned,
    };
  }

  factory QuestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestionResponse(
      id: json['id'],
      attemptId: json['attempt_id'],
      questionId: json['question_id'],
      studentAnswer: json['student_answer'],
      isCorrect: json['is_correct'],
      pointsEarned: json['points_earned'],
    );
  }
}
