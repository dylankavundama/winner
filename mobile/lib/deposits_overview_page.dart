import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/deposit_page.dart';
import 'package:gestion_app_mobile/additional_deposit_page.dart';
import 'package:gestion_app_mobile/deposits_history_page.dart';
import 'package:gestion_app_mobile/product_model.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class DepositsOverviewPage extends StatefulWidget {
  const DepositsOverviewPage({Key? key}) : super(key: key);

  @override
  State<DepositsOverviewPage> createState() => _DepositsOverviewPageState();
}

class _DepositsOverviewPageState extends State<DepositsOverviewPage> {
  bool _loading = true;
  String? _error;
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'fr_FR', symbol: '\$', decimalDigits: 2);

  // clientId -> {client: Client, total: double, remaining: double}
  final Map<int, Map<String, dynamic>> _clientTotals = {};

  @override
  void initState() {
    super.initState();
    _fetchDeposits();
  }

  Future<void> _fetchDeposits() async {
    setState(() {
      _loading = true;
      _error = null;
      _clientTotals.clear();
    });
    try {
      // Charger les prix des produits pour pouvoir calculer le "reste à payer"
      final productsResponse =
          await http.get(Uri.parse(ApiConstants.productsApi));
      final Map<int, double> productPrices = {};
      if (productsResponse.statusCode == 200) {
        final prodData = jsonDecode(productsResponse.body);
        if (prodData is Map &&
            prodData['success'] == true &&
            prodData['products'] is List) {
          for (final p in (prodData['products'] as List)) {
            final map = p as Map<String, dynamic>;
            final int id = int.tryParse('${map['id']}') ?? 0;
            if (id == 0) continue;
            final dynamic rawPrice = map['prix_vente'];
            final double price = rawPrice is num
                ? rawPrice.toDouble()
                : double.tryParse('$rawPrice') ?? 0.0;
            productPrices[id] = price;
          }
        }
      }

      final response = await http.get(Uri.parse(ApiConstants.depositsApi));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          final List<dynamic> deposits = data['deposits'] ?? [];
          
          // Grouper les dépôts par client et produit pour calculer correctement le reste à payer
          final Map<String, Map<String, dynamic>> clientProductTotals = {};
          
          for (final d in deposits) {
            final map = d as Map<String, dynamic>;
            final int clientId =
                int.tryParse('${map['client_id']}') ?? 0;
            if (clientId == 0) continue;
            final String name = (map['client_name'] ?? '') as String;
            final int productId =
                int.tryParse('${map['product_id']}') ?? 0;

            // amount peut venir de l'API en String ou en nombre -> on normalise en double
            final dynamic rawAmount = map['amount'];
            final double amount = rawAmount is num
                ? rawAmount.toDouble()
                : double.tryParse('$rawAmount') ?? 0.0;

            // Clé unique pour client+produit
            final String key = '$clientId-$productId';
            
            clientProductTotals.putIfAbsent(key, () {
              return {
                'client_id': clientId,
                'client_name': name,
                'product_id': productId,
                'total': 0.0,
                'product_price': productPrices[productId] ?? 0.0,
              };
            });
            clientProductTotals[key]!['total'] =
                (clientProductTotals[key]!['total'] as double) + amount;
          }
          
          // Maintenant, calculer le reste à payer pour chaque client+produit et agréger par client
          for (final entry in clientProductTotals.entries) {
            final clientId = entry.value['client_id'] as int;
            final clientName = entry.value['client_name'] as String;
            final totalDeposits = entry.value['total'] as double;
            final productPrice = entry.value['product_price'] as double;
            
            // Calculer le reste à payer pour ce client+produit
            final double remaining = (productPrice - totalDeposits).clamp(0, double.infinity);
            
            _clientTotals.putIfAbsent(clientId, () {
              return {
                'client': Client(id: clientId, name: clientName),
                'total': 0.0,
                'remaining': 0.0,
              };
            });
            _clientTotals[clientId]!['total'] =
                (_clientTotals[clientId]!['total'] as double) + totalDeposits;
            _clientTotals[clientId]!['remaining'] =
                (_clientTotals[clientId]!['remaining'] as double) + remaining;
          }
        } else {
          final loc = AppLocalizations.of(context);
          _error = data['message'] ?? loc.depositsOverviewLoadError;
        }
      } else {
        final loc = AppLocalizations.of(context);
        _error = loc.depositsOverviewServerError(response.statusCode);
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      _error = loc.depositsOverviewConnectionError(ErrorUtils.getUserFriendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final entries = _clientTotals.entries.toList()
      ..sort((a, b) =>
          (b.value['total'] as double).compareTo(a.value['total'] as double));

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.depositsOverviewTitle),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique des dépôts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DepositsHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDeposits,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : entries.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.savings_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    loc.depositsOverviewEmpty,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
          final entry = entries[index];
          final client = entry.value['client'] as Client;
          final double total =
              entry.value['total'] as double? ?? 0.0;
          final double remaining =
              entry.value['remaining'] as double? ?? 0.0;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueGrey[100],
                                child: Text(
                                  client.name.isNotEmpty
                                      ? client.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(client.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.depositsOverviewTotalDeposits + _currencyFormatter.format(total),
                              ),
                              if (remaining > 0)
                                Text(
                                  loc.depositsOverviewRemainingTotal + _currencyFormatter.format(remaining),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DepositHistoryPage(
                                      client: client,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Ouvrir la page d'ajout de dépôt (sans client pré‑sélectionné)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DepositPage(),
            ),
          );
          // Si un dépôt a été ajouté, on recharge la liste des totaux
          if (result == true) {
            await _fetchDeposits();
          }
        },
        tooltip: 'Ajouter un deposit',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DepositHistoryPage extends StatefulWidget {
  final Client client;

  const DepositHistoryPage({Key? key, required this.client}) : super(key: key);

  @override
  State<DepositHistoryPage> createState() => _DepositHistoryPageState();
}

class _DepositHistoryPageState extends State<DepositHistoryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _history = [];
  double _total = 0.0;

  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'fr_FR', symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<Product?> _getProduct(int productId, String productName) async {
    try {
      // Récupérer les informations complètes du produit
      final response = await http.get(Uri.parse(ApiConstants.productsApi));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true && data['products'] is List) {
          final products = (data['products'] as List)
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
          return products.firstWhere(
            (p) => p.id == productId,
            orElse: () => Product(
              id: productId,
              name: productName,
              prixVente: 0.0,
              quantity: 0,
            ),
          );
        }
      }
    } catch (e) {
      // En cas d'erreur, créer un produit minimal
      return Product(
        id: productId,
        name: productName,
        prixVente: 0.0,
        quantity: 0,
      );
    }
    return null;
  }

  Future<void> _openAdditionalDepositPage(int productId, String productName) async {
    final product = await _getProduct(productId, productName);
    if (product != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdditionalDepositPage(
            client: widget.client,
            product: product,
          ),
        ),
      );
      if (result == true) {
        await _fetchHistory();
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

  /// Imprime un reçu de dépôt sur l'imprimante Sunmi
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
      _showSnackBar('Reçu imprimé avec succès');
    } catch (e) {
      final loc = AppLocalizations.of(context);
      _showSnackBar(loc.depositPrintError(e.toString()), isError: true);
    } finally {
      try {
        await SunmiPrinter.unbindingPrinter();
      } catch (_) {}
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
      _history = [];
      _total = 0.0;
    });
    try {
      final uri = Uri.parse(
          '${ApiConstants.depositsApi}?client_id=${widget.client.id}');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          final List<dynamic> items = data['deposits'] ?? [];
          double sum = 0.0;
          final List<Map<String, dynamic>> list = [];
          for (final d in items) {
            final map = d as Map<String, dynamic>;
            final dynamic rawAmount = map['amount'];
            final double amount = rawAmount is num
                ? rawAmount.toDouble()
                : double.tryParse('$rawAmount') ?? 0.0;
            sum += amount;
            list.add(map);
          }
          setState(() {
            _history = list;
            _total = sum;
          });
        } else {
          final loc = AppLocalizations.of(context);
          _error = data['message'] ?? loc.depositsOverviewLoadHistoryError;
        }
      } else {
        final loc = AppLocalizations.of(context);
        _error = loc.depositsOverviewServerError(response.statusCode);
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      _error = loc.depositsOverviewConnectionError(ErrorUtils.getUserFriendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.depositsOverviewHistoryTitle(widget.client.name)),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        color: Colors.blueGrey[50],
                        child: ListTile(
                          leading: const Icon(Icons.savings,
                              color: Colors.blueGrey),
                          title: Text(loc.depositsOverviewTotal),
                          subtitle: Text(_currencyFormatter.format(_total)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Text(
                              loc.depositsOverviewNoDepositsClient,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ..._history.map((d) {
                          final dynamic rawAmount = d['amount'];
                          final double amount = rawAmount is num
                              ? rawAmount.toDouble()
                              : double.tryParse('$rawAmount') ?? 0.0;
                          final String productName =
                              (d['product_name'] ?? '') as String;
                          final int productId =
                              int.tryParse('${d['product_id'] ?? 0}') ?? 0;
                          final String date =
                              (d['deposit_date'] ?? '') as String;
                          final bool reserved =
                              (d['stock_reserved'] ?? 0) == 1;
                          final int? depositId = int.tryParse('${d['id'] ?? ''}');
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                reserved
                                    ? Icons.check_circle
                                    : Icons.warning_amber,
                                color: reserved
                                    ? Colors.green
                                    : Colors.orange[800],
                              ),
                              title: Text(_currencyFormatter.format(amount)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (productName.isNotEmpty)
                                    Text(productName),
                                  Text(date),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.print, color: Colors.blueGrey),
                                    tooltip: 'Imprimer le reçu',
                                    onPressed: () async {
                                      // Récupérer le produit pour l'impression
                                      final product = await _getProduct(productId, productName);
                                      if (product != null) {
                                        // Parser la date du dépôt
                                        DateTime depositDate;
                                        try {
                                          depositDate = DateTime.parse(date);
                                        } catch (_) {
                                          depositDate = DateTime.now();
                                        }
                                        await _printDepositReceipt(
                                          client: widget.client,
                                          product: product,
                                          amount: amount,
                                          date: depositDate,
                                          stockReserved: reserved,
                                          depositId: depositId,
                                        );
                                      } else {
                                        _showSnackBar('Impossible de récupérer les informations du produit', isError: true);
                                      }
                                    },
                                  ),
                                  Text(
                                    reserved ? loc.depositReserved : loc.depositOutOfStock,
                                    style: TextStyle(
                                      color: reserved
                                          ? Colors.green
                                          : Colors.orange[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                // Ouvrir la page de dépôt supplémentaire pour ce produit
                                if (productId > 0) {
                                  await _openAdditionalDepositPage(productId, productName);
                                }
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      if (_history.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text(loc.depositsOverviewAddButton),
                            onPressed: () async {
                              // Utiliser le premier produit de l'historique pour le dépôt supplémentaire
                              final firstDeposit = _history.first;
                              final int productId =
                                  int.tryParse('${firstDeposit['product_id'] ?? 0}') ?? 0;
                              final String productName =
                                  (firstDeposit['product_name'] ?? '') as String;
                              if (productId > 0) {
                                await _openAdditionalDepositPage(productId, productName);
                              } else {
                                // Si pas de produit ID, utiliser l'ancienne page
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DepositPage(initialClient: widget.client),
                                  ),
                                );
                                if (result == true) {
                                  await _fetchHistory();
                                }
                              }
                            },
                          ),
                        ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Ouvrir la page d'ajout de deposit pour ce client
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DepositPage(initialClient: widget.client),
            ),
          );
          if (result == true) {
            await _fetchHistory();
          }
        },
        tooltip: loc.depositsOverviewAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}


