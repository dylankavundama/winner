import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/deposit_page.dart';
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

  // clientId -> {client: Client, total: double}
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
            final num rawAmount = map['amount'] as num? ?? 0;
            final double amount = rawAmount.toDouble();
            _clientTotals.putIfAbsent(clientId, () {
              return {
                'client': Client(id: clientId, name: name),
                'total': 0.0,
              };
            });
            _clientTotals[clientId]!['total'] =
                (_clientTotals[clientId]!['total'] as double) + amount;
          }
        } else {
          _error = data['message'] ?? 'Erreur lors du chargement des dépôts.';
        }
      } else {
        _error = 'Erreur serveur (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Erreur de connexion : $e';
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
    final entries = _clientTotals.entries.toList()
      ..sort((a, b) =>
          (b.value['total'] as double).compareTo(a.value['total'] as double));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposits'),
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
                                    'Aucun deposit enregistré',
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
                              subtitle: Text(
                                'Total deposits : ${_currencyFormatter.format(total)}',
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
            final num rawAmount = map['amount'] as num? ?? 0;
            sum += rawAmount.toDouble();
            list.add(map);
          }
          setState(() {
            _history = list;
            _total = sum;
          });
        } else {
          _error = data['message'] ?? 'Erreur lors du chargement.';
        }
      } else {
        _error = 'Erreur serveur (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Erreur de connexion : $e';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Deposits - ${widget.client.name}'),
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
                          title: const Text('Total deposits'),
                          subtitle: Text(_currencyFormatter.format(_total)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Text(
                              'Aucun deposit pour ce client.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        ..._history.map((d) {
                          final num rawAmount = d['amount'] as num? ?? 0;
                          final double amount = rawAmount.toDouble();
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
                                reserved ? 'Réservé' : 'Hors stock',
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
        tooltip: 'Ajouter un deposit',
        child: const Icon(Icons.add),
      ),
    );
  }
}


