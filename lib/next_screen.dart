import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'openai_response_screen.dart';

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

  Future<void> _sendToOpenAI(BuildContext context) async {
    setState(() => _loading = true);
    try {
      List<Map<String, String>> imagesData = [];
      for (final img in widget.images) {
        final bytes = await img.readAsBytes();
        final mime = _getMimeType(img.path);
        imagesData.add({'b64': base64Encode(bytes), 'mime': mime});
      }
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OpenAI API key not found.')),
        );
        setState(() => _loading = false);
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.images.length} images selected')),
        );
      }
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final messages = [
        {
          "role": "system",
          "content":
              "You are a professional visagism consultant. Only answer based on the images provided. Do not provide generic advice, disclaimers, or privacy statements. Go straight to the analysis and recommendations.",
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text":
                  "Analyze the face(s) in these images. What is the face shape? Based only on the images, what haircut styles would best suit this person? Do not provide general information, preambles, or disclaimers. Start your answer directly with the face shape and haircut recommendations.",
            },
            ...imagesData.map(
              (img) => {
                "type": "image_url",
                "image_url": {
                  "url": "data:${img['mime']};base64,${img['b64']}",
                },
              },
            ),
          ],
        },
      ];
      final body = jsonEncode({
        "model": "gpt-4o",
        "messages": messages,
        "max_tokens": 500,
        "temperature": 0.7,
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
        resultText =
            decoded["choices"]?[0]?['message']?["content"] ?? response.body;
        print(resultText);
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OpenAIResponseScreen(response: resultText),
        ),
      );
    } catch (e, stack) {
      // Print error and stack trace to console
      print('Error: $e');
      print('Stack trace: $stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e\n$stack')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: widget.images.isEmpty
          ? const Center(
              child: Text(
                'Error, please take pictures again',
                style: TextStyle(fontSize: 32),
              ),
            )
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: widget.images
                      .map(
                        (img) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Image.file(
                            img,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
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
              onPressed: _loading
                  ? null
                  : () {
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
