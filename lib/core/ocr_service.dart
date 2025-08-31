import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:http/http.dart' as http;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class OCRService {
  final String baseUrl = "http://localhost:5000";

  /// Ping backend
  Future<bool> pingBackend() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/ping"));
      return response.statusCode == 200;
    } catch (e) {
      print("Ping failed: $e");
      return false;
    }
  }

  /// Kirim gambar ke backend dan terima JSON hasil OCR
  Future<Map<String, dynamic>?> extractTable(Uint8List imageBytes) async {
    try {
      // Buat multipart request
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/ocr"));

      // Tambahkan file sebagai multipart
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // field name yang diharapkan backend
          imageBytes,
          filename: 'receipt.jpg',
        ),
      );

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error: ${response.statusCode}, ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  /// Simpan JSON hasil OCR ke Excel rapi
  Future<File?> saveToExcel(Map<String, dynamic> data) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Transaksi'];

      // Header informasi
      sheet.appendRow([TextCellValue('Tanggal'), TextCellValue('Nama Toko')]);
      sheet.appendRow([
        TextCellValue(data['tanggal'] ?? ''),
        TextCellValue(data['toko'] ?? ''),
      ]);
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('Item'),
        TextCellValue('Jumlah'),
        TextCellValue('Harga'),
        TextCellValue('Subtotal'),
      ]);

      // Items
      if (data['items'] != null && data['items'] is List) {
        for (var item in data['items']) {
          final jumlah = int.tryParse(item['jumlah']?.toString() ?? '0') ?? 0;
          final harga = int.tryParse(item['harga']?.toString() ?? '0') ?? 0;
          final subtotal = jumlah * harga;

          sheet.appendRow([
            TextCellValue(item['nama'] ?? ''),
            IntCellValue(item['jumlah'] ?? 0),
            IntCellValue(item['harga'] ?? 0),
            IntCellValue(subtotal),
          ]);
        }
      }

      // Total
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('Total'),
        TextCellValue(''),
        TextCellValue(''),
        IntCellValue(data['total'] ?? 0),
      ]);

      // Save file - berbeda untuk web dan mobile/desktop
      if (kIsWeb) {
        // Untuk web, buat file sementara dalam memory
        final bytes = excel.encode()!;
        return _createTempFile(bytes);
      } else {
        // Untuk mobile/desktop
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/transaksi.xlsx');
        await file.writeAsBytes(excel.encode()!);
        print('Excel saved: ${file.path}');
        return file;
      }
    } catch (e) {
      print("Save to Excel failed: $e");
      return null;
    }
  }

  /// Buat file sementara untuk web
  File _createTempFile(List<int> bytes) {
    // Buat file sementara dengan Uint8List
    final uint8List = Uint8List.fromList(bytes);
    return File.fromRawPath(uint8List);
  }

  /// Method khusus untuk mendapatkan bytes Excel (untuk web download)
  Future<Uint8List?> getExcelBytes(Map<String, dynamic> data) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Transaksi'];

      // Header informasi
      sheet.appendRow([TextCellValue('Tanggal'), TextCellValue('Nama Toko')]);
      sheet.appendRow([
        TextCellValue(data['tanggal'] ?? ''),
        TextCellValue(data['toko'] ?? ''),
      ]);
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('Item'),
        TextCellValue('Jumlah'),
        TextCellValue('Harga'),
        TextCellValue('Subtotal'),
      ]);

      // Items
      if (data['items'] != null && data['items'] is List) {
        for (var item in data['items']) {
          final jumlah = int.tryParse(item['jumlah']?.toString() ?? '0') ?? 0;
          final harga = int.tryParse(item['harga']?.toString() ?? '0') ?? 0;
          final subtotal = jumlah * harga;

          sheet.appendRow([
            TextCellValue(item['nama'] ?? ''),
            IntCellValue(item['jumlah'] ?? 0),
            IntCellValue(item['harga'] ?? 0),
            IntCellValue(subtotal),
          ]);
        }
      }

      // Total
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('Total'),
        TextCellValue(''),
        TextCellValue(''),
        IntCellValue(data['total'] ?? 0),
      ]);

      return Uint8List.fromList(excel.encode()!);
    } catch (e) {
      print("Generate Excel bytes failed: $e");
      return null;
    }
  }
}
