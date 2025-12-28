import 'package:flutter/material.dart';

import 'package:gestion_app_mobile/stock_add_out.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/error_utils.dart';

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

  // Fonction pour mettre à jour le statut de paiement
  Future<void> _updatePaymentStatus(int recordId, int newStatus) async {
    final url =
        Uri.parse('${ApiConstants.updatePaymentStatusApi}?id=$recordId');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'paid_status': newStatus}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Mettre à jour l'état local de la liste sans tout recharger
        setState(() {
          final index =
              _stockOutRecords.indexWhere((record) => record['id'] == recordId);
          if (index != -1) {
            _stockOutRecords[index]['paid_status'] = newStatus;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour avec succès!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  data['message'] ?? 'Échec de la mise à jour du statut.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: ${ErrorUtils.getUserFriendlyError(e)}')),
      );
    }
  }

  // Fonction pour récupérer l'historique des sorties de stock
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
        _errorMessage = 'Connection error: ${ErrorUtils.getUserFriendlyError(e)}';
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
        title: const Text('Sorties de Stock',
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune sortie de stock trouvée',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Les sorties de stock apparaîtront ici',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: _stockOutRecords.length,
                        itemBuilder: (context, index) {
                          final record = _stockOutRecords[index];
                          final formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                              .format(DateTime.parse(record['out_date']));

                          // Déterminer le statut et la couleur
                          final isPaid = record['paid_status'] == 1;
                          final statusText = isPaid ? 'Payé' : 'Impayé';
                          final statusColor =
                              isPaid ? Colors.green : Colors.red;

                          return Card(
                            elevation: 3,
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
                                 
                                  Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child:
                                        Text('Quantité: ${record['quantity']}'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: Text(
                                        'Client: ${record['client_name'] ?? 'Non spécifié'}'),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: Text(
                                      formattedDate,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isPaid
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: statusColor,
                                    ),
                                    onPressed: () {
                                      _updatePaymentStatus(
                                          record['id'], isPaid ? 0 : 1);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
