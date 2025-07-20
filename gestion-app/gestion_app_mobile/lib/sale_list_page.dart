import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:intl/intl.dart';
import 'package:gestion_app_mobile/detail_sale_page.dart';

class Sale {
  final int id;
  final String clientName;
  final double total;
  final String date;

  Sale({required this.id, required this.clientName, required this.total, required this.date});

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      clientName: json['client_name'] ?? '',
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : double.tryParse(json['total'].toString()) ?? 0.0,
      date: json['sale_date'] ?? '',
    );
  }
}

class SaleListPage extends StatefulWidget {
  const SaleListPage({Key? key}) : super(key: key);

  @override
  State<SaleListPage> createState() => _SaleListPageState();
}

class _SaleListPageState extends State<SaleListPage> {
  List<Sale> sales = [];
  bool isLoading = true;
  String? errorMessage;
  String sortMode = 'date'; // 'date', 'mois', 'annee'

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/sales.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['sales'] is List) {
          setState(() {
            sales = (data['sales'] as List).map((e) => Sale.fromJson(e)).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Erreur lors du chargement des ventes';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Erreur serveur (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
    }
  }

  void _setSortMode(String mode) {
    setState(() {
      sortMode = mode;
    });
  }

  List<Sale> get sortedSales {
    List<Sale> sorted = List.from(sales);
    if (sortMode == 'date') {
      sorted.sort((a, b) {
        final da = DateTime.tryParse(a.date);
        final db = DateTime.tryParse(b.date);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    }
    return sorted;
  }

  Map<String, List<Sale>> get groupedByMonth {
    final Map<String, List<Sale>> map = {};
    for (var sale in sales) {
      final date = DateTime.tryParse(sale.date);
      if (date != null) {
        final key = DateFormat('MMMM yyyy', 'fr_FR').format(date);
        map.putIfAbsent(key, () => []).add(sale);
      } else {
        map.putIfAbsent('Inconnue', () => []).add(sale);
      }
    }
    // Trie les mois par date décroissante
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        try {
          final da = DateFormat('MMMM yyyy', 'fr_FR').parse(a);
          final db = DateFormat('MMMM yyyy', 'fr_FR').parse(b);
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });
    return {for (var k in sortedKeys) k: map[k]!};
  }

  Map<String, List<Sale>> get groupedByYear {
    final Map<String, List<Sale>> map = {};
    for (var sale in sales) {
      final date = DateTime.tryParse(sale.date);
      final key = date != null ? date.year.toString() : 'Inconnue';
      map.putIfAbsent(key, () => []).add(sale);
    }
    // Trie les années par ordre décroissant
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return {for (var k in sortedKeys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Ventes'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _setSortMode,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('Trier par date')),
              const PopupMenuItem(value: 'mois', child: Text('Trier par mois')),
              const PopupMenuItem(value: 'annee', child: Text('Trier par année')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : sales.isEmpty
                  ? const Center(child: Text('Aucune vente trouvée.'))
                  : RefreshIndicator(
                      onRefresh: _fetchSales,
                      child: sortMode == 'date'
                          ? ListView.separated(
                              itemCount: sortedSales.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final sale = sortedSales[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(sale.id.toString()),
                                    backgroundColor: Colors.blueGrey[100],
                                  ),
                                  title: Text('Client : ${sale.clientName}'),
                                  subtitle: Text('Date : ${sale.date}'),
                                  trailing: Text(' 24${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailSalePage(saleId: sale.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : ListView(
                              children: [
                                for (final entry in (sortMode == 'mois' ? groupedByMonth.entries : groupedByYear.entries)) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                    ),
                                  ),
                                  ...entry.value.map((sale) => ListTile(
                                        leading: CircleAvatar(
                                          child: Text(sale.id.toString()),
                                          backgroundColor: Colors.blueGrey[100],
                                        ),
                                        title: Text('Client : ${sale.clientName}'),
                                        subtitle: Text('Date : ${sale.date}'),
                                        trailing: Text(' 24${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetailSalePage(saleId: sale.id),
                                            ),
                                          );
                                        },
                                      )),
                                  const Divider(),
                                ]
                              ],
                            ),
                    ),
    );
  }
} 