import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
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
          final loc = AppLocalizations.of(context);
          setState(() {
            errorMessage =
                data['message'] ?? loc.reportLoadError;
            isLoading = false;
          });
        }
      } else {
        final loc = AppLocalizations.of(context);
        setState(() {
          errorMessage = loc.reportServerError(response.statusCode);
          isLoading = false;
        });
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      setState(() {
        errorMessage = loc.reportConnectionError(e.toString());
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
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: loc.reportTabSales,
            ),
            Tab(text: loc.reportTabLowStock),
            Tab(text: loc.reportTabTopClients),
            Tab(text: loc.reportTabUnpaid),
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
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: start),
                  decoration: InputDecoration(labelText: loc.reportDateFrom),
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
                  decoration: InputDecoration(labelText: loc.reportDateTo),
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
                child: Text(loc.reportFilterButton),
              ),
            ],
          ),
        ),
        Expanded(child: _buildSalesTable()),
      ],
    );
  }

  Widget _buildSalesTable() {
    final loc = AppLocalizations.of(context);
    return Card(
      child: sales.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
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
                      loc.reportNoSales,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.reportNoSalesPeriod,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(loc.reportSalesColumnId)),
                  DataColumn(label: Text(loc.reportSalesColumnClient)),
                  DataColumn(label: Text(loc.reportSalesColumnDate)),
                  DataColumn(label: Text(loc.reportSalesColumnTotal)),
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
    final loc = AppLocalizations.of(context);
    return Card(
      child: lowStock.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.reportNoLowStock,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.reportAllStockSufficient,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(loc.reportLowStockColumnId)),
                  DataColumn(label: Text(loc.reportLowStockColumnName)),
                  DataColumn(label: Text(loc.reportLowStockColumnQuantity)),
                  DataColumn(label: Text(loc.reportLowStockColumnPrice)),
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
    final loc = AppLocalizations.of(context);
    return Card(
      child: topClients.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.reportNoClients,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.reportNoClientsPeriod,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(loc.reportTopClientsColumnClient)),
                  DataColumn(label: Text(loc.reportTopClientsColumnTotal)),
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
    final loc = AppLocalizations.of(context);
    return Card(
      child: unpaid.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.reportNoUnpaid,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.reportAllInvoicesPaid,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(loc.reportUnpaidColumnId)),
                  DataColumn(label: Text(loc.reportUnpaidColumnClient)),
                  DataColumn(label: Text(loc.reportUnpaidColumnDate)),
                  DataColumn(label: Text(loc.reportUnpaidColumnAmount)),
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
