import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_response_screen.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class NextScreen extends StatefulWidget {
  final List<File> images;
  const NextScreen({super.key, required this.images});

  @override
  State<NextScreen> createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen> {
  bool _loading = false;

  String _getMimeType(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg'; // default
  }

  Future<String?> _detectFaceShape(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    final faceDetector = FaceDetector(options: options);
    final faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();
    if (faces.isEmpty) return null;
    final face = faces.first;
    // Use available landmarks
    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final mouthLeft = face.landmarks[FaceLandmarkType.mouthLeftPoint]?.position;
    final mouthRight = face.landmarks[FaceLandmarkType.mouthRightPoint]?.position;
    if (leftCheek == null || rightCheek == null || noseBase == null || mouthLeft == null || mouthRight == null) return null;
    final faceWidth = (rightCheek.x - leftCheek.x).abs();
    final mouthAvgY = (mouthLeft.y + mouthRight.y) / 2;
    final faceHeight = (mouthAvgY - noseBase.y).abs();
    final ratio = faceWidth / faceHeight;
    if (ratio > 0.95 && ratio < 1.05) return 'round';
    if (ratio < 0.95) return 'oval';
    if (ratio > 1.05) return 'square';
    return 'unknown';
  }

  Future<void> _sendToOpenAI(BuildContext context) async {
    setState(() => _loading = true);
    try {
      // Only use the first image for face shape detection
      final faceShape = await _detectFaceShape(widget.images.first);
      if (faceShape == null || faceShape == 'unknown') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect face shape.')),
        );
        setState(() => _loading = false);
        return;
      }
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OpenAI API key not found.')),
        );
        setState(() => _loading = false);
        return;
      }
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final messages = [
        {
          "role": "user",
          "content": [
            {"type": "text", "text": "My face shape is $faceShape. Based on visagism, what haircut styles would best suit me?"}
          ]
        }
      ];
      final body = jsonEncode({
        "model": "gpt-4o",
        "messages": messages,
        "max_tokens": 300
      });
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );
      String resultText = response.body;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        resultText = decoded["choices"]?[0]?['message']?["content"] ?? response.body;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OpenAIResponseScreen(response: resultText),
        ),
      );
    } catch (e, stack) {
      print('Error: $e');
      print('Stack trace: $stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e\n$stack')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: widget.images.isEmpty
          ? const Center(child: Text('Error, please take pictures again', style: TextStyle(fontSize: 32)))
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: widget.images
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
                if (_loading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 24),
                          Text(
                            'Analyzing your best haircut, wait',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 16),
            child: FloatingActionButton.extended(
              heroTag: 'cancel',
              onPressed: _loading ? null : () {
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
                // TODO: Implement confirm action
                // onPressed: null,
              onPressed: _loading ? null : () => _sendToOpenAI(context),
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
