import 'dart:io';
import 'package:flutter/material.dart';

class NextScreen extends StatelessWidget {
  final List<File> images;
  const NextScreen({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: images.isEmpty
          ? const Center(child: Text('Error, please take pictures again', style: TextStyle(fontSize: 32)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: images
                  .map((img) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Image.file(
                          img,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ))
                  .toList(),
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 16),
            child: FloatingActionButton.extended(
              heroTag: 'cancel',
              onPressed: () {
                Navigator.pop(context);
              },
              backgroundColor: Colors.red,
              label: const Text('Cancel'),
              icon: const Icon(Icons.close),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 32, bottom: 16),
            child: FloatingActionButton.extended(
              heroTag: 'confirm',
              onPressed: () {
                // TODO: Implement confirm action
              },
              backgroundColor: Colors.green,
              label: const Text('Confirm'),
              icon: const Icon(Icons.check),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
