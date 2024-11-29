import 'package:uuid/uuid.dart';

import 'course.dart';
import 'user.dart';

class Teacher {
  String id;
  String? userId;
  String specialization;

  // Relations
  AppUser? user;
  List<Course> courses;

  Teacher({
    String? id,
    this.userId,
    required this.specialization,
    this.user,
    this.courses = const [],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'specialization': specialization,
    };
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      userId: json['user_id'],
      specialization: json['specialization'],
    );
  }
}
