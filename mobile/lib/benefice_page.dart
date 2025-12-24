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
  String? errorType; // 'load', 'server', 'connection'
  int? errorCode; // Pour les erreurs serveur
  String? errorDetails; // Détails de l'erreur
  double beneficeBrut = 0;
  double depenses = 0;
  double beneficeExact = 0;
  String date = '';
  String month = '';
  String year = '';

  @override
  void initState() {
    super.initState();
    date = '';
    month = DateFormat('yyyy-MM').format(DateTime.now());
    year = DateFormat('yyyy').format(DateTime.now());
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
      final uri = Uri.parse('${ApiConstants.baseUrl}/benefice.php')
          .replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            beneficeBrut = (data['benefice_brut'] as num).toDouble();
            depenses = (data['depenses'] as num).toDouble();
            beneficeExact = (data['benefice_exact'] as num).toDouble();
            isLoading = false;
          });
        } else {
          setState(() {
            errorType = 'load';
            errorMessage = data['message'];
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
        errorDetails = e.toString();
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
                    child: Text(
                      _getErrorMessage(loc),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildBeneficeContent(),
    );
  }

  Widget _buildBeneficeContent() {
    final loc = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.beneficeCalculationTitle,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: TextEditingController(text: date),
                        decoration: InputDecoration(labelText: loc.beneficeDayLabel),
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
                    const SizedBox(width: 12),
                    Flexible(
                      child: TextField(
                        controller: TextEditingController(text: month),
                        decoration: InputDecoration(labelText: loc.beneficeMonthLabel),
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
                    const SizedBox(width: 12),
                    Flexible(
                      child: TextField(
                        controller: TextEditingController(text: year),
                        decoration: InputDecoration(labelText: loc.beneficeYearLabel),
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
                const SizedBox(height: 24),
                Text(loc.beneficeGrossProfitLabel),
                Text('${beneficeBrut.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                const SizedBox(height: 16),
                Text(loc.beneficeExpensesLabel),
                Text('${depenses.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
                const SizedBox(height: 16),
                Text(loc.beneficeExactProfitLabel),
                Text('${beneficeExact.toStringAsFixed(2)} \$',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
          ),
        ),
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
