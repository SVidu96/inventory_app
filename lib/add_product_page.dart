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

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  String? _errorMessage;

  Future<void> _searchProduct() async {
    final productId = _barcodeController.text.trim();
    setState(() {
      _errorMessage = null;
    });
    if (productId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter or scan a product ID.';
      });
      return;
    }
    try {
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('productid', isEqualTo: productId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Product not found.';
        });
      } else {
        final data = query.docs.first.data();
        setState(() {
          _nameController.text = data['name']?.toString() ?? '';
          _priceController.text = data['price']?.toString() ?? '';
          _selectedType = data['producttype'] is int ? data['producttype'] : int.tryParse(data['producttype'].toString()) ?? 0;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search product: ${e.toString()}';
      });
    }
  }
  Future<void> _addOrUpdateProduct() async {
    final productId = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final type = _selectedType;

    if (productId.isEmpty || name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields with valid values.')),
      );
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('productid', isEqualTo: productId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // Update existing product
        await query.docs.first.reference.update({
          'name': name,
          'price': price,
          'producttype': type,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully!')),
        );
      } else {
        // Add new product
        await FirebaseFirestore.instance.collection('products').add({
          'productid': productId, // store as string
          'name': name,
          'price': price,
          'producttype': type,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add/update product: $e')),
      );
    }
  }
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  int _selectedType = 0;

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
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _searchProduct,
                    child: Icon(Icons.search),
                  ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              Text('Product Details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Product Type',
                  border: OutlineInputBorder(),
                ),
                items: productTypeMap.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? 0;
                  });
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _addOrUpdateProduct,
                  child: const Text('Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
