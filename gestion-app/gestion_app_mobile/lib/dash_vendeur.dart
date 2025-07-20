import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/invoice_list_page.dart';
import 'package:gestion_app_mobile/main.dart';
import 'package:gestion_app_mobile/product_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gestion_app_mobile/client.dart';
import 'sortie_page.dart';
import 'package:gestion_app_mobile/detail_sale_page.dart';
import 'package:intl/intl.dart';

class DashboardPageVendeur extends StatefulWidget {
  const DashboardPageVendeur({Key? key}) : super(key: key);

  @override
  State<DashboardPageVendeur> createState() => _DashboardPageVendeurState();
}

class _DashboardPageVendeurState extends State<DashboardPageVendeur> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> ventes = [];
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchVentes();
  }

  Future<void> _fetchVentes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response =
          await http.get(Uri.parse(ApiConstants.baseUrl + '/sales.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            ventes = data['sales'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                data['message'] ?? 'Erreur lors du chargement des ventes';
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

  void _goToNouvelleVente() {
    Navigator.pushNamed(context, '/vente');
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phpSessionCookie');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  List<dynamic> get sortedVentes {
    List<dynamic> sorted = List.from(ventes);
    sorted.sort((a, b) {
      final da = DateTime.tryParse(a['sale_date'] ?? '');
      final db = DateTime.tryParse(b['sale_date'] ?? '');
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da); // décroissant
    });
    return sorted;
  }

  List<dynamic> get filteredVentes {
    if (selectedDate == null) return sortedVentes;
    final String selectedStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    return sortedVentes.where((v) {
      final saleDate = v['sale_date']?.substring(0, 10);
      return saleDate == selectedStr;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Vendeur'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filtrer par date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Réinitialiser le filtre',
              onPressed: () {
                setState(() {
                  selectedDate = null;
                });
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardPageVendeur()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Ventes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardPageVendeur()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Factures'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvoiceListPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clients'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Produits'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Sorties'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SortiePage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Déconnexion',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : RefreshIndicator(
                  onRefresh: _fetchVentes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredVentes.length,
                    itemBuilder: (context, index) {
                      final vente = filteredVentes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.shopping_bag),
                          title: Text(
                              'Vente #${vente['id']} - ${vente['client_name'] ?? ''}'),
                          subtitle: Text(
                              'Montant: ${vente['total']}\nDate: ${vente['sale_date']}'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailSalePage(saleId: vente['id']),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToNouvelleVente,
        child: const Icon(Icons.add),
        tooltip: 'Nouvelle vente',
      ),
    );
  }
}
