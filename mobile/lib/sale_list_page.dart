import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';
import 'package:intl/intl.dart';
import 'package:gestion_app_mobile/detail_sale_page.dart';

class Sale {
  final int id;
  final String clientName;
  final double total;
  final String date;

  final String status;
  Sale(
      {required this.id,
      required this.clientName,
      required this.total,
      required this.date,
      required this.status});

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      clientName: json['client_name'] ?? '',
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : double.tryParse(json['total'].toString()) ?? 0.0,
      date: json['sale_date'] ?? '',
      status: json['status'] ?? 'payée',
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
      final response =
          await http.get(Uri.parse('${ApiConstants.baseUrl}/sales.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['sales'] is List) {
          setState(() {
            sales =
                (data['sales'] as List).map((e) => Sale.fromJson(e)).toList();
            isLoading = false;
          });
        } else {
          final loc = AppLocalizations.of(context);
          setState(() {
            errorMessage = data['message'] ?? loc.saleListLoadError;
            isLoading = false;
          });
        }
      } else {
        final loc = AppLocalizations.of(context);
        setState(() {
          errorMessage = loc.saleListServerError(response.statusCode);
          isLoading = false;
        });
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      setState(() {
        errorMessage =
            loc.saleListConnectionError(ErrorUtils.getUserFriendlyError(e));
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

  Map<String, List<Sale>> groupedByMonth(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final Map<String, List<Sale>> map = {};
    final locale = loc.locale.languageCode == 'fr' ? 'fr_FR' : 'en_US';
    for (var sale in sales) {
      final date = DateTime.tryParse(sale.date);
      if (date != null) {
        final key = DateFormat('MMMM yyyy', locale).format(date);
        map.putIfAbsent(key, () => []).add(sale);
      } else {
        map.putIfAbsent(loc.saleListUnknown, () => []).add(sale);
      }
    }
    // Trie les mois par date décroissante
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        try {
          final da = DateFormat('MMMM yyyy', locale).parse(a);
          final db = DateFormat('MMMM yyyy', locale).parse(b);
          return db.compareTo(da);
        } catch (_) {
          return 0;
        }
      });
    return {for (var k in sortedKeys) k: map[k]!};
  }

  Map<String, List<Sale>> groupedByYear(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final Map<String, List<Sale>> map = {};
    for (var sale in sales) {
      final date = DateTime.tryParse(sale.date);
      final key = date != null ? date.year.toString() : loc.saleListUnknown;
      map.putIfAbsent(key, () => []).add(sale);
    }
    // Trie les années par ordre décroissant
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (var k in sortedKeys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.saleListTitle),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _setSortMode,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'date', child: Text(loc.saleListSortByDate)),
              PopupMenuItem(
                  value: 'mois', child: Text(loc.saleListSortByMonth)),
              PopupMenuItem(
                  value: 'annee', child: Text(loc.saleListSortByYear)),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : sales.isEmpty
                  ? Center(
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
                            loc.saleListNoSales,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.saleListEmptyHint,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchSales,
                      child: sortMode == 'date'
                          ? ListView.separated(
                              itemCount: sortedSales.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final sale = sortedSales[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(sale.id.toString()),
                                    backgroundColor: Colors.blueGrey[100],
                                  ),
                                  title: Text(
                                    loc.saleListClientLabel(sale.clientName),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle:
                                      Text(loc.saleListDateLabel(sale.date)),
                                  trailing: SizedBox(
                                    width: 120,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${sale.total.toStringAsFixed(2)} \$',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          sale.status.toLowerCase() == 'payée'
                                              ? Icons.check_circle
                                              : Icons.error_outline,
                                          color: sale.status.toLowerCase() ==
                                                  'payée'
                                              ? Colors.green
                                              : Colors.red,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailSalePage(saleId: sale.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : ListView(
                              children: [
                                for (final entry in (sortMode == 'mois'
                                    ? groupedByMonth(context).entries
                                    : groupedByYear(context).entries)) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey),
                                    ),
                                  ),
                                  ...entry.value.map((sale) => ListTile(
                                        leading: CircleAvatar(
                                          child: Text(sale.id.toString()),
                                          backgroundColor: Colors.blueGrey[100],
                                        ),
                                        title: Text(
                                          loc.saleListClientLabel(
                                              sale.clientName),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                            loc.saleListDateLabel(sale.date)),
                                        trailing: SizedBox(
                                          width: 80,
                                          child: Text(
                                            '${sale.total.toStringAsFixed(2)} \$',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailSalePage(
                                                      saleId: sale.id),
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
