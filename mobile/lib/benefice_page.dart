import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';
import 'package:intl/intl.dart';

class BeneficePage extends StatefulWidget {
  const BeneficePage({Key? key}) : super(key: key);

  @override
  State<BeneficePage> createState() => _BeneficePageState();
}

class _BeneficePageState extends State<BeneficePage> {
  bool isLoading = true;
  String? errorMessage;
  String? errorType;
  int? errorCode;
  String? errorDetails;
  
  double beneficeBrut = 0;
  double depenses = 0;
  double beneficeExact = 0;
  double totalVentes = 0;
  List<dynamic> ventes = [];
  
  String date = '';
  String month = '';
  String year = '';

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchBenefice();
  }

  Future<void> _fetchBenefice() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      errorType = null;
      errorCode = null;
      errorDetails = null;
    });
    
    try {
      final params = <String, String>{};
      if (date.isNotEmpty) params['date'] = date;
      if (month.isNotEmpty) params['month'] = month;
      if (year.isNotEmpty) params['year'] = year;
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/benefice_detail.php')
          .replace(queryParameters: params);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            beneficeBrut = (data['benefice_brut'] as num?)?.toDouble() ?? 0.0;
            depenses = (data['depenses'] as num?)?.toDouble() ?? 0.0;
            beneficeExact = (data['benefice_exact'] as num?)?.toDouble() ?? 0.0;
            totalVentes = (data['total_ventes'] as num?)?.toDouble() ?? 0.0;
            ventes = data['ventes'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorType = 'load';
            errorMessage = data['message'] ?? 'Erreur lors du chargement';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorType = 'server';
          errorCode = response.statusCode;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorType = 'connection';
        errorDetails = ErrorUtils.getUserFriendlyError(e);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.beneficeTitle),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorType != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _getErrorMessage(loc),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchBenefice,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchBenefice,
                  child: _buildBeneficeContent(),
                ),
    );
  }

  Widget _buildBeneficeContent() {
    final loc = AppLocalizations.of(context);
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
                    'Filtres',
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
                            text: date.isNotEmpty
                                ? DateFormat('yyyy-MM-dd').format(DateTime.parse(date))
                                : '',
                          ),
                          decoration: InputDecoration(
                            labelText: loc.beneficeDayLabel,
                            suffixIcon: const Icon(Icons.calendar_today),
                            border: const OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date.isNotEmpty
                                  ? DateTime.parse(date)
                                  : DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                date = DateFormat('yyyy-MM-dd').format(picked);
                                month = '';
                                year = '';
                              });
                              _fetchBenefice();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(
                            text: month.isNotEmpty ? month : '',
                          ),
                          decoration: InputDecoration(
                            labelText: loc.beneficeMonthLabel,
                            suffixIcon: const Icon(Icons.calendar_month),
                            border: const OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: month.isNotEmpty
                                  ? DateTime.parse(month + '-01')
                                  : DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                month = DateFormat('yyyy-MM').format(picked);
                                date = '';
                                year = '';
                              });
                              _fetchBenefice();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: year),
                          decoration: InputDecoration(
                            labelText: loc.beneficeYearLabel,
                            suffixIcon: const Icon(Icons.event),
                            border: const OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: year.isNotEmpty
                                  ? DateTime(int.parse(year))
                                  : DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                year = DateFormat('yyyy').format(picked);
                                date = '';
                                month = '';
                              });
                              _fetchBenefice();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            date = '';
                            month = '';
                            year = '';
                          });
                          _fetchBenefice();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Cartes de résumé
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total ventes',
                  totalVentes,
                  Colors.blue,
                  Icons.shopping_cart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Dépenses',
                  depenses,
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Bénéfice brut',
                  beneficeBrut,
                  Colors.purple,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Bénéfice net',
                  beneficeExact,
                  Colors.green,
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Liste des ventes
          Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                        'Détail des ventes (${ventes.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                if (ventes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune vente trouvée',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...ventes.map((vente) => _buildVenteCard(vente)),
                  
                  // Ligne de total
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[800],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFormat.format(totalVentes),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(beneficeBrut),
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenteCard(Map<String, dynamic> vente) {
    final saleId = vente['sale_id'] ?? 0;
    final saleDate = vente['sale_date'] ?? '';
    final clientName = vente['client_name'] ?? 'N/A';
    final saleTotal = (vente['sale_total'] as num?)?.toDouble() ?? 0.0;
    final benefice = (vente['benefice_vente'] as num?)?.toDouble() ?? 0.0;
    final pourcentage = saleTotal > 0 ? (benefice / saleTotal) * 100 : 0.0;
    
    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(saleDate);
    } catch (e) {
      dateTime = null;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$saleId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: benefice >= 0 ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currencyFormat.format(benefice),
                  style: TextStyle(
                    color: benefice >= 0 ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dateTime != null)
            Text(
              _dateFormat.format(dateTime),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Montant: ${_currencyFormat.format(saleTotal)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pourcentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(AppLocalizations loc) {
    switch (errorType) {
      case 'load':
        return errorMessage ?? loc.beneficeLoadError;
      case 'server':
        return loc.beneficeServerError(errorCode ?? 0);
      case 'connection':
        return loc.beneficeConnectionError(errorDetails ?? '');
      default:
        return errorMessage ?? loc.beneficeLoadError;
    }
  }
}
