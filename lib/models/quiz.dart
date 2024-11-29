import 'package:uuid/uuid.dart';

import 'module.dart';
import 'question.dart';
import 'quiz_attempt.dart';

class Quiz {
  String id;
  String? moduleId;
  String title;
  int timeLimit;
  String timeUnit;
  int passingScore;
  bool isActive;
  DateTime createdAt;

  // Relations
  Module? module;
  List<Question> questions;
  List<QuizAttempt> attempts;

  Quiz({
    String? id,
    this.moduleId,
    required this.title,
    required this.timeLimit,
    required this.timeUnit,
    this.passingScore = 75,
    this.isActive = true,
    DateTime? createdAt,
    this.module,
    this.questions = const [],
    this.attempts = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'time_limit': timeLimit,
      'time_unit': timeUnit,
      'passing_score': passingScore,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      moduleId: json['module_id'],
      title: json['title'],
      timeLimit: json['time_limit'],
      timeUnit: json['time_unit'],
      passingScore: json['passing_score'] ?? 75,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
