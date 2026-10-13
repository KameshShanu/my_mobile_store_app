import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class EquipmentScannerScreen extends StatefulWidget {
  const EquipmentScannerScreen({super.key});

  @override
  State<EquipmentScannerScreen> createState() => _EquipmentScannerScreenState();
}

class _EquipmentScannerScreenState extends State<EquipmentScannerScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _aiResult = "";

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

  Future<void> _identifyEquipmentWithAI(File image) async {
    setState(() {
      _isLoading = true;
      _aiResult = "Analyzing equipment...";
    });

    try {
      // 1. Setup the model
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: 'AIzaSyBajGtWi9Mn2vNM06U1PACgUsFkLJ0XIpQ',
        requestOptions: const RequestOptions(apiVersion: 'v1'),
      );

      // 2. Prepare the image for the AI
      final imageBytes = await image.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            "You are a professional rigger and safety inspector. "
            "Identify this equipment and provide a brief safety check "
            "status (check for rust, fraying, or mechanical wear).",
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      // 3. Generate the response
      final response = await model.generateContent(content);

      setState(() {
        _aiResult = response.text ?? "Could not identify equipment.";
        _isLoading = false;
      });

      await _saveInspectionToFirebase(_aiResult);
    } catch (e) {
      print("Gemini Error: $e");
      setState(() {
        _aiResult = "Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveInspectionToFirebase(String analysisText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('inspections').add({
        'inspectorId': user.uid,
        'equipmentType':
            'Traction Hoist', // We can eventually let the AI parse this
        'analysis': analysisText,
        'timestamp': FieldValue.serverTimestamp(),
        // We'll add the imageUrl once we set up Firebase Storage
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inspection saved to database!")),
      );
    } catch (e) {
      debugPrint("Error saving to Firebase: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    if (selectedImage != null) {
      setState(() {
        _image = File(selectedImage.path);
      });
      // Call the AI analysis function directly
      _identifyEquipmentWithAI(_image!);
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Equipment Scanner",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Camera & Gallery Toggle Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text(
                        "Camera",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.black87,
                      ),
                      label: const Text(
                        "Gallery",
                        style: TextStyle(color: Colors.black87),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Image Preview Area
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Center(
                        child: Text(
                          "Capture or upload a photo of the equipment",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // 3. Loading State Indicator
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: const [
                      CircularProgressIndicator(color: Colors.black),
                      SizedBox(height: 12),
                      Text(
                        "Analyzing equipment with AI...",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. Premium AI Result Card
              if (!_isLoading && _aiResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.verified_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "AI Inspection Summary",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      SelectableText(
                        _aiResult,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
