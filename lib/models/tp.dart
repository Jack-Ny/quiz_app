import 'dart:io';

import 'package:uuid/uuid.dart';

import 'module.dart';
import 'tp_submission.dart';

class TP {
  String id;
  String? moduleId;
  String title;
  String description;
  DateTime? dueDate;
  int? maxPoints;
  bool isActive;
  DateTime createdAt;
  List<String> fileUrls;
  List<File>? files;

  // Relations
  Module? module;
  List<TPSubmission> submissions;

  TP({
    String? id,
    this.moduleId,
    required this.title,
    required this.description,
    this.dueDate,
    this.maxPoints,
    this.isActive = true,
    DateTime? createdAt,
    List<String>? fileUrls,
    this.files,
    this.module,
    List<TPSubmission>? submissions,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        fileUrls = fileUrls ?? [],
        submissions = submissions ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'max_points': maxPoints,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'file_urls': fileUrls.toList(),
    };
  }

  factory TP.fromJson(Map<String, dynamic> json) {
    return TP(
      id: json['id'],
      moduleId: json['module_id'],
      title: json['title'],
      description: json['description'],
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      maxPoints: json['max_points'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      fileUrls:
          (json['file_urls'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

// methode pour copier
  TP copyWith({
    String? id,
    String? moduleId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? maxPoints,
    bool? isActive,
    DateTime? createdAt,
    List<String>? fileUrls,
    List<File>? files,
    Module? module,
    List<TPSubmission>? submissions,
  }) {
    return TP(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      maxPoints: maxPoints ?? this.maxPoints,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      fileUrls: fileUrls ?? this.fileUrls,
      files: files ?? this.files,
      module: module ?? this.module,
      submissions: submissions ?? this.submissions,
    );
  }
}
