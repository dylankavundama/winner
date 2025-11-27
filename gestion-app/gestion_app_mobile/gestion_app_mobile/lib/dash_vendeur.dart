import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/get_out.dart';
import 'package:gestion_app_mobile/invoice_list_page.dart';
import 'package:gestion_app_mobile/main.dart';
import 'package:gestion_app_mobile/product_page.dart';

import 'package:gestion_app_mobile/vente_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gestion_app_mobile/client.dart';
import 'sortie_page.dart';
import 'package:gestion_app_mobile/detail_sale_page.dart';
import 'package:intl/intl.dart';

class DashboardPageVendeur extends StatefulWidget {
  final String loggedInUsername;

  const DashboardPageVendeur({Key? key, required this.loggedInUsername})
      : super(key: key);

  @override
  State<DashboardPageVendeur> createState() => _DashboardPageVendeurState();
}

class _DashboardPageVendeurState extends State<DashboardPageVendeur> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> ventes = [];
  DateTime? selectedDate;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  int _lastVenteCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchVentes();
    // Actualisation automatique toutes les 30 secondes
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Actualisation automatique toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isRefreshing) {
        _fetchVentes(silent: true);
      }
    });
  }

  Future<void> _fetchVentes({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else {
      _isRefreshing = true;
    }
    
    try {
      final response =
          await http.get(Uri.parse(ApiConstants.baseUrl + '/sales.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
          if (data['success'] == true) {
            if (mounted) {
              setState(() {
                ventes = data['sales'] ?? [];
                isLoading = false;
                _isRefreshing = false;
                // Initialiser le compteur au premier chargement
                if (_lastVenteCount == 0) {
                  _lastVenteCount = ventes.length;
                }
              });
            
            // Afficher une notification discrète seulement si le nombre de ventes a changé
            if (silent && ventes.length != _lastVenteCount) {
              final previousCount = _lastVenteCount;
              _lastVenteCount = ventes.length;
              if (mounted && previousCount > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.refresh, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ventes.length > previousCount
                                ? 'Nouvelle vente enregistrée !'
                                : 'Données mises à jour',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(8),
                  ),
                );
              }
            } else if (!silent) {
              // Mettre à jour le compteur lors d'un refresh manuel
              _lastVenteCount = ventes.length;
            }
          }
        } else {
          if (mounted) {
            setState(() {
              errorMessage =
                  data['message'] ?? 'Erreur lors du chargement des ventes';
              isLoading = false;
              _isRefreshing = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Erreur serveur (${response.statusCode})';
            isLoading = false;
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erreur de connexion: $e';
          isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phpSessionCookie');
    await prefs.remove('loggedInUsername');
    await prefs.remove('user_role');
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
      return db.compareTo(da);
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
          // Indicateur d'actualisation automatique
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => _fetchVentes(),
          ),
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
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueGrey),
              accountName: Text(widget.loggedInUsername,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              accountEmail: null,
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blueGrey, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardPageVendeur(
                        loggedInUsername: widget.loggedInUsername),
                  ),
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
                    builder: (context) => DashboardPageVendeur(
                        loggedInUsername: widget.loggedInUsername),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Factures'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InvoiceListPage(),
                  ),
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
            // ListTile(
            //   leading: const Icon(Icons.money_off),
            //   title: const Text('Sorties'),
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const SortiePage()),
            //     );
            //   },
            // ),

            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Sorties'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SortiePage(
                          loggedInUsername: widget.loggedInUsername)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.approval),
              title: const Text('Sortie Stock'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StockOutHistoryPage()),
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
                  child: filteredVentes.isEmpty
                      ? Center(
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
                                selectedDate == null
                                    ? 'Aucune vente enregistrée'
                                    : 'Aucune vente pour cette date',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedDate == null
                                    ? 'Les ventes apparaîtront ici'
                                    : 'Essayez une autre date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
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
                                    'Montant: ${vente['total']} \$ \nDate: ${vente['sale_date']} '),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailSalePage(saleId: vente['id']),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => VentePage()));
        },
        child: const Icon(Icons.add),
        tooltip: 'Nouvelle vente',
      ),
    );
  }
}
