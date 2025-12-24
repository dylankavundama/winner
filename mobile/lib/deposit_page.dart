import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/product_model.dart';
import 'package:gestion_app_mobile/product_page.dart' as product_page;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:gestion_app_mobile/app_localizations.dart';

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

  double get _remainingToPay {
    if (_selectedProduct == null) return 0.0;
    return _selectedProduct!.prixVente - _historyTotal;
  }

  double get _clientCredit {
    // Crédit = solde dépôt - prix de vente si supérieur à 0
    if (_selectedProduct == null) return 0.0;
    final credit = _historyTotal - _selectedProduct!.prixVente;
    return credit > 0 ? credit : 0.0;
  }

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
            final dynamic totalRaw = data['total_amount'];
            _historyTotal = totalRaw is num
                ? totalRaw.toDouble()
                : double.tryParse('$totalRaw') ?? 0.0;
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
    final loc = AppLocalizations.of(context);
    if (_selectedClient == null || _selectedProduct == null) {
      _showSnackBar(
        loc.depositSelectClientProduct,
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
        loc.depositAmountPositive,
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
      final loc = AppLocalizations.of(context);
      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar(loc.depositSuccess);

        // Récupérer quelques infos utiles pour le reçu
        final int? depositId = data['deposit_id'] is int
            ? data['deposit_id'] as int
            : int.tryParse('${data['deposit_id'] ?? ''}');
        final bool stockReserved =
            (data['stock_reserved'] == true) || (data['stock_reserved'] == 1);

        // Imprimer le reçu (preuve de paiement)
        try {
          await _printDepositReceipt(
            depositId: depositId,
            client: _selectedClient!,
            product: _selectedProduct!,
            amount: amount,
            date: _selectedDate,
            stockReserved: stockReserved,
          );
        } catch (_) {
          // On ne bloque pas l'utilisateur si l'impression échoue
        }

        setState(() {
          _amountController.clear();
        });
        // Recharger l'historique pour ce client/produit
        await _fetchHistory();
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar(
          data['message'] ?? loc.depositError,
          isError: true,
        );
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      _showSnackBar(loc.depositConnectionError(e.toString()), isError: true);
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

  Future<void> _closeDeposit() async {
    if (_selectedClient == null || _selectedProduct == null) return;

    // TODO: Implémenter ici l'appel API qui va clôturer automatiquement
    // la vente côté serveur et, si nécessaire, enregistrer le crédit client.
    _showSnackBar(
      'Clôture du dépôt à implémenter côté serveur.',
    );
  }

  /// Imprime un reçu de dépôt sur l'imprimante Sunmi (preuve de paiement)
  Future<void> _printDepositReceipt({
    required Client client,
    required Product product,
    required double amount,
    required DateTime date,
    required bool stockReserved,
    int? depositId,
  }) async {
    final loc = AppLocalizations.of(context);
    bool? isConnected = await SunmiPrinter.bindingPrinter();
    if (isConnected != true) {
      _showSnackBar(
        loc.depositPrinterError,
        isError: true,
      );
      return;
    }

    try {
      await SunmiPrinter.initPrinter();

      // Logo si disponible
      try {
        final ByteData logoBytes = await rootBundle.load('assets/logo.png');
        final Uint8List logoData = logoBytes.buffer.asUint8List();
        await SunmiPrinter.printImage(logoData);
        await SunmiPrinter.lineWrap(1);
      } catch (_) {
        // Logo optionnel
      }

      final String dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);

      final loc = AppLocalizations.of(context);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.bold();
      await SunmiPrinter.setFontSize(SunmiFontSize.LG);
      await SunmiPrinter.printText(loc.depositReceiptTitle);
      await SunmiPrinter.resetBold();
      await SunmiPrinter.setFontSize(SunmiFontSize.MD);
      await SunmiPrinter.lineWrap(1);

      if (depositId != null) {
        await SunmiPrinter.printText(loc.depositReceiptNumber(depositId));
      }
      await SunmiPrinter.printText(loc.depositReceiptDate(dateStr));
      await SunmiPrinter.line();

      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      await SunmiPrinter.bold();
      await SunmiPrinter.printText(loc.depositReceiptClient);
      await SunmiPrinter.resetBold();
      await SunmiPrinter.printText(loc.depositReceiptClientName(client.name));
      await SunmiPrinter.lineWrap(1);

      await SunmiPrinter.bold();
      await SunmiPrinter.printText(loc.depositReceiptProduct);
      await SunmiPrinter.resetBold();
      await SunmiPrinter.printText(product.name);
      await SunmiPrinter.lineWrap(1);

      await SunmiPrinter.bold();
      await SunmiPrinter.printText(loc.depositReceiptAmount);
      await SunmiPrinter.resetBold();
      await SunmiPrinter.printText('${amount.toStringAsFixed(2)} \$');
      await SunmiPrinter.lineWrap(1);

      await SunmiPrinter.bold();
      await SunmiPrinter.printText(loc.depositReceiptStockStatus);
      await SunmiPrinter.resetBold();
      await SunmiPrinter.printText(
          stockReserved ? loc.depositReceiptReserved : loc.depositReceiptNotReserved);
      await SunmiPrinter.lineWrap(2);

      await SunmiPrinter.setFontSize(SunmiFontSize.SM);
      await SunmiPrinter.printText(loc.depositReceiptProof);
      await SunmiPrinter.lineWrap(2);

      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.setFontSize(SunmiFontSize.MD);
      await SunmiPrinter.printText(loc.depositReceiptThanks);
      await SunmiPrinter.lineWrap(3);

      await SunmiPrinter.cut();
    } catch (e) {
      final loc = AppLocalizations.of(context);
      _showSnackBar(loc.depositPrintError(e.toString()),
          isError: true);
    } finally {
      try {
        await SunmiPrinter.unbindingPrinter();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.depositTitle),
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
                      Text(
                        loc.depositClientLabel,
                        style: const TextStyle(
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
                            decoration: InputDecoration(
                              labelText: loc.depositSearchClient,
                              hintText: loc.depositSearchClientHint,
                              prefixIcon: const Icon(Icons.search),
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
                          final loc = AppLocalizations.of(context);
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _clients.isEmpty
                                  ? loc.depositNoClients
                                  : loc.depositNoClientFound,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.depositProductLabel,
                        style: const TextStyle(
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
                        decoration: InputDecoration(
                          labelText: loc.depositSelectProduct,
                          prefixIcon: const Icon(Icons.inventory_2),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedProduct = val;
                          });
                          _fetchHistory();
                        },
                        validator: (val) => val == null
                            ? loc.depositSelectProduct
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
                          label: Text(
                            loc.depositProductNotFound,
                            style: const TextStyle(fontSize: 13),
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
                        decoration: InputDecoration(
                          labelText: loc.depositAmountLabel,
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? loc.depositAmountLabel : null,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _selectDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: loc.depositDateLabel,
                              prefixIcon: const Icon(Icons.calendar_today),
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
                            _loading ? loc.depositSaving : loc.depositSaveButton,
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
                          loc.depositHistoryTitle,
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
                            loc.depositNoDepositsFound,
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        else ...[
                          Card(
                            color: Colors.blueGrey[50],
                            child: ListTile(
                              leading: const Icon(Icons.savings,
                                  color: Colors.blueGrey),
                              title: Text(loc.depositTotalDeposited),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currencyFormatter.format(_historyTotal),
                                  ),
                                  if (_selectedProduct != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      loc.depositRemainingToPay +
                                          _currencyFormatter.format(
                                            _remainingToPay
                                                .clamp(0, double.infinity),
                                          ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blueGrey[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_clientCredit > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        loc.depositClientCredit +
                                            _currencyFormatter
                                                .format(_clientCredit),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedProduct != null &&
                              _remainingToPay <= 0)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _closeDeposit,
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(loc.depositCloseButton),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                                        ? loc.depositReserved
                                        : loc.depositOutOfStock,
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


