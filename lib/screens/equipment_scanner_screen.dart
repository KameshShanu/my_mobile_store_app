import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Added for Base64 image encoding
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

  Future<void> _openCamera() async {
    try {
      // Added maxWidth, maxHeight, and imageQuality to compress under Firestore's 1MB limit
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (photo != null) {
        setState(() {
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
      _aiResult = "";
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-3.8-flash', // Updated to current supported model
        apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
        requestOptions: const RequestOptions(apiVersion: 'v1'),
      );

      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(
        imageBytes,
      ); // Encode image for Firestore

      final content = [
        Content.multi([
          TextPart(
            "You are a professional rigger and safety inspector. "
            "Analyze this equipment image and provide the response in EXACTLY this format with clear headings:\n\n"
            "EQUIPMENT_NAME: [Name of equipment]\n"
            "EQUIPMENT_TYPE: [Type / Application]\n"
            "OVERALL_STATUS: [PASSED / NEEDS MAINTENANCE / CRITICAL]\n"
            "CORROSION_STATUS: [Status details on rust/wear]\n"
            "ELECTRICAL_STATUS: [Status details on cords/buttons]\n"
            "RECOMMENDATIONS: [Brief safety recommendation]",
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final text = response.text ?? "Could not identify equipment.";

      setState(() {
        _aiResult = text;
        _isLoading = false;
      });

      // Extract parsed equipment name dynamically
      final parsedEquipmentName = _parseField(text, "EQUIPMENT_NAME");

      // Save analysis, dynamic name, and image to Firestore
      await _saveInspectionToFirebase(text, parsedEquipmentName, base64Image);
    } catch (e) {
      print("Gemini Error: $e");
      setState(() {
        _aiResult = "Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveInspectionToFirebase(
    String analysisText,
    String equipmentName,
    String base64Image,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final String inspectorId = user != null ? user.uid : 'local_inspector';
    // Removed "if (user == null) return;" so local test writes succeed

    try {
      await FirebaseFirestore.instance.collection('inspections').add({
        'inspectorId': inspectorId,
        'equipmentType':
            equipmentName.isNotEmpty && equipmentName != "Not specified"
            ? equipmentName
            : 'Equipment Inspection',
        'analysis': analysisText,
        'imageUrl':
            base64Image, // Stores compressed image data for dashboard preview
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Inspection report saved successfully!"),
          backgroundColor: Colors.grey.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error saving to Firebase: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Save Failed: $e"),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Added compression limits here as well for gallery uploads
    final XFile? selectedImage = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (selectedImage != null) {
      setState(() {
        _image = File(selectedImage.path);
      });
      _identifyEquipmentWithAI(_image!);
    }
  }

  String _parseField(String text, String key) {
    try {
      final regExp = RegExp(
        r'(?:\*\*|)?' + key + r'(?:\*\*|)?\s*[:\-]\s*(.*)',
        caseSensitive: false,
      );
      for (final line in text.split('\n')) {
        final match = regExp.firstMatch(line);
        if (match != null && match.group(1) != null) {
          return match.group(1)!.replaceAll('*', '').trim();
        }
      }
      return "Not specified";
    } catch (_) {
      return "Not specified";
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentName = _parseField(_aiResult, "EQUIPMENT_NAME");
    final equipmentType = _parseField(_aiResult, "EQUIPMENT_TYPE");
    final overallStatus = _parseField(_aiResult, "OVERALL_STATUS");
    final corrosionStatus = _parseField(_aiResult, "CORROSION_STATUS");
    final electricalStatus = _parseField(_aiResult, "ELECTRICAL_STATUS");
    final recommendations = _parseField(_aiResult, "RECOMMENDATIONS");

    bool isPassed =
        overallStatus.toUpperCase().contains("PASS") ||
        overallStatus.toUpperCase().contains("ACCEPTABLE");

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Safety Inspection Hub",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Action Source Selector
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        "Capture Photo",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.black87,
                        size: 20,
                      ),
                      label: const Text(
                        "Upload File",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Image Preview Container
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_search_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No equipment media loaded",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              if (_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: const [
                      CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Gemini is analyzing structural integrity...",
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              if (!_isLoading && _aiResult.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPassed
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          color: isPassed
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipmentName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              equipmentType,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          overallStatus,
                          style: TextStyle(
                            color: isPassed
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _buildInspectionDetailCard(
                  "Rust & Corrosion Check",
                  corrosionStatus,
                  Icons.shield_outlined,
                ),
                const SizedBox(height: 12),
                _buildInspectionDetailCard(
                  "Electrical & Fraying Check",
                  electricalStatus,
                  Icons.bolt_rounded,
                ),
                const SizedBox(height: 12),
                _buildInspectionDetailCard(
                  "Inspector Recommendations",
                  recommendations,
                  Icons.assignment_outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionDetailCard(
    String title,
    String content,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF4F4F4)),
          ),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
