import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class PricesListPage extends StatefulWidget {
  const PricesListPage({super.key});

  @override
  State<PricesListPage> createState() => _PricesListPageState();
}

class _PricesListPageState extends State<PricesListPage> {
  void _showQrCode(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: QrImageView(
                data: product['productid'] ?? '',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: product['productid'] ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Product ID copied to clipboard')),
                    );
                  },
                ),
                Text('Product ID: ${product['productid'] ?? 'N/A'}'),
              ],
            ),
            Text("Price: \$${product['price']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchProducts() async {
    final query = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      _allProducts = query.docs.map((doc) {
        final data = doc.data();
        // Ensure productid is always a string
        if (data['productid'] != null) {
          data['productid'] = data['productid'].toString();
        }
        return data;
      }).toList();
      _filteredProducts = List.from(_allProducts);
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.length < 2) {
      setState(() {
        _filteredProducts = List.from(_allProducts);
      });
      return;
    }
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prices List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by product name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(child: Text('No products found.'))
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(product['name'] ?? 'No Name'),
                          subtitle: Text('Price: \$${product['price'] ?? '-'}'),
                          trailing: Text('ID: ${product['productid'] ?? '-'}'),
                          onTap: () => _showQrCode(context, { 
                            'productid': product['productid'] ?? '',
                            'name': product['name'] ?? '',
                            'price': product['price'] ?? ''}),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
