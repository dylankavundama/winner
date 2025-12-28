import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/get_out.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/product_model.dart' show Product;


class NewSalePage extends StatefulWidget {
  const NewSalePage({Key? key}) : super(key: key);

  @override
  State<NewSalePage> createState() => _NewSalePageState();
}

class _NewSalePageState extends State<NewSalePage> {
  // Available and filtered products
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  // Sale cart
  Map<int, Map<String, dynamic>> _cart = {};

  // Client data
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();

  // User data (simplified for a non-session environment)
  // Hardcoded ID, not recommended for production.
  final int _currentUserId = 1;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _fetchProducts();
    setState(() => _isLoading = false);
  }

  // --- API Data Retrieval ---
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.productsApi),
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> productsData = data['products'];
        _allProducts =
            productsData.map((json) => Product.fromJson(json)).toList();
        _filteredProducts = _allProducts.where((p) => p.quantity > 0).toList();
      } else {
        final loc = AppLocalizations.of(context);
        _errorMessage =
            data['message'] ?? loc.stockAddOutLoadError;
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      _errorMessage = loc.stockAddOutConnectionError(ErrorUtils.getUserFriendlyError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Client API Logic ---
  Future<Client?> _findClientByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.clientsApi}?name=$name'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['client'] != null) {
          return Client.fromJson(data['client']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int?> _addNewClient(String name) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.clientsApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['client_id'] != null) {
          return data['client_id'] as int;
        } else if (data['success'] == false && data['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message']),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
      } else {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.stockAddOutServerError(response.statusCode)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.stockAddOutClientConnectionError(ErrorUtils.getUserFriendlyError(e))),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  // --- Cart Logic ---
  void _addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      if (_cart[product.id]!['quantity'] < product.quantity) {
        _cart[product.id]!['quantity'] += 1;
      } else {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.stockAddOutInsufficientStock(product.name)),
            backgroundColor: Colors.orange));
      }
    } else {
      _cart[product.id] = {
        'product': product,
        'quantity': 1,
      };
    }
    setState(() {});
  }

  void _removeFromCart(int productId) {
    if (_cart.containsKey(productId)) {
      if (_cart[productId]!['quantity'] > 1) {
        _cart[productId]!['quantity'] -= 1;
      } else {
        _cart.remove(productId);
      }
    }
    setState(() {});
  }

  double get _cartTotal {
    double total = 0;
    _cart.forEach((key, value) {
      total += value['product'].prixVente * value['quantity'];
    });
    return total;
  }

  // --- Sale Submission to API ---
  Future<void> _recordSale() async {
    final loc = AppLocalizations.of(context);
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.stockAddOutEmptyCart), backgroundColor: Colors.red));
      return;
    }

    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.stockAddOutEnterClient),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    // Check if client exists
    final existingClient = await _findClientByName(clientName);

    int? clientId = existingClient?.id;

    // If client does not exist, ask user to add them
    if (existingClient == null) {
      final shouldAdd = await _showAddClientDialog(clientName);
      if (shouldAdd == true) {
        clientId = await _addNewClient(clientName);
        if (clientId == null) {
          setState(() => _isLoading = false);
          final loc = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(loc.stockAddOutAddClientError),
              backgroundColor: Colors.red));
          return;
        }
      } else {
        setState(() => _isLoading = false);
        return; // User cancelled
      }
    }

    final saleItems = _cart.entries
        .map((entry) => {
              'product_id': entry.key,
              'quantity': entry.value['quantity'],
            })
        .toList();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.recordStockOutApi),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': _currentUserId,
          'client_id': clientId,
          'items': saleItems,
        }),
      );

      final data = json.decode(response.body);

      final loc = AppLocalizations.of(context);
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.stockAddOutSuccess),
            backgroundColor: Colors.green));
        // Reset the page
        _cart.clear();
        _clientNameController.clear();
        _productSearchController.clear();
        await _fetchProducts(); // Re-fetch products to show updated stock

        // Navigate to the StockOutHistoryPage
        // Assurez-vous d'importer le fichier de cette page en haut du document.
        // Par exemple: import 'package:gestion_app_mobile/stock_out_history_page.dart';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StockOutHistoryPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.stockAddOutError(data['message'] ?? '')),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.stockAddOutConnectionErrorSale(ErrorUtils.getUserFriendlyError(e))),
          backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showAddClientDialog(String clientName) {
    final loc = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.stockAddOutClientNotFound),
        content: Text(loc.stockAddOutClientNotFoundMessage(clientName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.stockAddOutCancel, style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(loc.stockAddOutAdd, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI Widgets ---
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.stockAddOutTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Client search section
                      TextField(
                        controller: _clientNameController,
                        decoration: InputDecoration(
                          labelText: loc.stockAddOutClientNameLabel,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Product search bar
                      TextField(
                        controller: _productSearchController,
                        onChanged: (value) {
                          setState(() {
                            _filteredProducts = _allProducts
                                .where((p) =>
                                    p.quantity > 0 &&
                                    p.name
                                        .toLowerCase()
                                        .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: loc.stockAddOutSearchProduct,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // List of available products to add
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? Center(
                                child: Text(loc.stockAddOutNoProducts))
                            : ListView.builder(
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return ListTile(
                                    leading: const Icon(Icons.shopping_bag),
                                    title: Text(product.name),
                                    subtitle: Text(loc.stockAddOutProductSubtitle(
                                        product.prixVente.toStringAsFixed(2),
                                        product.quantity.toString())),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_shopping_cart,
                                          color: Colors.green),
                                      onPressed: () => _addToCart(product),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Cart section
                      _buildCartSummary(),
                      const SizedBox(height: 16),
                      // Validation button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _recordSale,
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: Text(loc.stockAddOutValidateSale,
                              style:
                                  const TextStyle(color: Colors.white, fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Cart summary widget
  Widget _buildCartSummary() {
    final loc = AppLocalizations.of(context);
    if (_cart.isEmpty) {
      return const SizedBox.shrink(); // Hide if cart is empty
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.stockAddOutCart,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        ..._cart.entries.map((entry) {
          final product = entry.value['product'] as Product;
          final quantity = entry.value['quantity'] as int;
          return ListTile(
            title: Text(product.name),
            subtitle: Text(loc.stockAddOutQuantityLabel(
                quantity.toString(), product.prixVente.toStringAsFixed(2))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeFromCart(product.id),
                ),
                Text('$quantity', style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _addToCart(product),
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            loc.stockAddOutTotal(_cartTotal.toStringAsFixed(2)),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
      ],
    );
  }
}
