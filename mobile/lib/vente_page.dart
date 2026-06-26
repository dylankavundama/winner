import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';
import 'package:gestion_app_mobile/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:gestion_app_mobile/facture_page.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

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
  final TextEditingController _clientSearchController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientAddressController =
      TextEditingController();
  final TextEditingController _garantieController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();

  // Données
  List<SaleProduct> _selectedProducts = [];
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Client> _clients = [];
  Client? _selectedClient;
  bool _showProductDropdown = false;

  // Debouncer pour la recherche de produits
  Timer? _productSearchDebouncer;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _productSearchDebouncer?.cancel();
    _clientSearchController.dispose();
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _garantieController.dispose();
    _imeiController.dispose();
    _productSearchController.dispose();
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
      final loc = AppLocalizations.of(context);
      setState(() => _errorMessage =
          loc.venteLoadError(ErrorUtils.getUserFriendlyError(e)));
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
          final loc = AppLocalizations.of(context);
          setState(() {
            _errorMessage = data['message'] ?? loc.venteErrorLoadingProducts;
          });
        }
      } else {
        final loc = AppLocalizations.of(context);
        setState(() {
          _errorMessage = loc.venteErrorServer(response.statusCode);
        });
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      setState(() {
        _errorMessage =
            loc.venteErrorConnection(ErrorUtils.getUserFriendlyError(e));
      });
    }
  }

  // Filtrer les clients pour la recherche
  List<Client> _filterClients(String query) {
    if (query.isEmpty) return _clients;
    return _clients.where((client) {
      return client.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Méthode pour filtrer les produits avec debounce
  void _filterProducts(String query) {
    // Annuler le timer précédent s'il existe
    _productSearchDebouncer?.cancel();

    // Si la requête est vide, masquer immédiatement
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = [];
        _showProductDropdown = false;
      });
      return;
    }

    // Créer un nouveau timer pour debounce (300ms)
    _productSearchDebouncer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final queryLower = query.toLowerCase().trim();

      // Filtrer les produits
      final filtered = _allProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(queryLower);
        final idMatch = product.id.toString().contains(query);
        return nameMatch || idMatch;
      }).toList();

      // Limiter à 20 résultats pour éviter la surcharge
      final limitedResults = filtered.take(20).toList();

      setState(() {
        _filteredProducts = limitedResults;
        _showProductDropdown = limitedResults.isNotEmpty;
      });
    });
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
          _showError(data['message']);
          return null;
        }
      } else {
        final loc = AppLocalizations.of(context);
        _showError(loc.venteErrorServerClient(response.statusCode));
      }
      return null;
    } catch (e) {
      final loc = AppLocalizations.of(context);
      _showError(
          loc.venteErrorConnectionClient(ErrorUtils.getUserFriendlyError(e)));
      return null;
    }
  }

  Future<void> _handleNextClientStep() async {
    final newClientName = _clientNameController.text.trim();

    // Priorité: nouveau client si saisi
    if (newClientName.isNotEmpty) {
      setState(() => _isLoading = true);
      final clientId = await _addNewClient(newClientName);
      setState(() => _isLoading = false);

      if (clientId != null) {
        final newClient = Client(id: clientId, name: newClientName);
        setState(() {
          _clients.add(newClient);
          _selectedClient = newClient;
        });
        _clientNameController.clear();
        _clientSearchController.clear();
        _nextPage();
      } else {
        final loc = AppLocalizations.of(context);
        _showError(loc.venteErrorCreateClient);
      }
    }
    // Sinon, vérifier qu'un client existant est sélectionné
    else if (_selectedClient != null) {
      _nextPage();
    }
    // Aucun client sélectionné
    else {
      final loc = AppLocalizations.of(context);
      _showError(loc.venteErrorSelectClient);
    }
  }

  // Méthode améliorée pour ajouter un produit (avec validation)
  void _addProduct(Product product) {
    final loc = AppLocalizations.of(context);
    // Vérifier si le produit est déjà ajouté
    final isAlreadyAdded = _selectedProducts.any((p) => p.id == product.id);
    if (isAlreadyAdded) {
      _showError(loc.venteErrorProductAlreadyAdded);
      return;
    }

    // Vérifier le stock
    if (product.quantity <= 0) {
      _showError(loc.venteErrorInsufficientStock(product.name));
      return;
    }

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

    _showSuccess(loc.venteProductAddedToSale(product.name));
  }

  Future<void> _submitSale() async {
    final loc = AppLocalizations.of(context);
    if (_selectedClient == null) {
      _showError(loc.venteErrorSelectClientSale);
      _pageController.jumpToPage(0);
      return;
    }

    if (_selectedProducts.isEmpty) {
      _showError(loc.venteErrorSelectProducts);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

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

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);

          final loc = AppLocalizations.of(context);
          if (responseData['success'] == true) {
            try {
              final saleId =
                  int.tryParse(responseData['sale_id'].toString()) ?? 0;

              // Demander le statut de la facture AVANT tout message de succès
              final String? status = await _askPaymentStatus();

              // Si annulé, on met 'impayée' par défaut pour garantir la génération de facture
              final finalStatus = status ?? 'impayée';

              // Générer la facture avec le statut choisi
              final invoiceId = await _generateInvoice(saleId, finalStatus);

              if (invoiceId != null) {
                _showSuccess(responseData['message'] ?? loc.venteSaleRecorded);
                await _showSuccessDialog(invoiceId);
              } else {
                _showError(loc.venteErrorGenerateInvoice);
              }
            } catch (e) {
              print('Erreur lors de la création de la facture: $e');
              _showError(loc.venteErrorGenerateInvoice);
            }
          } else {
            _showError(responseData['message'] ?? loc.venteErrorSale);
          }
        } on FormatException catch (e) {
          print('JSON parsing error: $e');
          final loc = AppLocalizations.of(context);
          _showError(loc.venteErrorServerResponse);
        }
      } else {
        final loc = AppLocalizations.of(context);
        _showError(loc.venteErrorServer(response.statusCode));
      }
    } on TimeoutException {
      final loc = AppLocalizations.of(context);
      _showError(loc.venteErrorTimeout);
    } catch (e) {
      print('Error in _submitSale: $e');
      final loc = AppLocalizations.of(context);
      _showError(loc.venteErrorConnection(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog(int invoiceId) async {
    final loc = AppLocalizations.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(loc.venteSaleRecordedTitle)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person, loc.venteInfoClient,
                    _selectedClient?.name ?? ''),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.attach_money, loc.venteInfoTotal,
                    '${_calculateTotal().toStringAsFixed(2)} \$'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, loc.venteInfoDate,
                    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
                if (_imeiController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone_android, loc.venteInfoImei,
                      _imeiController.text),
                ],
                if (_garantieController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.verified, loc.venteInfoWarranty,
                      _garantieController.text),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Retour à la page précédente
              },
              child: Text(loc.venteClose),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: Text(loc.ventePrintInvoice),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FacturePage(invoiceId: invoiceId),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  double _calculateTotal() {
    return _selectedProducts.fold(
        0.0,
        (sum, product) =>
            sum + (product.priceOverride * product.quantityToSell));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      // Empêche le redimensionnement automatique du corps quand le clavier apparaît,
      // ce qui évite les erreurs d'overflow lors de la saisie du nom des produits.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(loc.venteTitle),
        backgroundColor: Colors.blueGrey[800],
        elevation: 2,
      ),
      body: _isLoading && _clients.isEmpty && _allProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _clients.isEmpty && _allProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        child: Text(loc.venteRetry),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildProgressIndicator(),
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

  Widget _buildProgressIndicator() {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey[800]!),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(0, loc.venteStepClient, _currentPage >= 0),
              _buildStepIndicator(1, loc.venteStepAddress, _currentPage >= 1),
              _buildStepIndicator(2, loc.venteStepWarranty, _currentPage >= 2),
              _buildStepIndicator(3, loc.venteStepProducts, _currentPage >= 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.blueGrey[800] : Colors.grey[300],
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.blueGrey[800] : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoPage() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blueGrey[800], size: 28),
              const SizedBox(width: 8),
              Text(
                loc.venteClientInfoTitle,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recherche de client avec TypeAhead
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.venteSearchExistingClient,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TypeAheadField<Client>(
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: loc.venteSearchClientLabel,
                          hintText: loc.venteSearchClientHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _selectedClient != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _selectedClient = null;
                                      _clientSearchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      );
                    },
                    controller: _clientSearchController,
                    suggestionsCallback: (pattern) async {
                      return _filterClients(pattern);
                    },
                    itemBuilder: (context, Client client) {
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(client.name),
                        subtitle: Text('ID: ${client.id}'),
                      );
                    },
                    onSelected: (Client client) {
                      setState(() {
                        _selectedClient = client;
                        _clientSearchController.text = client.name;
                      });
                      // Passer automatiquement à l'étape suivante après sélection du client
                      _nextPage();
                    },
                    emptyBuilder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _clients.isEmpty
                              ? loc.venteNoClientsRegistered
                              : loc.venteNoClientFound,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    },
                  ),
                  if (_selectedClient != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.venteClientSelected(_selectedClient!.name),
                              style: TextStyle(
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Séparateur
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  loc.venteOr,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          const SizedBox(height: 24),

          // Créer un nouveau client
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_add, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        loc.venteCreateNewClient,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientNameController,
                    decoration: InputDecoration(
                      labelText: loc.venteNewClientNameLabel,
                      hintText: loc.venteNewClientNameHint,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      // Désélectionner le client existant si on tape un nouveau nom
                      if (value.isNotEmpty && _selectedClient != null) {
                        setState(() {
                          _selectedClient = null;
                          _clientSearchController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.venteRequiredFields,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          if (_clients.isEmpty) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.venteNoClientsInfo,
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressPage() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blueGrey[800], size: 28),
              const SizedBox(width: 8),
              Text(
                loc.venteAddressTitle,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _clientAddressController,
                    decoration: InputDecoration(
                      labelText: loc.venteAddressLabel,
                      hintText: loc.venteAddressHint,
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      // Passer le focus au champ IMEI
                      FocusScope.of(context).nextFocus();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imeiController,
                    decoration: InputDecoration(
                      labelText: loc.venteImeiLabel,
                      hintText: loc.venteImeiHint,
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      // Passer automatiquement à l'étape suivante après saisie de l'IMEI
                      _nextPage();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantyPage() {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: Colors.blueGrey[800], size: 28),
              const SizedBox(width: 8),
              Text(
                loc.venteWarrantyTitle,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _garantieController,
                    decoration: InputDecoration(
                      labelText: loc.venteWarrantyLabel,
                      hintText: loc.venteWarrantyHint,
                      prefixIcon: const Icon(Icons.verified_user),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.venteWarrantyOptional,
                            style: TextStyle(
                                color: Colors.blue[900], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget de recherche de produits amélioré
  Widget _buildProductSearchWidget() {
    final loc = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _productSearchController,
              decoration: InputDecoration(
                labelText: loc.venteSearchProductLabel,
                hintText: loc.venteSearchProductHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _productSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _productSearchController.clear();
                            _filterProducts('');
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterProducts,
            ),
            if (_showProductDropdown) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.3, // 30% de la hauteur d'écran
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: _filteredProducts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              loc.venteNoProductFound,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final isAlreadyAdded = _selectedProducts
                                .any((p) => p.id == product.id);

                            return InkWell(
                              onTap: !isAlreadyAdded && product.quantity > 0
                                  ? () {
                                      _addProduct(product);
                                      _productSearchController.clear();
                                      _filterProducts('');
                                    }
                                  : null,
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isAlreadyAdded
                                      ? Colors.green[100]
                                      : product.quantity > 0
                                          ? Colors.blue[100]
                                          : Colors.red[100],
                                  child: Icon(
                                    isAlreadyAdded
                                        ? Icons.check
                                        : product.quantity > 0
                                            ? Icons.inventory_2
                                            : Icons.block,
                                    color: isAlreadyAdded
                                        ? Colors.green[700]
                                        : product.quantity > 0
                                            ? Colors.blue[700]
                                            : Colors.red[700],
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    decoration: isAlreadyAdded
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      loc.venteStockLabel(
                                          product.quantity.toString()),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      loc.ventePriceLabel(
                                          product.prixVente.toStringAsFixed(2)),
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isAlreadyAdded
                                    ? Chip(
                                        label: Text(loc.venteProductAdded,
                                            style:
                                                const TextStyle(fontSize: 10)),
                                        backgroundColor: Colors.green,
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                      )
                                    : product.quantity > 0
                                        ? IconButton(
                                            icon: const Icon(Icons.add_circle,
                                                color: Colors.blue, size: 24),
                                            onPressed: () {
                                              _addProduct(product);
                                              _productSearchController.clear();
                                              _filterProducts('');
                                            },
                                          )
                                        : Chip(
                                            label: Text(
                                                loc.venteProductOutOfStock,
                                                style: const TextStyle(
                                                    fontSize: 10)),
                                            backgroundColor: Colors.red,
                                            labelStyle: const TextStyle(
                                                color: Colors.white),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                          ),
                                enabled:
                                    !isAlreadyAdded && product.quantity > 0,
                              ),
                            );
                          },
                        ),
                ),
              ),
              // Afficher un message si plus de résultats sont disponibles
              if (_filteredProducts.length >= 20 && _allProducts.length > 20)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    loc.venteSearchLimitMessage,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelectionPage() {
    final loc = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart,
                      color: Colors.blueGrey[800], size: 28),
                  const SizedBox(width: 8),
                  Text(
                    loc.venteProductsTitle,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Widget de recherche de produits
              _buildProductSearchWidget(),

              const SizedBox(height: 16),

              // Zone des produits sélectionnés
              Expanded(
                child: _selectedProducts.isNotEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  loc.venteSelectedProducts,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[800],
                                  ),
                                ),
                                Chip(
                                  label: Text('${_selectedProducts.length}'),
                                  backgroundColor: Colors.blueGrey[800],
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _selectedProducts.length,
                              itemBuilder: (context, index) {
                                final product = _selectedProducts[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[100],
                                      child: Text(
                                        '${product.quantityToSell}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Prix avec possibilité de modification
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (product.priceOverride !=
                                                      product.prixVente) ...[
                                                    Text(
                                                      loc.venteOriginalPrice(
                                                          _currencyFormatter
                                                              .format(product
                                                                  .prixVente)),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                  ],
                                                  Row(
                                                    children: [
                                                      Text(
                                                        loc.ventePrice(
                                                            _currencyFormatter
                                                                .format(product
                                                                    .priceOverride)),
                                                        style: TextStyle(
                                                          color: product
                                                                      .priceOverride <
                                                                  product
                                                                      .prixVente
                                                              ? Colors
                                                                  .orange[700]
                                                              : Colors
                                                                  .green[700],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      if (product
                                                              .priceOverride <
                                                          product
                                                              .prixVente) ...[
                                                        const SizedBox(
                                                            width: 4),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .orange[100],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: Text(
                                                            '-${((product.prixVente - product.priceOverride) / product.prixVente * 100).toStringAsFixed(0)}%',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .orange[900],
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                size: 20,
                                                color: Colors.blue[700],
                                              ),
                                              onPressed: () =>
                                                  _showEditPriceDialog(product),
                                              tooltip:
                                                  loc.venteEditPriceTooltip,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.remove_circle_outline),
                                              iconSize: 20,
                                              color: Colors.red,
                                              onPressed: () =>
                                                  _updateProductQuantity(
                                                      product.id,
                                                      product.quantityToSell -
                                                          1),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${product.quantityToSell}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.add_circle_outline),
                                              iconSize: 20,
                                              color: Colors.green,
                                              onPressed: () =>
                                                  _updateProductQuantity(
                                                      product.id,
                                                      product.quantityToSell +
                                                          1),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _removeProduct(product.id),
                                          tooltip: loc.venteDeleteTooltip,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Total
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.attach_money,
                                        color: Colors.green[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      loc.venteTotal,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _currencyFormatter.format(_calculateTotal()),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loc.venteNoProductsSelected,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              loc.venteNoProductsHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    final loc = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: Text(loc.ventePrevious),
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentPage > 0 && _currentPage < 3) const SizedBox(width: 12),
          if (_currentPage < 3)
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: Text(loc.venteNext),
                onPressed: () {
                  if (_currentPage == 0) {
                    _handleNextClientStep();
                  } else {
                    _nextPage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentPage == 3)
            Expanded(
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? loc.venteSaving : loc.venteFinishSale),
                onPressed: _isLoading ? null : _submitSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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
      } else if (newQuantity > product.quantity) {
        final loc = AppLocalizations.of(context);
        _showError(loc.venteMaxQuantity(product.quantity.toString()));
      }
    });
  }

  void _removeProduct(int productId) {
    final loc = AppLocalizations.of(context);
    setState(() {
      _selectedProducts.removeWhere((p) => p.id == productId);
    });
    _showSuccess(loc.venteProductRemoved);
  }

  // Afficher le dialogue pour modifier le prix
  Future<void> _showEditPriceDialog(SaleProduct product) async {
    final loc = AppLocalizations.of(context);
    final TextEditingController priceController = TextEditingController(
      text: product.priceOverride.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.venteModifyPrice,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.venteOriginalPrice(
                            _currencyFormatter.format(product.prixVente)),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: loc.venteNewPriceLabel,
                          hintText: loc.venteNewPriceHint,
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: '\$',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          setDialogState(
                              () {}); // Mettre à jour l'affichage en temps réel
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return loc.ventePriceRequired;
                          }
                          final price = double.tryParse(value);
                          if (price == null) {
                            return loc.ventePriceInvalid;
                          }
                          if (price < 0) {
                            return loc.ventePriceNegative;
                          }
                          if (price > product.prixVente * 2) {
                            return loc.ventePriceTooHigh;
                          }
                          return null;
                        },
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      // Afficher la réduction si applicable
                      Builder(
                        builder: (context) {
                          final newPrice =
                              double.tryParse(priceController.text) ??
                                  product.priceOverride;
                          if (newPrice < product.prixVente) {
                            final reduction = product.prixVente - newPrice;
                            final percentage =
                                (reduction / product.prixVente * 100);
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.trending_down,
                                      color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.venteReduction(_currencyFormatter
                                              .format(reduction)),
                                          style: TextStyle(
                                            color: Colors.orange[900],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          loc.venteReductionPercent(
                                              percentage.toStringAsFixed(1)),
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (newPrice > product.prixVente) {
                            final augmentation = newPrice - product.prixVente;
                            final percentage =
                                (augmentation / product.prixVente * 100);
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up,
                                      color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.venteIncrease(_currencyFormatter
                                              .format(augmentation)),
                                          style: TextStyle(
                                            color: Colors.blue[900],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          loc.venteIncreasePercent(
                                              percentage.toStringAsFixed(1)),
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(loc.venteCancel),
                ),
                TextButton(
                  onPressed: () {
                    // Réinitialiser au prix original
                    priceController.text = product.prixVente.toStringAsFixed(2);
                    setDialogState(() {}); // Mettre à jour l'affichage
                  },
                  child: Text(
                    loc.venteReset,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newPrice = double.parse(priceController.text);
                      setState(() {
                        product.priceOverride = newPrice;
                      });
                      Navigator.of(dialogContext).pop();
                      _showSuccess(loc.ventePriceModified);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                  child: Text(loc.venteSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Demander le statut de paiement via un popup
  Future<String?> _askPaymentStatus() async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Finalisation de la vente"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choisissez le mode de paiement pour cette vente :",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                  "Note : Seules les factures 'PAYÉES' augmentent le montant en caisse.",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.money_off, color: Colors.orange),
              onPressed: () => Navigator.of(context).pop('impayée'),
              label: const Text("À CRÉDIT",
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_money, color: Colors.white),
              onPressed: () => Navigator.of(context).pop('payée'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              label: const Text("CASH / PAYÉ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Générer la facture via l'API
  Future<int?> _generateInvoice(int saleId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/add_invoice.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sale_id': saleId, 'status': status}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['invoice_id'] != null) {
          return data['invoice_id'] as int;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
