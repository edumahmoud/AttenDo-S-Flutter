import 'package:flutter/material.dart';

class CoursePage extends StatelessWidget {
  final String courseId;
  const CoursePage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CoursePage')),
      body: const Center(child: Text('Stub for CoursePage')),
    );
  }
}
