import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/product_model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdditionalDepositPage extends StatefulWidget {
  final Client client;
  final Product product;

  const AdditionalDepositPage({
    Key? key,
    required this.client,
    required this.product,
  }) : super(key: key);

  @override
  State<AdditionalDepositPage> createState() => _AdditionalDepositPageState();
}

class _AdditionalDepositPageState extends State<AdditionalDepositPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _loading = false;
  bool _initialLoading = true;
  double _historyTotal = 0.0;
  double _productPrice = 0.0;

  final _currencyFormatter =
      NumberFormat.currency(locale: 'fr_FR', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _initialLoading = true;
    });
    try {
      await Future.wait([
        _fetchDepositHistory(),
        _fetchProductPrice(),
      ]);
    } catch (e) {
      // Gérer l'erreur silencieusement
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDepositHistory() async {
    try {
      final uri = Uri.parse(
          '${ApiConstants.depositsApi}?client_id=${widget.client.id}&product_id=${widget.product.id}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          final dynamic totalRaw = data['total_amount'];
          if (mounted) {
            setState(() {
              _historyTotal = totalRaw is num
                  ? totalRaw.toDouble()
                  : double.tryParse('$totalRaw') ?? 0.0;
            });
          }
        }
      }
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  Future<void> _fetchProductPrice() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.productsApi));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true && data['products'] is List) {
          final products = (data['products'] as List)
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
          final foundProduct = products.firstWhere(
            (p) => p.id == widget.product.id,
            orElse: () => widget.product,
          );
          if (mounted) {
            setState(() {
              _productPrice = foundProduct.prixVente;
            });
          }
        }
      }
    } catch (_) {
      // Utiliser le prix du produit passé en paramètre
      if (mounted) {
        setState(() {
          _productPrice = widget.product.prixVente;
        });
      }
    }
  }

  double get _remainingToPay {
    return (_productPrice - _historyTotal).clamp(0, double.infinity);
  }

  bool get _isFullyPaid {
    // Utiliser une tolérance pour les comparaisons de nombres à virgule flottante
    // Vérifier que le total des dépôts est égal ou supérieur au prix de vente
    return _productPrice > 0 && _historyTotal >= _productPrice - 0.01;
  }

  bool get _canDeliver {
    // Le produit peut être livré si :
    // 1. Le reste à payer est 0 (produit entièrement payé)
    // 2. Le produit est en stock (quantity > 0)
    // 
    // IMPORTANT: Si le produit n'est PAS en stock ET le client n'a pas encore tout payé,
    // le bouton "Livrer" ne s'affichera PAS (car _isFullyPaid sera false OU quantity <= 0)
    return _isFullyPaid && widget.product.quantity > 0;
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
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.depositsApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': widget.client.id,
          'product_id': widget.product.id,
          'amount': amount,
          'deposit_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar(loc.depositSuccess);

        // Récupérer quelques infos utiles pour le reçu
        final int? depositId = data['deposit_id'] is int
            ? data['deposit_id'] as int
            : int.tryParse('${data['deposit_id'] ?? ''}');
        final bool stockReserved =
            (data['stock_reserved'] == true) || (data['stock_reserved'] == 1);

        // Recharger le produit pour avoir la quantité à jour avant l'impression
        Product? updatedProduct = widget.product;
        try {
          final productResponse = await http.get(Uri.parse(ApiConstants.productsApi));
          if (productResponse.statusCode == 200) {
            final productData = jsonDecode(productResponse.body);
            if (productData is Map &&
                productData['success'] == true &&
                productData['products'] is List) {
              final products = (productData['products'] as List)
                  .map((e) => Product.fromJson(e as Map<String, dynamic>))
                  .toList();
              final foundProduct = products.firstWhere(
                (p) => p.id == widget.product.id,
                orElse: () => widget.product,
              );
              updatedProduct = foundProduct;
            }
          }
        } catch (_) {
          // Si le rechargement échoue, on utilise le produit existant
        }

        // Imprimer le reçu (preuve de paiement) - TOUJOURS imprimer pour chaque dépôt
        try {
          await _printDepositReceipt(
            depositId: depositId,
            client: widget.client,
            product: updatedProduct ?? widget.product,
            amount: amount,
            date: _selectedDate,
            stockReserved: stockReserved,
          );
        } catch (e) {
          // Afficher un message si l'impression échoue, mais ne pas bloquer l'utilisateur
          if (mounted) {
            _showSnackBar(
              loc.depositPrintError(e.toString()),
              isError: true,
            );
          }
        }

        setState(() {
          _amountController.clear();
        });
        // Recharger l'historique
        await _fetchDepositHistory();
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
      _showSnackBar(loc.depositConnectionError(ErrorUtils.getUserFriendlyError(e)), isError: true);
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

  Future<void> _deliverProduct() async {
    final loc = AppLocalizations.of(context);

    // Vérifier que le produit est en stock
    if (widget.product.quantity <= 0) {
      _showSnackBar('Le produit n\'est pas en stock', isError: true);
      return;
    }

    // Vérifier que le produit est entièrement payé
    if (!_isFullyPaid) {
      _showSnackBar('Le produit n\'est pas entièrement payé', isError: true);
      return;
    }

    // Confirmer avant de livrer
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.depositDeliverButton),
        content: Text(loc.depositDeliverConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      // Créer la vente automatiquement
      final response = await http.post(
        Uri.parse(ApiConstants.addSaleApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': widget.client.id,
          'user_id': userId,
          'total': _productPrice,
          'imei': '',
          'garanti': '',
          'products': [
            {
              'id': widget.product.id,
              'quantity': 1,
              'price': _productPrice,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSnackBar(loc.depositDeliverSuccess);
          // Recharger l'historique
          await _fetchDepositHistory();
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          _showSnackBar(
            data['message'] ?? loc.depositDeliverError,
            isError: true,
          );
        }
      } else {
        _showSnackBar(loc.depositDeliverError, isError: true);
      }
    } catch (e) {
      _showSnackBar(
        '${loc.depositDeliverError}: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
      // Vérifier si le produit est en stock (quantity <= 0)
      String stockStatusText;
      if (product.quantity <= 0) {
        stockStatusText = loc.depositReceiptStockEmpty;
      } else if (stockReserved) {
        stockStatusText = loc.depositReceiptReserved;
      } else {
        stockStatusText = loc.depositReceiptNotReserved;
      }
      await SunmiPrinter.printText(stockStatusText);
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
      _showSnackBar(loc.depositPrintError(e.toString()), isError: true);
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
        title: Text(loc.additionalDepositTitle),
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
                      // Informations client et produit
                      Card(
                        color: Colors.blueGrey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      color: Colors.blueGrey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      loc.additionalDepositClient,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.client.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2,
                                      color: Colors.blueGrey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      loc.additionalDepositProduct,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.product.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Résumé des dépôts
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
                              if (_productPrice > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  loc.depositRemainingToPay +
                                      _currencyFormatter.format(_remainingToPay),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Montant du dépôt supplémentaire
                      Text(
                        loc.additionalDepositAmountLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: loc.depositAmountLabel,
                          prefixIcon: const Icon(Icons.attach_money),
                          hintText: '0.00',
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? loc.depositAmountLabel
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Date du dépôt
                      Text(
                        loc.additionalDepositDateLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      // Bouton Livrer si le reste à payer = 0 ET le produit est en stock
                      if (_canDeliver)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _deliverProduct,
                            icon: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.local_shipping),
                            label: Text(
                              _loading ? 'Livraison...' : loc.depositDeliverButton,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      if (_canDeliver)
                        const SizedBox(height: 16),
                      // Bouton d'enregistrement
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
                            _loading
                                ? loc.depositSaving
                                : loc.additionalDepositSaveButton,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

