import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OCRService {
  final String baseUrl = "http://localhost:5000"; // base URL backend

  Future<bool> pingBackend() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/ping"));
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Ping failed: $e");
      return false;
    }
  }

  Future<String?> extractTable(Uint8List imageBytes) async {
    try {
      // Convert ke base64 + tambahkan prefix
      final base64Image = base64Encode(imageBytes);
      final formattedImage = "data:image/png;base64,$base64Image";

      // Kirim ke backend /ocr
      final response = await http.post(
        Uri.parse("$baseUrl/ocr"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": formattedImage}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body["output"]?.toString(); // backend balikin field "output"
      } else {
        print("Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }
}
