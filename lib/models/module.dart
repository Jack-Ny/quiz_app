import 'package:uuid/uuid.dart';

import 'course.dart';
import 'quiz.dart';
import 'tp.dart';

class Module {
  String id;
  String? courseId;
  String name;
  String? description;
  int orderIndex;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  // Relations
  Course? course;
  List<TP> tps;
  List<Quiz> quizzes;

  Module({
    String? id,
    this.courseId,
    required this.name,
    this.description,
    this.orderIndex = 0,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.course,
    this.tps = const [],
    this.quizzes = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'description': description,
      'order_index': orderIndex,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      courseId: json['course_id'],
      name: json['name'],
      description: json['description'],
      orderIndex: json['order_index'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
