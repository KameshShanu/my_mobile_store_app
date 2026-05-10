import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EquipmentScannerScreen extends StatefulWidget {
  const EquipmentScannerScreen({super.key});

  @override
  State<EquipmentScannerScreen> createState() => _EquipmentScannerScreenState();
}

class _EquipmentScannerScreenState extends State<EquipmentScannerScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // 2. Create the function that triggers the camera
  Future<void> _openCamera() async {
    try {
      // THIS LINE IS THE TRIGGER
      // It tells iOS: "I need the camera now."
      // iOS will then check your Info.plist and show the popup.
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() {
          // This is where you store the image to show it on screen
          _image = File(photo.path);
        });
        _identifyEquipmentWithAI(_image!);
      }
    } catch (e) {
      print("Error opening camera: $e");
    }
  }

  void _identifyEquipmentWithAI(File image) {
    print("AI is ready to look at: ${image.path}");
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    if (selectedImage != null) {
      setState(() {
        _image = File(selectedImage.path);
      });
      // This is where we will eventually call the AI to identify the gear
      _identifyEquipment();
    }
  }

  void _identifyEquipment() {
    // Placeholder for AI Logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Analyzing equipment... (Connecting to AI)"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Scanner"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Image Preview Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Text("Capture or Upload a photo of the equipment"),
                    ),
            ),
          ),

          // 2. Button Action Area
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // CAMERA BUTTON
                ElevatedButton.icon(
                  onPressed:
                      _openCamera, // Calls your fixed _openCamera function
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),

                // GALLERY BUTTON
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
