import 'package:flutter/material.dart';

class OpenAIResponseScreen extends StatelessWidget {
  final String response;
  const OpenAIResponseScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Best Haircut')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(response, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
