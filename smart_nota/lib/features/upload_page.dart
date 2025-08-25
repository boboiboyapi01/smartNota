import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '/core/ocr_service.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  Uint8List? _imageBytes;
  String? _result;
  final _ocrService = OCRService();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final bytes = result.files.first.bytes;
      if (bytes != null) {
        setState(() {
          _imageBytes = bytes;
          _result = "Processing...";
        });

        final res = await _ocrService.extractTable(bytes);
        setState(() => _result = res ?? "Failed to extract text.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NotaKu (Web Demo)")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text("Upload Nota"),
            ),
            const SizedBox(height: 16),
            if (_imageBytes != null)
              Image.memory(_imageBytes!, height: 200),
            const SizedBox(height: 16),
            if (_result != null)
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    _result!,
                    style: const TextStyle(fontFamily: "monospace"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
