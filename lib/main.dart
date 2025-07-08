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
          backgroundColor: Colors.blueAccent,
          elevation: 4,
          title: const Text(
            'The Right Cut',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFe3f2fd), Color(0xFF90caf9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.content_cut, size: 56, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'Find your perfect haircut',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Builder(
                builder: (parentContext) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: parentContext,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (BuildContext modalContext) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                                title: const Text('Take a picture', style: TextStyle(fontWeight: FontWeight.w500)),
                                onTap: () {
                                  Navigator.pop(modalContext);
                                  _takePictures(parentContext);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
                                title: const Text('Select from gallery', style: TextStyle(fontWeight: FontWeight.w500)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text("Take or select pictures", style: TextStyle(color: Colors.blueAccent)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        )
      )
      );
  }
}