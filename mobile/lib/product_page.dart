import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/add.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/main.dart';
import 'package:gestion_app_mobile/app_localizations.dart';

// --- Product Model ---
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final double prixVente; // Selling price
  final int quantity;
  final String createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.prixVente,
    required this.quantity,
    required this.createdAt,
  });

  // Factory constructor to create a Product from a JSON map
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description:
          json['description'] ?? '', // Handle null description gracefully
      price: _parseDouble(json['price']),
      prixVente: _parseDouble(json['prix_vente']),
      quantity: json['quantity'],
      createdAt: json['created_at'],
    );
  }

  // Helper function to safely parse dynamic values to double, handling comma as decimal separator
  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      // Replace comma with dot for consistent parsing across locales
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0; // Default value if the type is neither num nor String
  }
}

// --- Product Page Widget ---
class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Product> products = [];
  bool isLoading = true;
  String? errorMessage;
  String? _phpSessionCookie;
  String searchQuery = ''; // For product search functionality
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _loadSessionAndFetchProducts();
    _loadUserRole();
  }

  // Loads PHP session cookie and then fetches products
  Future<void> _loadSessionAndFetchProducts() async {
    final prefs = await SharedPreferences.getInstance();
    _phpSessionCookie = prefs.getString('phpSessionCookie');

    if (_phpSessionCookie == null || _phpSessionCookie!.isEmpty) {
      final loc = AppLocalizations.of(context);
      setState(() {
        errorMessage = loc.productSessionNotFound;
        isLoading = false;
      });
      _navigateToLogin(); // Redirect to login if no session
      return;
    }

    await _fetchProducts();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('user_role') ?? '';
    });
  }

  // Fetches product data from the API
  Future<void> _fetchProducts() async {
  setState(() {
    isLoading = true; // Show loading indicator
    errorMessage = null; // Clear any previous error messages
  });

  try {
    final response = await http.get(
      Uri.parse(ApiConstants.productsApi), // Your API endpoint to get all products
      headers: {
        'Cookie': _phpSessionCookie!, // Send the session cookie for authentication
      },
    );

    // For debugging:
    print('Products response status: ${response.statusCode}');
    print('Products response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final List<dynamic> productsData = data['products'];
        setState(() {
          products =
              productsData.map((json) => Product.fromJson(json)).toList();

          // Tri en ordre décroissant par id
          products.sort((a, b) => b.id.compareTo(a.id));

          // Si tu veux trier par prix décroissant, remplace par :
          // products.sort((a, b) => b.price.compareTo(a.price));

          isLoading = false;
        });
      } else {
        final loc = AppLocalizations.of(context);
        setState(() {
          errorMessage =
              data['message'] ?? loc.productLoadError;
          isLoading = false;
        });
      }
    } else if (response.statusCode == 401) {
      // Unauthorized - session likely expired
      final loc = AppLocalizations.of(context);
      setState(() {
        errorMessage = loc.productUnauthorized;
        isLoading = false;
      });
      _navigateToLogin(); // Redirect to login
    } else {
      final loc = AppLocalizations.of(context);
      setState(() {
        errorMessage = loc.productHttpError(response.statusCode);
        isLoading = false;
      });
    }
  } catch (e) {
    // Catch network errors or other exceptions
    final loc = AppLocalizations.of(context);
    setState(() {
      errorMessage = loc.productConnectionError(e.toString());
      isLoading = false;
    });
    print('Error fetching products: $e'); // For debugging
  }
}


  // Navigates to the login page and clears session
  Future<void> _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phpSessionCookie'); // Clear stored session
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false, // Remove all previous routes
    );
  }

  // Filters products based on search query
  List<Product> get filteredProducts {
    if (searchQuery.isEmpty) {
      return products;
    }
    return products
        .where((product) =>
            product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();
  }

  // Determines stock color based on quantity
  Color _getStockColor(int quantity) {
    if (quantity <= 0) return Colors.red;
    if (quantity <= 10) return Colors.orange;
    return Colors.green;
  }

  // Determines stock status text based on quantity
  String _getStockStatus(int quantity, BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (quantity <= 0) return loc.productStockOut;
    if (quantity <= 10) return loc.productStockLow;
    return loc.productStockAvailable;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: userRole != 'vendeur'
          ? FloatingActionButton(
              onPressed: () async {
                // Naviguer vers la page d'ajout de produit
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddProductPage()),
                );
                // Si un produit a été ajouté avec succès, actualiser la liste
                if (result == true) {
                  _fetchProducts();
                }
              },
              backgroundColor: Colors.green,
              tooltip: loc.productAddTooltip,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // Masque le bouton si le rôle est 'vendeur'

      appBar: AppBar(
        title: Text(
          loc.productTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[800],
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.productRefreshTooltip,
            onPressed: _fetchProducts, // Call fetch function to refresh
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchProducts, // Retry button
                          child: Text(loc.productRetryButton),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: loc.productSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    // Quick Statistics Cards
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              loc.productTotalProducts,
                              products.length.toString(),
                              Icons.inventory_2_outlined,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              loc.productInStock,
                              products
                                  .where((p) => p.quantity > 0)
                                  .length
                                  .toString(),
                              Icons.check_circle_outline,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              loc.productOutOfStock,
                              products
                                  .where((p) => p.quantity <= 0)
                                  .length
                                  .toString(),
                              Icons.error_outline,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Product List
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isEmpty
                                        ? loc.productNoProducts
                                        : loc.productNoSearchResults,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return _buildProductCard(product);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  // Widget for displaying a single statistic card
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget for displaying a single product card
  Widget _buildProductCard(Product product) {
    final loc = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Stock status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStockColor(product.quantity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStockStatus(product.quantity, context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Edit button
                if (userRole != 'vendeur')
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    tooltip: loc.productEditTooltip,
                    onPressed: () {
                      _showEditProductDialog(product);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Prices and Quantity details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.productPurchasePrice,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${product.price.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.productSalePrice,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${product.prixVente.toStringAsFixed(2)} \$',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.productQuantityLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: _getStockColor(product.quantity),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.quantity}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStockColor(product.quantity),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              loc.productAddedOn(product.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shows a dialog to edit product details
  void _showEditProductDialog(Product product) {
    final priceController =
        TextEditingController(text: product.price.toString());
    final prixVenteController =
        TextEditingController(text: product.prixVente.toString());
    final quantityController =
        TextEditingController(text: product.quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.productEditDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.productEditName(product.name),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (product.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(loc.productEditDescription(product.description),
                        style: const TextStyle(color: Colors.grey)),
                  ),
                const SizedBox(height: 15),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: loc.productEditPurchasePrice),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: prixVenteController,
                  decoration: InputDecoration(labelText: loc.productEditSalePrice),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: loc.productEditQuantity),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.productEditCancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedProduct = Product(
                  id: product.id,
                  name: product.name,
                  description: product.description,
                  price: double.tryParse(priceController.text) ?? product.price,
                  prixVente: double.tryParse(prixVenteController.text) ??
                      product.prixVente,
                  quantity:
                      int.tryParse(quantityController.text) ?? product.quantity,
                  createdAt: product.createdAt,
                );
                final result =
                    await _updateProductOnServerWithError(updatedProduct);
                if (result['success'] == true) {
                  setState(() {
                    final index =
                        products.indexWhere((p) => p.id == product.id);
                    if (index != -1) {
                      products[index] = updatedProduct;
                    }
                  });
                  Navigator.of(context).pop();
                  final loc = AppLocalizations.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(loc.productUpdateSuccess),
                        backgroundColor: Colors.green),
                  );
                } else {
                  Navigator.of(context).pop();
                  final loc = AppLocalizations.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(loc.productUpdateError(result['message'] ?? '')),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: Text(loc.productEditSave),
            ),
          ],
        );
      },
    );
  }

  /// Sends product update request to the server and returns a map indicating success and message.
  /// Includes more detailed error handling for the response.
  Future<Map<String, dynamic>> _updateProductOnServerWithError(
      Product product) async {
    try {
      final response = await http.post(
        // Ensure ApiConstants.baseUrl is correctly defined, e.g., "http://yourserver.com/api"
        Uri.parse('${ApiConstants.baseUrl}/update_product.php'),
        headers: {
          'Content-Type': 'application/json',
          if (_phpSessionCookie != null)
            'Cookie': _phpSessionCookie!, // Send session cookie
        },
        body: json.encode({
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'prix_vente': product.prixVente,
          'quantity': product.quantity,
        }),
      );

      // For debugging:
      print('Update Product API Status: ${response.statusCode}');
      print('Update Product API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': data['success'] == true, 'message': data['message']};
      } else {
        final loc = AppLocalizations.of(context);
        String errorMessage = loc.productUpdateHttpError(response.statusCode);
        // Try to parse a more specific error message from the response body
        try {
          final errorData = json.decode(response.body);
          if (errorData != null &&
              errorData is Map &&
              errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // If body is not valid JSON or doesn't contain 'message', use generic HTTP error
          print('Failed to parse error body: $e');
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      // Catch network-related exceptions (e.g., no internet, host unreachable)
      print('Network or other exception during product update: $e');
      final loc = AppLocalizations.of(context);
      return {
        'success': false,
        'message': loc.productUpdateConnectionError(e.toString())
      };
    }
  }
}
