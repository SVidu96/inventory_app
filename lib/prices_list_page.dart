import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'add_product_page.dart';

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
                    Clipboard.setData(
                      ClipboardData(text: product['productid'] ?? ''),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Product ID copied to clipboard')),
                    );
                  },
                ),
                Text('Product ID: ${product['productid'] ?? 'N/A'}'),
              ],
            ),
            Text("Price: \$${product['price']}"),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.edit),
              label: Text('Edit Product'),
              onPressed: () {
                Navigator.pop(context); // Close dialog first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductPage(
                      initialProductId: product['productid'],
                      key: UniqueKey(), // ensure new instance
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.delete),
              label: Text(
                'Delete Product',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Product'),
                    content: Text(
                      'Are you sure you want to delete this product?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  // Find and delete product from Firestore
                  try {
                    final query = await FirebaseFirestore.instance
                        .collection('products')
                        .where('productid', isEqualTo: product['productid'])
                        .limit(1)
                        .get();
                    if (query.docs.isNotEmpty) {
                      await query.docs.first.reference.delete();
                      if (mounted) {
                        Navigator.pop(context); // Close QR dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Product deleted successfully.'),
                          ),
                        );
                        _fetchProducts(); // Refresh list
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Product not found in database.'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete product: $e')),
                      );
                    }
                  }
                }
              },
            ),
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
      appBar: AppBar(
        title: const Text('Prices List'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchProducts,
          ),
        ],
      ),
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
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(product['name'] ?? 'No Name'),
                          subtitle: Text('Price: \$${product['price'] ?? '-'}'),
                          trailing: Text('ID: ${product['productid'] ?? '-'}'),
                          onTap: () => _showQrCode(context, {
                            'productid': product['productid'] ?? '',
                            'name': product['name'] ?? '',
                            'price': product['price'] ?? '',
                          }),
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
