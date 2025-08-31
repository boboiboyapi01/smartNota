import 'dart:typed_data';
import 'dart:html' as html; // Untuk web download
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
  Map<String, dynamic>? _jsonData;
  bool _isProcessing = false;
  bool _isDownloading = false;
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
          _jsonData = null;
          _isProcessing = true;
        });

        final res = await _ocrService.extractTable(bytes);
        setState(() {
          _isProcessing = false;
          if (res != null) {
            _jsonData = res;
            _result = _formatJsonDisplay(res);
          } else {
            _result = "Failed to extract text.";
            _jsonData = null;
          }
        });
      }
    }
  }

  String _formatJsonDisplay(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln("=== HASIL OCR ===");
    buffer.writeln("Tanggal: ${data['tanggal'] ?? 'N/A'}");
    buffer.writeln("Nama Toko: ${data['nama_toko'] ?? 'N/A'}");
    buffer.writeln("\n=== ITEMS ===");
    
    if (data['items'] != null && data['items'] is List) {
      for (var item in data['items']) {
        final subtotal = (item['jumlah'] ?? 0) * (item['harga'] ?? 0);
        buffer.writeln("• ${item['nama'] ?? 'N/A'} - ${item['jumlah'] ?? 0}x @ Rp${item['harga'] ?? 0} = Rp$subtotal");
      }
    }
    
    buffer.writeln("\nTotal: Rp${data['total'] ?? 0}");
    return buffer.toString();
  }

  Future<void> _downloadExcel() async {
    if (_jsonData == null) return;

    setState(() => _isDownloading = true);

    try {
      // Gunakan method baru untuk mendapatkan bytes Excel
      final excelBytes = await _ocrService.getExcelBytes(_jsonData!);
      
      if (excelBytes != null) {
        // Buat nama file dengan timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'transaksi_$timestamp.xlsx';
        
        // Buat blob dan download link untuk web
        final blob = html.Blob([excelBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = fileName;
        
        html.document.body!.children.add(anchor);
        anchor.click();
        
        // Cleanup
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel file "$fileName" berhasil didownload!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        throw Exception('Gagal membuat file Excel');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error download Excel: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Widget _buildExcelPreview() {
    if (_jsonData == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Preview Excel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSimpleTable(),
        ],
      ),
    );
  }

  Widget _buildSimpleTable() {
    if (_jsonData == null) return const SizedBox.shrink();
    
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: [
            _buildTableCell('Item', isHeader: true),
            _buildTableCell('Jumlah', isHeader: true),
            _buildTableCell('Harga', isHeader: true),
            _buildTableCell('Subtotal', isHeader: true),
          ],
        ),
        // Items
        if (_jsonData!['items'] != null)
          ...(_jsonData!['items'] as List).map((item) {
            final subtotal = (item['jumlah'] ?? 0) * (item['harga'] ?? 0);
            return TableRow(
              children: [
                _buildTableCell(item['nama'] ?? 'N/A'),
                _buildTableCell('${item['jumlah'] ?? 0}'),
                _buildTableCell('Rp${item['harga'] ?? 0}'),
                _buildTableCell('Rp$subtotal'),
              ],
            );
          }),
        // Total
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _buildTableCell('TOTAL', isHeader: true),
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell('Rp${_jsonData!['total'] ?? 0}', isHeader: true),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 13 : 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("smartNota (Web Demo)"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickFile,
              icon: _isProcessing 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
              label: Text(_isProcessing ? "Processing..." : "Upload Nota"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Image Preview
            if (_imageBytes != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageBytes!, 
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Excel Preview
            _buildExcelPreview(),
            
            // Download Button
            if (_jsonData != null && !_isProcessing)
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadExcel,
                icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
                label: Text(_isDownloading ? "Downloading..." : "Download Excel"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Result Display
            if (_result != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _result!,
                      style: const TextStyle(
                        fontFamily: "monospace",
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}