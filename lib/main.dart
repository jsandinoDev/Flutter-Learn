import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'next_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<XFile> _selectedImages = [];

  Future<void> _selectMultipleFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.take(3).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedImages.length} images selected')),
      );
      // Automatically navigate to next page after images are selected
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NextScreen(
              images: _selectedImages.map((x) => File(x.path)).toList(),
            ),
          ),
        );
      });
    }
  }

  Future<void> _takePictures(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    List<XFile> takenImages = [];
    for (int i = 0; i < 3; i++) {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        takenImages.add(image);
        if (i < 2) {
          final continueTaking = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Take another picture?'),
              content: Text('You have taken \\${takenImages.length} picture(s).'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Done'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Take another'),
                ),
              ],
            ),
          );
          if (continueTaking != true) break;
        }
      } else {
        break;
      }
    }
    if (takenImages.isNotEmpty) {
      setState(() {
        _selectedImages = takenImages;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Taken: \\${_selectedImages.length} images')),
      );
      // Automatically navigate to next page after images are taken
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NextScreen(
              images: _selectedImages.map((x) => File(x.path)).toList(),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('The Right Cut'),
        ),

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Builder(
                builder: (parentContext) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: parentContext,
                      builder: (BuildContext modalContext) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Take a picture'),
                                onTap: () {
                                  Navigator.pop(modalContext);
                                  _takePictures(parentContext);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Select from gallery'),
                                onTap: () {
                                  Navigator.pop(modalContext);
                                  _selectMultipleFromGallery(parentContext);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text("Take or select pictures"),
                ),
              ),
              const SizedBox(height: 24),
              // if (_selectedImages.isNotEmpty)
              //   Column(
              //     children: [
              //       Wrap(
              //         spacing: 8,
              //         children: _selectedImages.map((img) => Image.file(
              //           File(img.path),
              //           width: 80,
              //           height: 80,
              //           fit: BoxFit.cover,
              //         )).toList(),
              //       ),
              //       const SizedBox(height: 16),
              //     ],
              //   ),
            ],
          ),
        )
      )
      );
  }
}