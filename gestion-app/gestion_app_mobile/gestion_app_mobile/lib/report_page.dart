import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> sales = [];
  List<dynamic> lowStock = [];
  List<dynamic> topClients = [];
  List<dynamic> unpaid = [];
  String start = DateFormat('yyyy-MM-01').format(DateTime.now());
  String end = DateFormat('yyyy-MM-dd').format(DateTime.now());

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchReports();
  }

  Future<void> _fetchReports({String? customStart, String? customEnd}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final url =
          '${ApiConstants.baseUrl}/reports.php?start=${customStart ?? start}&end=${customEnd ?? end}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            sales = data['sales'] ?? [];
            lowStock = data['low_stock'] ?? [];
            topClients = data['top_clients'] ?? [];
            unpaid = data['unpaid'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                data['message'] ?? 'Erreur lors du chargement des rapports';
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Ventes',
            ),
            Tab(text: 'Stock faible'),
            Tab(text: 'Top clients'),
            Tab(text: 'Impayées'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSalesTab(),
                    _buildLowStockTable(),
                    _buildTopClientsTable(),
                    _buildUnpaidTable(),
                  ],
                ),
    );
  }

  Widget _buildSalesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: start),
                  decoration: const InputDecoration(labelText: 'Du'),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(start) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() =>
                          start = DateFormat('yyyy-MM-dd').format(picked));
                      _fetchReports();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: end),
                  decoration: const InputDecoration(labelText: 'Au'),
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(end) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(
                          () => end = DateFormat('yyyy-MM-dd').format(picked));
                      _fetchReports();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _fetchReports(),
                child: const Text('Filtrer'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildSalesTable()),
      ],
    );
  }

  Widget _buildSalesTable() {
    return Card(
      child: sales.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune vente trouvée.'),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Total')),
                ],
                rows: sales
                    .map<DataRow>((s) => DataRow(cells: [
                          DataCell(Text(s['id'].toString())),
                          DataCell(Text(s['client'] ?? '')),
                          DataCell(Text(s['sale_date'] ?? '')),
                          DataCell(Text('${s['total']} \$')),
                        ]))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildLowStockTable() {
    return Card(
      child: lowStock.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun produit en stock faible.'),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Quantité')),
                  DataColumn(label: Text('Prix')),
                ],
                rows: lowStock
                    .map<DataRow>((p) => DataRow(cells: [
                          DataCell(Text(p['id'].toString())),
                          DataCell(Text(p['name'] ?? '')),
                          DataCell(Text(p['quantity'].toString())),
                          DataCell(Text('${p['price']} \$')),
                        ]))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildTopClientsTable() {
    return Card(
      child: topClients.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun client trouvé.'),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Total achats')),
                ],
                rows: topClients
                    .map<DataRow>((c) => DataRow(cells: [
                          DataCell(Text(c['name'] ?? '')),
                          DataCell(Text('${c['total_achats']} \$')),
                        ]))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildUnpaidTable() {
    return Card(
      child: unpaid.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune facture impayée.'),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Montant')),
                ],
                rows: unpaid
                    .map<DataRow>((f) => DataRow(cells: [
                          DataCell(Text(f['id'].toString())),
                          DataCell(Text(f['client'] ?? '')),
                          DataCell(Text(f['invoice_date'] ?? '')),
                          DataCell(Text('${f['amount']} \$')),
                        ]))
                    .toList(),
              ),
            ),
    );
  }
}
