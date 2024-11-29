import 'package:uuid/uuid.dart';

import 'student.dart';
import 'teacher.dart';
import 'tp.dart';

class TPSubmission {
  String id;
  String? tpId;
  String? studentId;
  Map<String, dynamic> submittedFiles;
  String? comment;
  DateTime submissionDate;
  int? grade;
  String? gradedBy;
  DateTime? gradedAt;

  // Relations
  TP? tp;
  Student? student;
  Teacher? gradedByTeacher;

  TPSubmission({
    String? id,
    this.tpId,
    this.studentId,
    required this.submittedFiles,
    this.comment,
    DateTime? submissionDate,
    this.grade,
    this.gradedBy,
    this.gradedAt,
    this.tp,
    this.student,
    this.gradedByTeacher,
  })  : id = id ?? const Uuid().v4(),
        submissionDate = submissionDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tp_id': tpId,
      'student_id': studentId,
      'submitted_files': submittedFiles,
      'comment': comment,
      'submission_date': submissionDate.toIso8601String(),
      'grade': grade,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
    };
  }

  factory TPSubmission.fromJson(Map<String, dynamic> json) {
    return TPSubmission(
      id: json['id'],
      tpId: json['tp_id'],
      studentId: json['student_id'],
      submittedFiles: json['submitted_files'],
      comment: json['comment'],
      submissionDate: DateTime.parse(json['submission_date']),
      grade: json['grade'],
      gradedBy: json['graded_by'],
      gradedAt:
          json['graded_at'] != null ? DateTime.parse(json['graded_at']) : null,
    );
  }
}
