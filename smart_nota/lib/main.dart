import 'package:flutter/material.dart';
import 'features/upload_page.dart';

Future<void> main() async {
  // pastikan Flutter binding siap
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "NotaKu",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const UploadPage(), // kasih const biar konsisten
    );
  }
}
