import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/error_utils.dart';
import 'package:intl/intl.dart';

class DepositsHistoryPage extends StatefulWidget {
  const DepositsHistoryPage({Key? key}) : super(key: key);

  @override
  State<DepositsHistoryPage> createState() => _DepositsHistoryPageState();
}

class _DepositsHistoryPageState extends State<DepositsHistoryPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _deposits = [];
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'fr_FR', symbol: '\$', decimalDigits: 2);
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  // Filtres
  bool _showUsedOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchDeposits();
  }

  Future<void> _fetchDeposits() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String url = ApiConstants.depositsHistoryApi;
      if (_showUsedOnly) {
        url += '?used_only=1';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          setState(() {
            _deposits = data['deposits'] ?? [];
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'Erreur lors du chargement des données';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Erreur HTTP: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur de connexion: ${ErrorUtils.getUserFriendlyError(e)}';
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredDeposits {
    if (_searchQuery.isEmpty) {
      return _deposits;
    }
    final query = _searchQuery.toLowerCase();
    return _deposits.where((deposit) {
      final clientName = (deposit['client_name'] ?? '').toString().toLowerCase();
      final productName = (deposit['product_name'] ?? '').toString().toLowerCase();
      return clientName.contains(query) || productName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Dépôts'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _fetchDeposits,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher par client ou produit...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _showUsedOnly,
                      onChanged: (value) {
                        setState(() {
                          _showUsedOnly = value ?? false;
                        });
                        _fetchDeposits();
                      },
                    ),
                    const Text('Afficher uniquement les dépôts utilisés'),
                  ],
                ),
              ],
            ),
          ),
          // Liste des dépôts
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
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
                              _error!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchDeposits,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filteredDeposits.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun dépôt trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchDeposits,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _filteredDeposits.length,
                              itemBuilder: (context, index) {
                                final deposit = _filteredDeposits[index];
                                final isUsed = deposit['sale_id'] != null;
                                final depositDate = deposit['deposit_date'] ?? '';
                                final amount = deposit['amount'] is num
                                    ? (deposit['amount'] as num).toDouble()
                                    : double.tryParse(
                                            deposit['amount'].toString()) ??
                                        0.0;

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  color: isUsed
                                      ? Colors.grey[100]
                                      : Colors.white,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isUsed
                                          ? Colors.green[700]
                                          : Colors.blue[700],
                                      child: Icon(
                                        isUsed
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      deposit['client_name'] ?? 'Client inconnu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: isUsed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Produit: ${deposit['product_name'] ?? 'Produit inconnu'}',
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Date: ${depositDate.isNotEmpty ? _dateFormatter.format(DateTime.parse(depositDate)) : 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (isUsed && deposit['sale_date'] != null)
                                          Text(
                                            'Vente: ${_dateFormatter.format(DateTime.parse(deposit['sale_date']))}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _currencyFormatter.format(amount),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isUsed
                                                ? Colors.grey[600]
                                                : Colors.blue[700],
                                          ),
                                        ),
                                        if (isUsed)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Utilisé',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

