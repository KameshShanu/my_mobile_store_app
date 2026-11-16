import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';

class InspectionDetailScreen extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const InspectionDetailScreen({
    super.key,
    required this.documentId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String equipmentType =
        (data['equipmentType'] as String?)?.trim().isNotEmpty == true
        ? data['equipmentType']
        : 'Equipment Inspection';
    final String analysis =
        (data['analysis'] as String?) ?? 'No detailed analysis available.';
    final String inspectorId = (data['inspectorId'] as String?) ?? 'Unknown';
    final String? imageUrl = data['imageUrl'] as String?;
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    final String formattedDate = timestamp != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate())
        : 'Date not recorded';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Inspection Report',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_outlined,
                          color: Colors.lightBlueAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipmentType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.12)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: Saved • Verified by Gemini',
                        style: TextStyle(
                          color: Colors.greenAccent[200],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'ID: ${documentId.substring(0, documentId.length > 8 ? 8 : documentId.length)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Captured Equipment Image Card (Shows if imageUrl exists)
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Text('Unable to load image')),
                        )
                      : Image.memory(
                          base64Decode(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('Unable to decode image'),
                          ),
                        ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Full AI Analysis Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Full AI Safety Analysis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: analysis,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      h3: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.8,
                      ),
                      p: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      listBullet: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metadata Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Inspector ID: $inspectorId',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
