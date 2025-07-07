import 'package:flutter/material.dart';

class OpenAIResponseScreen extends StatelessWidget {
  final String response;
  const OpenAIResponseScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Best Haircut')),
      body: Padding(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(response, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text('Try Again', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Set button color to blue
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
