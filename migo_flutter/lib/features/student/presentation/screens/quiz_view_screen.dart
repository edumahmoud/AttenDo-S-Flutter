import 'package:flutter/material.dart';

class QuizViewScreen extends StatelessWidget {
  final String quizId;
  const QuizViewScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QuizViewScreen')),
      body: const Center(child: Text('Stub for QuizViewScreen')),
    );
  }
}
