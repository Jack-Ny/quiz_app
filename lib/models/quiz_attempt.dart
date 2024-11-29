import 'package:uuid/uuid.dart';

import 'question_response.dart';
import 'quiz.dart';
import 'student.dart';

class QuizAttempt {
  String id;
  String? studentId;
  String? quizId;
  DateTime startTime;
  DateTime? endTime;
  int? score;
  bool isCompleted;

  // Relations
  Quiz? quiz;
  Student? student;
  List<QuestionResponse> responses;

  QuizAttempt({
    String? id,
    this.studentId,
    this.quizId,
    DateTime? startTime,
    this.endTime,
    this.score,
    this.isCompleted = false,
    this.quiz,
    this.student,
    this.responses = const [],
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'quiz_id': quizId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'score': score,
      'is_completed': isCompleted,
    };
  }

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      studentId: json['student_id'],
      quizId: json['quiz_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      score: json['score'],
      isCompleted: json['is_completed'] ?? false,
    );
  }
}
