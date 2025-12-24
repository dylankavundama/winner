import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/deposit_page.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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
          for (final d in deposits) {
            final map = d as Map<String, dynamic>;
            final int clientId =
                int.tryParse('${map['client_id']}') ?? 0; // nullable safe
            if (clientId == 0) continue;
            final String name = (map['client_name'] ?? '') as String;
            final int productId =
                int.tryParse('${map['product_id']}') ?? 0; // nullable safe

            // amount peut venir de l'API en String ou en nombre -> on normalise en double
            final dynamic rawAmount = map['amount'];
            final double amount = rawAmount is num
                ? rawAmount.toDouble()
                : double.tryParse('$rawAmount') ?? 0.0;

            // Prix du produit pour calculer le reste à payer
            final double? productPrice = productPrices[productId];
            double remainingForThisDeposit = 0.0;
            if (productPrice != null) {
              remainingForThisDeposit = productPrice - amount;
              if (remainingForThisDeposit < 0) {
                remainingForThisDeposit = 0.0;
              }
            }

            _clientTotals.putIfAbsent(clientId, () {
              return {
                'client': Client(id: clientId, name: name),
                'total': 0.0,
                'remaining': 0.0,
              };
            });
            _clientTotals[clientId]!['total'] =
                (_clientTotals[clientId]!['total'] as double) + amount;
            _clientTotals[clientId]!['remaining'] =
                (_clientTotals[clientId]!['remaining'] as double) +
                    remainingForThisDeposit;
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
      _error = loc.depositsOverviewConnectionError(e.toString());
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
                                    color: Colors.blueGrey[800],
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
      _error = loc.depositsOverviewConnectionError(e.toString());
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
                          final String date =
                              (d['deposit_date'] ?? '') as String;
                          final bool reserved =
                              (d['stock_reserved'] ?? 0) == 1;
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
                              trailing: Text(
                                reserved ? loc.depositReserved : loc.depositOutOfStock,
                                style: TextStyle(
                                  color: reserved
                                      ? Colors.green
                                      : Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(loc.depositsOverviewAddButton),
                          onPressed: () async {
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


