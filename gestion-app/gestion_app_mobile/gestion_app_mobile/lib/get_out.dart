import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/stock.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:gestion_app_mobile/constants.dart';

class StockOutHistoryPage extends StatefulWidget {
  const StockOutHistoryPage({Key? key}) : super(key: key);

  @override
  State<StockOutHistoryPage> createState() => _StockOutHistoryPageState();
}

class _StockOutHistoryPageState extends State<StockOutHistoryPage> {
  List<dynamic> _stockOutRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStockOutRecords();
  }

  // Fetch stock out records from the API
  Future<void> _fetchStockOutRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await http.get(Uri.parse(ApiConstants.stockOutHistoryApi));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _stockOutRecords = data['records'];
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to fetch data.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Sorties',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
        elevation: 4,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewSalePage()),
          );
        },
        tooltip: 'Ajouter un client',
        child: const Icon(Icons.event_repeat_outlined),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : _stockOutRecords.isEmpty
                  ? const Center(child: Text('Aucune sortie de stock trouvée.'))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: _stockOutRecords.length,
                        itemBuilder: (context, index) {
                          final record = _stockOutRecords[index];
                          final formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                              .format(DateTime.parse(record['out_date']));

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.history, color: Colors.blue),
                              title: Text(
                                record['product_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Quantité: ${record['quantity']}'),
                                  Text('Raison: ${record['reason']}'),
                                  // Use client_name if available, otherwise show "Non spécifié"
                                  Text(
                                      'Client: ${record['client_name'] ?? 'Non spécifié'}'),
                                ],
                              ),
                              trailing: Text(
                                formattedDate,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
