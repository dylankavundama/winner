import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/product_model.dart' show Product;


class NewSalePage extends StatefulWidget {
  const NewSalePage({Key? key}) : super(key: key);

  @override
  State<NewSalePage> createState() => _NewSalePageState();
}

class _NewSalePageState extends State<NewSalePage> {
  // Liste des produits disponibles et filtrés
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  // Panier de vente
  Map<int, Map<String, dynamic>> _cart = {};

  // Données du client
  final TextEditingController _clientNameController = TextEditingController();

  // Données de l'utilisateur (simplifié pour fonctionner sans session)
  // L'ID est codé en dur, ce qui n'est pas recommandé pour la production.
  final int _currentUserId = 1; 

  bool _isLoading = true;
  String? _errorMessage;
  String _productSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // La vérification de session est retirée.
    // L'utilisateur est considéré comme valide par défaut avec l'ID statique.
    await _fetchProducts();
    setState(() => _isLoading = false);
  }

  // --- Récupération des données depuis l'API ---
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.productsApi),
        // L'en-tête 'Cookie' a été retiré
      );
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> productsData = data['products'];
        _allProducts = productsData.map((json) => Product.fromJson(json)).toList();
        _filteredProducts = _allProducts.where((p) => p.quantity > 0).toList();
      } else {
        _errorMessage = data['message'] ?? 'Erreur lors du chargement des produits.';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion : $e';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Logique du panier ---
  void _addToCart(Product product) {
    if (_cart.containsKey(product.id)) {
      _cart[product.id]!['quantity'] += 1;
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

  // --- Soumission de la vente à l'API ---
  Future<void> _recordSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le panier est vide.'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final saleItems = _cart.entries.map((entry) => {
      'product_id': entry.key,
      'quantity': entry.value['quantity'],
    }).toList();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.recordStockOutApi), 
        headers: {
          'Content-Type': 'application/json',
          // L'en-tête 'Cookie' a été retiré
        },
        body: json.encode({
          'user_id': _currentUserId,
          'client_name': _clientNameController.text.trim().isEmpty ? null : _clientNameController.text.trim(),
          'items': saleItems,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vente enregistrée avec succès !'), backgroundColor: Colors.green));
        // Réinitialiser la page ou revenir en arrière
        _cart.clear();
        _clientNameController.clear();
        _productSearchQuery = '';
        await _fetchProducts(); // Re-fetch products to show updated stock
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${data['message']}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de connexion : $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Widgets de l'UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Vente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Section de recherche de client
                      TextField(
                        controller: _clientNameController,
                        decoration: InputDecoration(
                          labelText: 'Nom du client (facultatif)',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Barre de recherche de produits
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _productSearchQuery = value;
                            _filteredProducts = _allProducts
                                .where((p) =>
                                    p.quantity > 0 &&
                                    p.name.toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Liste des produits disponibles pour l'ajout
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? const Center(child: Text('Aucun produit disponible.'))
                            : ListView.builder(
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return ListTile(
                                    leading: const Icon(Icons.shopping_bag),
                                    title: Text(product.name),
                                    subtitle: Text('${product.prixVente.toStringAsFixed(2)} \$ - Stock: ${product.quantity}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                                      onPressed: () => _addToCart(product),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Section du panier
                      _buildCartSummary(),
                      const SizedBox(height: 16),
                      // Bouton de validation
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _recordSale,
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Valider la vente', style: TextStyle(color: Colors.white, fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Widget de résumé du panier
  Widget _buildCartSummary() {
    if (_cart.isEmpty) {
      return const SizedBox.shrink(); // Ne rien afficher si le panier est vide
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Panier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Divider(),
        ..._cart.entries.map((entry) {
          final product = entry.value['product'] as Product;
          final quantity = entry.value['quantity'] as int;
          return ListTile(
            title: Text(product.name),
            subtitle: Text('Quantité: $quantity x ${product.prixVente.toStringAsFixed(2)} \$'),
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
            'Total: ${_cartTotal.toStringAsFixed(2)} \$',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
      ],
    );
  }
}
