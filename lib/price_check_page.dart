import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'qr_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Global product type map
const Map<int, String> productTypeMap = {
  1: 'Beer',
  2: 'Vodka',
  3: 'Tequila',
  4: 'Whiskey',
  5: 'Rum',
  6: 'Gin',
  7: 'Wine',
  8: 'Mixtures',
  9: 'Brandy',
  0: 'Other',
};

class PriceCheckPage extends StatefulWidget {
  const PriceCheckPage({super.key});

  @override
  State<PriceCheckPage> createState() => _PriceCheckPageState();
}

class _PriceCheckPageState extends State<PriceCheckPage> {
  final TextEditingController _barcodeController = TextEditingController();

  Map<String, dynamic>? _foundProduct; // Store found product
  String? _errorMessage; // Store error message

  Future<void> _searchProduct() async {
    final productId = int.tryParse(_barcodeController.text.trim()) ?? -1; // Default to -1 if parsing fails
    setState(() {
      _foundProduct = null;
      _errorMessage = null;
    });
    if (productId == -1) {
      setState(() {
        _errorMessage = 'Please enter or scan a product ID.';
      });
      return;
    }
    try {
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('productid', isEqualTo: productId) // Search as string
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Product not found.';
        });
      } else {
        setState(() {
          _foundProduct = query.docs.first.data();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search product: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Camera permission denied.')),
            );
          }
          return;
        }
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QrScannerPage(),
        ),
      );
      if (result != null && mounted) {
        setState(() {
          _barcodeController.text = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Price Check'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter or scan barcode',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _scanBarcode,
                  child: Icon(Icons.qr_code_scanner),
                ),
                ElevatedButton(
                  onPressed: _searchProduct,
                  child: Icon(Icons.search),
                ),
              ],
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          if (_foundProduct != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: ListTile(
                  title: Text(_foundProduct!['name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
          children: _foundProduct!.entries.map((entry) {
            if (entry.key == 'producttype' && entry.value is int) {
              return Text('${entry.key}: ${productTypeMap[entry.value] ?? entry.value}');
            }
            return Text('${entry.key}: ${entry.value}');
          }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}