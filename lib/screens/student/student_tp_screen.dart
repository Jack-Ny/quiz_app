import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class StudentTPScreen extends StatefulWidget {
  final String moduleTitle;
  final String courseTitle;

  const StudentTPScreen({
    super.key,
    required this.moduleTitle,
    required this.courseTitle,
  });

  @override
  State<StudentTPScreen> createState() => _StudentTPScreenState();
}

class _StudentTPScreenState extends State<StudentTPScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.moduleTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text('TP pour le cours: ${widget.courseTitle}'),
      ),
    );
  }
}
