import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'facture_page.dart';

class Invoice {
  final int id;
  final String clientName;
  final String saleDate;
  final double total;
  final String status;

  Invoice({required this.id, required this.clientName, required this.saleDate, required this.total, required this.status});

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      clientName: json['client_name'] ?? '',
      saleDate: json['sale_date'] ?? '',
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : double.tryParse(json['total'].toString()) ?? 0.0,
      status: json['status'] ?? '',
    );
  }
}

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({Key? key}) : super(key: key);

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Invoice> invoices = [];
  bool isLoading = true;
  String? errorMessage;
  String sortMode = 'date_desc'; // 'date_desc', 'date_asc', 'payee', 'non_payee'

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/invoices.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['invoices'] is List) {
          setState(() {
            invoices = (data['invoices'] as List).map((e) => Invoice.fromJson(e)).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Erreur lors du chargement des factures';
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

  List<Invoice> get sortedInvoices {
    List<Invoice> sorted = List.from(invoices);
    if (sortMode == 'date_desc') {
      sorted.sort((a, b) {
        final da = DateTime.tryParse(a.saleDate);
        final db = DateTime.tryParse(b.saleDate);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    } else if (sortMode == 'date_asc') {
      sorted.sort((a, b) {
        final da = DateTime.tryParse(a.saleDate);
        final db = DateTime.tryParse(b.saleDate);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    } else if (sortMode == 'payee') {
      sorted = sorted.where((i) => i.status.toLowerCase() == 'payée').toList();
    } else if (sortMode == 'non_payee') {
      sorted = sorted.where((i) => i.status.toLowerCase() != 'payée').toList();
    }
    return sorted;
  }

  void _setSortMode(String mode) {
    setState(() {
      sortMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Factures'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _setSortMode,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date_desc', child: Text('Date décroissante')),
              const PopupMenuItem(value: 'date_asc', child: Text('Date croissante')),
              const PopupMenuItem(value: 'payee', child: Text('Factures payées')),
              const PopupMenuItem(value: 'non_payee', child: Text('Factures non payées')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : invoices.isEmpty
                  ? const Center(child: Text('Aucune facture trouvée.'))
                  : RefreshIndicator(
                      onRefresh: _fetchInvoices,
                      child: ListView.separated(
                        itemCount: sortedInvoices.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final invoice = sortedInvoices[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(invoice.id.toString()),
                              backgroundColor: Colors.blueGrey[100],
                            ),
                            title: Text('Client : ${invoice.clientName}'),
                            subtitle: Text('Date : ${invoice.saleDate}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${invoice.total.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(invoice.status, style: TextStyle(color: invoice.status.toLowerCase() == 'payée' ? Colors.green : Colors.orange)),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FacturePage(invoiceId: invoice.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
} 