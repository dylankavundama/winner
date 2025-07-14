import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class VentePage extends StatefulWidget {
  const VentePage({Key? key}) : super(key: key);

  @override
  State<VentePage> createState() => _VentePageState();
}

class _VentePageState extends State<VentePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Contrôleurs de formulaire
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  final TextEditingController _garantieController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();

  // Données
  List<SaleProduct> _selectedProducts = [];
  List<Product> _allProducts = [];
  List<Client> _clients = [];
  Client? _selectedClient;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _garantieController.dispose();
    _imeiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchClients(),
        _fetchAllProducts(),
      ]);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur de chargement: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchClients() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.clientsApi));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          setState(() {
            _clients = (data['clients'] as List)
                .map((json) => Client.fromJson(json))
                .toList();
          });
        } else {
          print('API returned success: false. Message: ${data['message']}');
        }
      } else {
        print('HTTP Request Failed with Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching clients: $e');
    }
  }

  Future<void> _fetchAllProducts() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.productsApi));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          setState(() {
            _allProducts = (data['products'] as List)
                .map((json) => Product.fromJson(json))
                .toList();
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Erreur lors du chargement des produits';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur serveur (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion: ${e.toString()}';
      });
    }
  }

  void _nextPage() {
    if (_pageController.page!.toInt() < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_pageController.page!.toInt() > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitSale() async {
    if (_selectedClient == null) {
      _showError('Veuillez sélectionner un client');
      _pageController.jumpToPage(0);
      return;
    }

    if (_selectedProducts.isEmpty) {
      _showError('Veuillez sélectionner au moins un produit');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1; // Default to 1 if not set

      final response = await http
          .post(
            Uri.parse(ApiConstants.addSaleApi),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_id': _selectedClient!.id,
              'user_id': userId,
              'total': _calculateTotal(),
              'imei': _imeiController.text,
              'garanti': _garantieController.text,
              'products': _selectedProducts
                  .map((p) => {
                        'id': p.id,
                        'quantity': p.quantityToSell,
                        'price': p.priceOverride,
                      })
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          
          if (responseData['success'] == true) {
            _showSuccess(responseData['message'] ?? 'Vente enregistrée avec succès');
            Navigator.of(context).pop();
          } else {
            _showError(responseData['message'] ?? 'Erreur lors de la vente');
          }
        } on FormatException catch (e) {
          print('JSON parsing error: $e');
          print('Response body: ${response.body}');
          _showError('Erreur de format de réponse du serveur');
        }
      } else {
        _showError('Erreur serveur (${response.statusCode}): ${response.body}');
      }
    } on TimeoutException {
      _showError('Timeout: Le serveur ne répond pas');
    } catch (e) {
      print('Error in _submitSale: $e');
      _showError('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateTotal() {
    return _selectedProducts.fold(
        0.0,
        (sum, product) =>
            sum + (product.priceOverride * product.quantityToSell));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Vente'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                LinearProgressIndicator(value: (_currentPage + 1) / 4),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildClientInfoPage(),
                      _buildAddressPage(),
                      _buildWarrantyPage(),
                      _buildProductSelectionPage(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildClientInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations Client',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField<Client>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Client existant',
              border: OutlineInputBorder(),
            ),
            items: _clients
                .map((client) => DropdownMenuItem(
                      value: client,
                      child: Text(client.name),
                    ))
                .toList(),
            onChanged: (client) => setState(() => _selectedClient = client),
            hint: const Text('Sélectionnez un client'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _clientNameController,
            decoration: const InputDecoration(
              labelText: 'Nouveau client*',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
          ),
          const SizedBox(height: 16),
          const Text('* Champs obligatoires',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAddressPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adresse Client',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _clientAddressController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
              hintText: 'Optionnel',
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _imeiController,
            decoration: const InputDecoration(
              labelText: 'IMEI',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Garantie',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _garantieController,
            decoration: const InputDecoration(
              labelText: 'Durée de garantie',
              border: OutlineInputBorder(),
              hintText: 'Ex: 6 mois, 1 an...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Produits à Vendre',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<Product>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sélectionner un produit',
              border: OutlineInputBorder(),
            ),
            items: _allProducts
                .map((product) => DropdownMenuItem(
                      value: product,
                      child:
                          Text('${product.name} (Stock: ${product.quantity})'),
                    ))
                .toList(),
            onChanged: (product) {
              if (product != null) {
                setState(() {
                  _selectedProducts.add(SaleProduct(
                    id: product.id,
                    name: product.name,
                    prixVente: product.prixVente,
                    quantity: product.quantity,
                    quantityToSell: 1,
                    priceOverride: product.prixVente,
                  ));
                });
              }
            },
          ),
          const SizedBox(height: 24),
          if (_selectedProducts.isNotEmpty) ...[
            const Text('Produits sélectionnés:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._selectedProducts.map((product) => ListTile(
                  title: Text(product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Prix: ${_currencyFormatter.format(product.priceOverride)}'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _updateProductQuantity(
                                product.id, product.quantityToSell - 1),
                          ),
                          Text('${product.quantityToSell}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _updateProductQuantity(
                                product.id, product.quantityToSell + 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeProduct(product.id),
                  ),
                )),
            const Divider(),
            Text(
              'Total: ${_currencyFormatter.format(_calculateTotal())}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            ElevatedButton(
              onPressed: _previousPage,
              child: const Text('Précédent'),
            ),
          if (_currentPage < 3)
            ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Suivant'),
            ),
          if (_currentPage == 3)
            ElevatedButton(
              onPressed: _isLoading ? null : _submitSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Terminer'),
            ),
        ],
      ),
    );
  }

  void _updateProductQuantity(int productId, int newQuantity) {
    setState(() {
      final product = _selectedProducts.firstWhere((p) => p.id == productId);
      if (newQuantity > 0 && newQuantity <= product.quantity) {
        product.quantityToSell = newQuantity;
      } else if (newQuantity == 0) {
        _selectedProducts.removeWhere((p) => p.id == productId);
      }
    });
  }

  void _removeProduct(int productId) {
    setState(() {
      _selectedProducts.removeWhere((p) => p.id == productId);
    });
  }
}
