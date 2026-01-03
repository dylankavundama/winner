import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:intl/intl.dart';

class BeneficePage extends StatefulWidget {
  const BeneficePage({Key? key}) : super(key: key);

  @override
  State<BeneficePage> createState() => _BeneficePageState();
}

class _BeneficePageState extends State<BeneficePage> {
  bool isLoading = true;
  String? errorMessage;
  
  double beneficeBrut = 0.0;
  double depenses = 0.0;
  double beneficeExact = 0.0;
  double totalVentes = 0.0;
  List<dynamic> ventes = [];
  
  String? date;
  String? month;
  String? year;

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat _dateInputFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _monthInputFormat = DateFormat('yyyy-MM');
  final DateFormat _yearInputFormat = DateFormat('yyyy');

  // Méthode helper pour convertir en double de manière sécurisée
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _fetchBenefice();
  }
 Future<void> _fetchBenefice() async {
  if (!mounted) return;
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final params = <String, String>{};
    if (date != null) params['date'] = date!;
    if (month != null) params['month'] = month!;
    if (year != null) params['year'] = year!;

    final uri = Uri.parse('${ApiConstants.baseUrl}/benefice_detail.php')
        .replace(queryParameters: params);
    
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        if (mounted) {
          setState(() {
            // Conversion sécurisée des valeurs numériques
            beneficeBrut = _safeDouble(data['benefice_brut']);
            depenses = _safeDouble(data['depenses']);
            beneficeExact = _safeDouble(data['benefice_exact']);
            totalVentes = _safeDouble(data['total_ventes']);
            ventes = data['ventes'] is List ? data['ventes'] : [];
            isLoading = false;
            errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = data['message']?.toString() ?? 'Erreur inconnue';
            isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          errorMessage = 'Erreur serveur (${response.statusCode})';
          isLoading = false;
        });
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        errorMessage = 'Erreur: ${e.toString()}';
        isLoading = false;
      });
    }
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
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
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
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(loc),
                  ),
                ),
    );
  }

  Widget _buildContent(AppLocalizations loc) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtres
          _buildFiltersCard(loc),
          
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
          _buildVentesList(loc),
        ],
    );
  }

  Widget _buildFiltersCard(AppLocalizations loc) {
    return Card(
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
                      text: date ?? '',
                    ),
                    decoration: InputDecoration(
                      labelText: loc.beneficeDayLabel,
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      try {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date != null && date!.isNotEmpty
                              ? _dateInputFormat.parse(date!)
                              : DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            date = _dateInputFormat.format(picked);
                            month = null;
                            year = null;
                          });
                          _fetchBenefice();
                        }
                      } catch (e) {
                        // Ignorer les erreurs de parsing
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: month ?? '',
                    ),
                    decoration: InputDecoration(
                      labelText: loc.beneficeMonthLabel,
                      suffixIcon: const Icon(Icons.calendar_month),
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      try {
                        DateTime initialDate = DateTime.now();
                        if (month != null && month!.isNotEmpty) {
                          try {
                            final parts = month!.split('-');
                            if (parts.length == 2) {
                              initialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                            }
                          } catch (e) {
                            initialDate = DateTime.now();
                          }
                        }
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            month = _monthInputFormat.format(picked);
                            date = null;
                            year = null;
                          });
                          _fetchBenefice();
                        }
                      } catch (e) {
                        // Ignorer les erreurs
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: year ?? '',
                    ),
                    decoration: InputDecoration(
                      labelText: loc.beneficeYearLabel,
                      suffixIcon: const Icon(Icons.event),
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      try {
                        DateTime initialDate = DateTime.now();
                        if (year != null && year!.isNotEmpty) {
                          try {
                            final yearInt = int.parse(year!);
                            if (yearInt >= 2020 && yearInt <= DateTime.now().year) {
                              initialDate = DateTime(yearInt);
                            }
                          } catch (e) {
                            initialDate = DateTime.now();
                          }
                        }
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            year = _yearInputFormat.format(picked);
                            date = null;
                            month = null;
                          });
                          _fetchBenefice();
                        }
                      } catch (e) {
                        // Ignorer les erreurs
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
                      date = null;
                      month = null;
                      year = null;
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
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildVentesList(AppLocalizations loc) {
    return Card(
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
    );
  }

  Widget _buildVenteCard(Map<String, dynamic> vente) {
    // Sécurisation totale des entrées
    final saleId = vente['sale_id']?.toString() ?? '0';
    final saleDate = vente['sale_date']?.toString() ?? '';
    final clientName = vente['client_name']?.toString() ?? 'Client inconnu';
    
    final saleTotal = double.tryParse(vente['sale_total']?.toString() ?? '0') ?? 0.0;
    final benefice = double.tryParse(vente['benefice_vente']?.toString() ?? '0') ?? 0.0;
    
    // Éviter la division par zéro pour le pourcentage
    final pourcentage = saleTotal > 0 ? (benefice / saleTotal) * 100 : 0.0;
    
    DateTime? dateTime;
    try {
      if (saleDate.isNotEmpty) {
        dateTime = DateTime.parse(saleDate);
      }
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
              Expanded(
                child: Row(
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
                    Flexible(
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
          if (dateTime != null) ...[
            const SizedBox(height: 8),
            Text(
              _dateFormat.format(dateTime),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
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
}
