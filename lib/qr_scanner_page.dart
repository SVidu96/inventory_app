import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  @override
  void initState() {
    super.initState();
 
  }
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR/Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          if (scanned) return;
          scanned = true;
          try {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                Navigator.of(context).pop(code);
              }
            }
          } catch (e) {
            Navigator.of(context).pop();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error reading barcode: $e')),
              );
            }
          }
        },
      ),
    );
  }
}
