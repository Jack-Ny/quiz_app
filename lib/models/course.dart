import 'package:uuid/uuid.dart';

import 'module.dart';
import 'student.dart';
import 'teacher.dart';
import 'user.dart';

class Course {
  String id;
  String name;
  String? description;
  String? createdBy;
  DateTime createdAt;
  DateTime updatedAt;
  bool isActive;

  // Relations
  List<Module> modules;
  List<Student> enrolledStudents;
  List<Teacher> teachers;
  AppUser? creator;

  Course({
    String? id,
    required this.name,
    this.description,
    this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    this.modules = const [],
    this.enrolledStudents = const [],
    this.teachers = const [],
    this.creator,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'] ?? true,
    );
  }
}
