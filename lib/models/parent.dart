import 'package:uuid/uuid.dart';

import 'student.dart';
import 'user.dart';

class Parent {
  String id;
  String? userId;
  String? phoneNumber;

  // Relations
  AppUser? user;
  List<Student> students;

  Parent({
    String? id,
    this.userId,
    this.phoneNumber,
    this.user,
    this.students = const [],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phone_number': phoneNumber,
    };
  }

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'],
      userId: json['user_id'],
      phoneNumber: json['phone_number'],
    );
  }
}
