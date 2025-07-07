import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
// If you want to use a custom mirror for the barcode library, set it here:
// final String scriptUrl = 'https://cdn.jsdelivr.net/npm/@undecaf/barcode-detector-polyfill@latest/dist/barcode-detector-polyfill.umd.js';
final String? scriptUrl = null; // Set to your mirror URL if needed

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb && scriptUrl != null) {
      MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(scriptUrl!);
    }
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
