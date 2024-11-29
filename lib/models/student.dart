import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'course.dart';
import 'parent.dart';

class Student {
  String id;
  String? userId;
  String registrationNumber;
  String classLevel;
  String? parentId;

  // Relations
  User? user;
  List<Course> enrolledCourses;
  Parent? parent;

  Student({
    String? id,
    this.userId,
    required this.registrationNumber,
    required this.classLevel,
    this.parentId,
    this.user,
    this.enrolledCourses = const [],
    this.parent,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'registration_number': registrationNumber,
      'class_level': classLevel,
      'parent_id': parentId,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      userId: json['user_id'],
      registrationNumber: json['registration_number'],
      classLevel: json['class_level'],
      parentId: json['parent_id'],
    );
  }
}
