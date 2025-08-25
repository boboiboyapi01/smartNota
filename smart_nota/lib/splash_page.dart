import 'package:flutter/material.dart';
import '/core/ocr_service.dart';
import '/features/upload_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _ocrService = OCRService();
  String _status = "Connecting to backend...";

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final ok = await _ocrService.pingBackend();
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UploadPage()),
      );
    } else {
      setState(() => _status = "Failed to connect. Please restart app.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(_status)),
    );
  }
}
