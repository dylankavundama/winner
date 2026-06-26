import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/error_utils.dart';

class DettesPage extends StatefulWidget {
  const DettesPage({Key? key}) : super(key: key);

  @override
  State<DettesPage> createState() => _DettesPageState();
}

class _DettesPageState extends State<DettesPage> {
  double totalDette = 0.0;
  List<dynamic> clients = [];
  List<dynamic> details = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDettes();
  }

  Future<void> _fetchDettes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse(ApiConstants.dettesApi));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            totalDette = (data['total_dette'] is num)
                ? (data['total_dette'] as num).toDouble()
                : 0.0;
            clients = data['clients'] ?? [];
            details = data['details'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                data['message'] ?? "Erreur lors du chargement des dettes";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Erreur serveur : ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            "Erreur de connexion : ${ErrorUtils.getUserFriendlyError(e)}";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestion des Dettes"),
          backgroundColor: Colors.blueGrey[800],
          bottom: const TabBar(
            tabs: [
              Tab(
                  text: "Par Client",
                  icon: Icon(Icons.people, color: Colors.white)),
              Tab(
                  text: "Détails Factures",
                  icon: Icon(Icons.receipt_long, color: Colors.white)),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _fetchDettes,
                            child: const Text("Réessayer"))
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildClientsList(),
                            _buildDetailsList(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border(bottom: BorderSide(color: Colors.red[100]!)),
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL DES DETTES",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            "${totalDette.toStringAsFixed(2)} \$",
            style: const TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    if (clients.isEmpty) {
      return const Center(child: Text("Aucune dette client."));
    }
    return RefreshIndicator(
      onRefresh: _fetchDettes,
      child: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange[100],
                child: const Icon(Icons.person, color: Colors.orange),
              ),
              title: Text(client['client_name'] ?? "Inconnu",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${client['nb_factures']} facture(s) impayée(s)"),
              trailing: Text(
                "${double.parse(client['total_dette'].toString()).toStringAsFixed(2)} \$",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsList() {
    if (details.isEmpty) {
      return const Center(child: Text("Aucune facture impayée."));
    }
    return RefreshIndicator(
      onRefresh: _fetchDettes,
      child: ListView.builder(
        itemCount: details.length,
        itemBuilder: (context, index) {
          final fact = details[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red[100],
                child: const Icon(Icons.receipt, color: Colors.red),
              ),
              title: Text(fact['client_name'] ?? "Inconnu"),
              subtitle:
                  Text("Vente #${fact['sale_id']} du ${fact['sale_date']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${double.parse(fact['amount'].toString()).toStringAsFixed(2)} \$",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    onPressed: () => _markAsPaid(fact['invoice_id']),
                    tooltip: "Marquer comme payée",
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAsPaid(dynamic invoiceId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/update_invoice_status.php'),
        body: {
          'id': invoiceId.toString(),
          'status': 'payée',
        },
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        _fetchDettes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Facture marquée comme payée.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(data['message'] ?? "Erreur lors de la mise à jour.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }
}
