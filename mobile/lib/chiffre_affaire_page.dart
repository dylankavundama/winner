import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';
import 'package:intl/intl.dart';

class ChiffreAffairePage extends StatefulWidget {
  const ChiffreAffairePage({Key? key}) : super(key: key);

  @override
  State<ChiffreAffairePage> createState() => _ChiffreAffairePageState();
}

class _ChiffreAffairePageState extends State<ChiffreAffairePage> {
  bool isLoading = true;
  String? errorMessage;
  
  double totalCa = 0.0;
  int salesCount = 0;
  int productsSold = 0;
  double avgSaleAmount = 0.0;
  double totalStockValue = 0.0;
  
  List<dynamic> detailsByPeriod = [];
  List<dynamic> detailsByProduct = [];
  
  String? startDate;
  String? endDate;
  String groupBy = 'all'; // 'all', 'day', 'month', 'year', 'product'
  
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    // Par défaut, afficher le mois en cours
    final now = DateTime.now();
    startDate = DateFormat('yyyy-MM-01').format(now);
    endDate = DateFormat('yyyy-MM-dd').format(now);
    _fetchChiffreAffaire();
  }

  Future<void> _fetchChiffreAffaire() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final params = <String, String>{};
      if (startDate != null) params['start_date'] = startDate!;
      if (endDate != null) params['end_date'] = endDate!;
      if (groupBy != 'all') params['group_by'] = groupBy;
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/chiffre_affaire.php')
          .replace(queryParameters: params);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            totalCa = (data['total_ca'] as num?)?.toDouble() ?? 0.0;
            final stats = data['stats'] ?? {};
            salesCount = stats['total_sales'] ?? 0;
            productsSold = stats['total_products'] ?? 0;
            avgSaleAmount = (stats['avg_sale_amount'] as num?)?.toDouble() ?? 0.0;
            totalStockValue = (data['total_stock_value'] as num?)?.toDouble() ?? 0.0;
            detailsByPeriod = data['by_period'] ?? [];
            detailsByProduct = data['by_product'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Erreur lors du chargement';
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
        errorMessage = 'Erreur de connexion: ${ErrorUtils.getUserFriendlyError(e)}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.chiffreAffaireTitle),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchChiffreAffaire,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchChiffreAffaire,
                  child: _buildContent(loc),
                ),
    );
  }

  Widget _buildContent(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtres
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.chiffreAffaireFilters,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(
                            text: startDate ?? '',
                          ),
                          decoration: InputDecoration(
                            labelText: loc.chiffreAffaireStartDate,
                            suffixIcon: const Icon(Icons.calendar_today),
                            border: const OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate != null
                                  ? DateTime.parse(startDate!)
                                  : DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                startDate = _dateFormat.format(picked);
                              });
                              _fetchChiffreAffaire();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(
                            text: endDate ?? '',
                          ),
                          decoration: InputDecoration(
                            labelText: loc.chiffreAffaireEndDate,
                            suffixIcon: const Icon(Icons.calendar_today),
                            border: const OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate != null
                                  ? DateTime.parse(endDate!)
                                  : DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                endDate = _dateFormat.format(picked);
                              });
                              _fetchChiffreAffaire();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: groupBy,
                    decoration: InputDecoration(
                      labelText: loc.chiffreAffaireGroupBy,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(loc.chiffreAffaireGroupByAll)),
                      DropdownMenuItem(value: 'day', child: Text(loc.chiffreAffaireGroupByDay)),
                      DropdownMenuItem(value: 'month', child: Text(loc.chiffreAffaireGroupByMonth)),
                      DropdownMenuItem(value: 'year', child: Text(loc.chiffreAffaireGroupByYear)),
                      DropdownMenuItem(value: 'product', child: Text(loc.chiffreAffaireGroupByProduct)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          groupBy = value;
                        });
                        _fetchChiffreAffaire();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            startDate = null;
                            endDate = null;
                            groupBy = 'all';
                          });
                          _fetchChiffreAffaire();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(loc.chiffreAffaireReset),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Carte du total CA
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.chiffreAffaireTotal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currencyFormat.format(totalCa),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  loc.chiffreAffaireSalesCount,
                  salesCount.toString(),
                  Colors.blue,
                  Icons.shopping_cart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  loc.chiffreAffaireProductsSold,
                  productsSold.toString(),
                  Colors.green,
                  Icons.inventory,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  loc.chiffreAffaireAvgSale,
                  _currencyFormat.format(avgSaleAmount),
                  Colors.orange,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  loc.chiffreAffaireTotalStock,
                  _currencyFormat.format(totalStockValue),
                  Colors.indigo,
                  Icons.inventory_2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Détails par période
          if (detailsByPeriod.isNotEmpty && (groupBy == 'day' || groupBy == 'month' || groupBy == 'year'))
            Card(
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      loc.chiffreAffaireDetailsByPeriod,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                  ...detailsByPeriod.map((detail) => _buildDetailRow(
                    detail['period']?.toString() ?? '',
                    _currencyFormat.format((detail['ca'] as num?)?.toDouble() ?? 0.0),
                    '',
                    '',
                  )),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Détails par produit
          if (detailsByProduct.isNotEmpty && groupBy == 'product')
            Card(
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      loc.chiffreAffaireDetailsByProduct,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                  ...detailsByProduct.map((detail) => _buildProductDetailRow(
                    detail['product_name'] ?? '',
                    '${detail['total_quantity'] ?? 0}',
                    _currencyFormat.format((detail['avg_price'] as num?)?.toDouble() ?? 0.0),
                    _currencyFormat.format((detail['total_ca'] as num?)?.toDouble() ?? 0.0),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String period, String ca, String sales, String products) {
    return ListTile(
      title: Text(
        period,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        ca,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.purple,
        ),
      ),
    );
  }

  Widget _buildProductDetailRow(String product, String quantity, String avgPrice, String totalCa) {
    return ListTile(
      title: Text(
        product,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('Qté: $quantity | Prix moy: $avgPrice'),
      trailing: Text(
        totalCa,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.purple,
        ),
      ),
    );
  }
}

