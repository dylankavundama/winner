import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/product_model.dart';
import 'package:gestion_app_mobile/product_page.dart' as product_page;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DepositPage extends StatefulWidget {
  final Client? initialClient;

  const DepositPage({Key? key, this.initialClient}) : super(key: key);

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _formKey = GlobalKey<FormState>();

  Client? _selectedClient;
  Product? _selectedProduct;
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _loading = false;
  bool _initialLoading = true;
  String? _error;

  List<Client> _clients = [];
  List<Product> _products = [];
  List<Map<String, dynamic>> _history = [];
  double _historyTotal = 0.0;
  bool _historyLoading = false;

  final _currencyFormatter =
      NumberFormat.currency(locale: 'fr_FR', symbol: '\$', decimalDigits: 2);
  final TextEditingController _clientSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.initialClient != null) {
      _selectedClient = widget.initialClient;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _fetchClients(),
        _fetchProducts(),
      ]);
      // Si un client initial est fourni, s'assurer qu'il est bien sélectionné
      if (widget.initialClient != null) {
        final existing = _clients
            .firstWhere((c) => c.id == widget.initialClient!.id, orElse: () {
          return widget.initialClient!;
        });
        _selectedClient = existing;
        _clientSearchController.text = existing.name;
      }
    } catch (e) {
      _error = 'Erreur de chargement des données : $e';
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _fetchClients() async {
    final response = await http.get(Uri.parse(ApiConstants.clientsApi));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['success'] == true && data['clients'] is List) {
        setState(() {
          _clients = (data['clients'] as List)
              .map((e) => Client.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    }
  }

  Future<void> _fetchProducts() async {
    final response = await http.get(Uri.parse(ApiConstants.productsApi));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['success'] == true && data['products'] is List) {
        setState(() {
          _products = (data['products'] as List)
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    }
  }

  Future<void> _fetchHistory() async {
    if (_selectedClient == null || _selectedProduct == null) {
      setState(() {
        _history = [];
        _historyTotal = 0.0;
      });
      return;
    }

    setState(() {
      _historyLoading = true;
    });

    try {
      final uri = Uri.parse(
          '${ApiConstants.depositsApi}?client_id=${_selectedClient!.id}&product_id=${_selectedProduct!.id}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          final List<dynamic> items = data['deposits'] ?? [];
          setState(() {
            _history = items
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            _historyTotal =
                (data['total_amount'] as num?)?.toDouble() ?? 0.0;
          });
        }
      }
    } catch (_) {
      // Ignorer silencieusement pour ne pas bloquer la page
    } finally {
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null || _selectedProduct == null) {
      _showSnackBar(
        'Veuillez sélectionner un client et un produit.',
        isError: true,
      );
      return;
    }

    final amount = double.tryParse(
          _amountController.text.replaceAll(',', '.'),
        ) ??
        0;
    if (amount <= 0) {
      _showSnackBar(
        'Le montant doit être supérieur à 0.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.depositsApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': _selectedClient!.id,
          'product_id': _selectedProduct!.id,
          'amount': amount,
          'deposit_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar('Dépôt enregistré avec succès.');
        setState(() {
          _amountController.clear();
        });
        // Recharger l'historique pour ce client/produit
        await _fetchHistory();
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
          data['message'] ?? 'Erreur lors de l\'enregistrement du dépôt.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion : $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau dépôt'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Client',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TypeAheadField<Client>(
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Rechercher un client',
                              hintText: 'Tapez le nom du client...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          );
                        },
                        controller: _clientSearchController,
                        suggestionsCallback: (pattern) async {
                          if (pattern.isEmpty) return _clients;
                          final lower = pattern.toLowerCase();
                          return _clients
                              .where((c) =>
                                  c.name.toLowerCase().contains(lower))
                              .toList();
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
                          _fetchHistory();
                        },
                        emptyBuilder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _clients.isEmpty
                                  ? 'Aucun client enregistré'
                                  : 'Aucun client trouvé',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Produit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Product>(
                        value: _selectedProduct,
                        items: _products
                            .map(
                              (p) => DropdownMenuItem<Product>(
                                value: p,
                                child: Text(
                                    '${p.name} (${_currencyFormatter.format(p.prixVente)})'),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner un produit',
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedProduct = val;
                          });
                          _fetchHistory();
                        },
                        validator: (val) => val == null
                            ? 'Veuillez sélectionner un produit'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                          ),
                          label: const Text(
                            'Produit introuvable ? Ajouter un produit',
                            style: TextStyle(fontSize: 13),
                          ),
                          onPressed: () async {
                            // Ouvre la page de gestion des produits pour en créer un nouveau
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const product_page.ProductPage(),
                              ),
                            );
                            // Au retour, on recharge la liste des produits
                            await _fetchProducts();
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Montant du dépôt',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Montant requis' : null,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Date du dépôt',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: DateFormat('yyyy-MM-dd').format(_selectedDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _loading ? 'Enregistrement...' : 'Enregistrer le dépôt',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_selectedClient != null &&
                          _selectedProduct != null) ...[
                        Text(
                          'Historique des dépôts pour ce client et ce produit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_historyLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_history.isEmpty)
                          Text(
                            'Aucun dépôt trouvé pour cette sélection.',
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        else ...[
                          Card(
                            color: Colors.blueGrey[50],
                            child: ListTile(
                              leading: const Icon(Icons.savings,
                                  color: Colors.blueGrey),
                              title: const Text('Total déjà déposé'),
                              subtitle: Text(
                                _currencyFormatter
                                    .format(_historyTotal),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final d = _history[index];
                              final amount = d['amount'];
                              final reserved =
                                  (d['stock_reserved'] ?? 0) == 1;
                              final date = d['deposit_date'] ?? '';
                              final double amt =
                                  amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0;
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    reserved
                                        ? Icons.check_circle
                                        : Icons.warning_amber,
                                    color: reserved
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  title: Text(
                                      _currencyFormatter.format(amt)),
                                  subtitle: Text(date.toString()),
                                  trailing: Text(
                                    reserved
                                        ? 'Réservé'
                                        : 'Hors stock',
                                    style: TextStyle(
                                      color: reserved
                                          ? Colors.green
                                          : Colors.orange[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}


