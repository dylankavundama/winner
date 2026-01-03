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
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/language_selection_page.dart';
import 'package:gestion_app_mobile/deposits_overview_page.dart';
import 'package:gestion_app_mobile/error_utils.dart';

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
  double totalDeposits = 0.0;
  double totalCaisse = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchVentes();
    // Actualisation automatique toutes les 30 secondes
    _startAutoRefresh();
    _fetchTotalDeposits();
    _fetchTotalCaisse();
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
                final loc = AppLocalizations.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.refresh, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ventes.length > previousCount
                                ? loc.vendorNewSaleNotification
                                : loc.vendorDataUpdated,
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
              final loc = AppLocalizations.of(context);
              setState(() {
                errorMessage =
                    data['message'] ?? loc.vendorLoadError;
                isLoading = false;
                _isRefreshing = false;
              });
            }
          }
        } else {
          if (mounted) {
            final loc = AppLocalizations.of(context);
            setState(() {
              errorMessage = loc.vendorServerError(response.statusCode);
              isLoading = false;
              _isRefreshing = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          final loc = AppLocalizations.of(context);
          setState(() {
            errorMessage = loc.vendorConnectionError(ErrorUtils.getUserFriendlyError(e));
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

  Future<void> _fetchTotalDeposits() async {
    try {
      final response =
          await http.get(Uri.parse(ApiConstants.depositsApi));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['deposits'] is List) {
          final List<dynamic> deposits = data['deposits'];
          double sum = 0.0;
          for (final d in deposits) {
            final amount = d['amount'];
            if (amount is num) {
              sum += amount.toDouble();
            } else if (amount is String) {
              sum += double.tryParse(amount) ?? 0.0;
            }
          }
          if (mounted) {
            setState(() {
              totalDeposits = sum;
            });
            // Recalculer le total de la caisse après mise à jour des dépôts
            _fetchTotalCaisse();
          }
        }
      }
    } catch (_) {
      // On ignore les erreurs silencieusement pour ne pas gêner le vendeur
    }
  }

  Future<void> _fetchTotalCaisse() async {
    try {
      // Récupérer le total des ventes
      double totalVentes = 0.0;
      final salesResponse = await http.get(Uri.parse(ApiConstants.baseUrl + '/sales.php'));
      if (salesResponse.statusCode == 200) {
        final salesData = json.decode(salesResponse.body);
        if (salesData['success'] == true && salesData['sales'] is List) {
          for (final sale in salesData['sales']) {
            final total = sale['total'];
            if (total is num) {
              totalVentes += total.toDouble();
            } else if (total is String) {
              totalVentes += double.tryParse(total) ?? 0.0;
            }
          }
        }
      }

      // Récupérer le total des sorties
      double totalSorties = 0.0;
      final sortiesResponse = await http.get(Uri.parse(ApiConstants.baseUrl + '/sorties.php'));
      if (sortiesResponse.statusCode == 200) {
        final sortiesData = json.decode(sortiesResponse.body);
        if (sortiesData['success'] == true && sortiesData['sorties'] is List) {
          for (final sortie in sortiesData['sorties']) {
            final montant = sortie['montant'];
            if (montant is num) {
              totalSorties += montant.toDouble();
            } else if (montant is String) {
              totalSorties += double.tryParse(montant) ?? 0.0;
            }
          }
        }
      }

      // Calculer le total de la caisse : (Ventes + Dépôts) - Sorties
      if (mounted) {
        setState(() {
          totalCaisse = (totalVentes + totalDeposits) - totalSorties;
        });
      }
    } catch (_) {
      // On ignore les erreurs silencieusement
    }
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
      final saleDateStr = v['sale_date']?.toString();
      if (saleDateStr == null || saleDateStr.length < 10) return false;
      final saleDate = saleDateStr.substring(0, 10);
      return saleDate == selectedStr;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo.png',
          height: 100,
          fit: BoxFit.contain,
        ),
        backgroundColor: Colors.blueGrey[800],
        centerTitle: true,
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
            tooltip: loc.vendorActionRefresh,
            onPressed: () => _fetchVentes(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: loc.vendorActionFilterDate,
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
              tooltip: loc.vendorActionResetFilter,
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
              title: Text(loc.vendorMenuDashboard),
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
              title: Text(loc.vendorMenuSales),
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
              title: Text(loc.vendorMenuInvoices),
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
              title: Text(loc.vendorMenuClients),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: Text(loc.vendorMenuProducts),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings),
              title: Text(loc.vendorMenuDeposits),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DepositsOverviewPage(),
                  ),
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
              title: Text(loc.vendorMenuExpenses),
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
              title: Text(loc.vendorMenuStockOut),
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
              leading: const Icon(Icons.language),
              title: Text(loc.dashboardMenuLanguage),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LanguageSelectionPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                loc.vendorMenuLogout,
                style: const TextStyle(color: Colors.redAccent),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchVentes();
                  },
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
                                    ? loc.vendorEmptyNoSales
                                    : loc.vendorEmptyNoSalesForDate,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedDate == null
                                    ? loc.vendorEmptyHint
                                    : loc.vendorEmptyHintOtherDate,
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
                          itemCount: filteredVentes.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                children: [
                                  Card(
                                    color: Colors.blueGrey[50],
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: const Icon(Icons.savings,
                                          color: Colors.blueGrey),
                                      title: Text(loc.vendorTotalDepositsTitle),
                                      subtitle: Text(
                                          '${totalDeposits.toStringAsFixed(2)} \$'),
                                    ),
                                  ),
                                  Card(
                                    color: Colors.green[50],
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: const Icon(Icons.account_balance,
                                          color: Colors.green),
                                      title: Text(loc.vendorTotalCaisseTitle),
                                      subtitle: Text(
                                          '${totalCaisse.toStringAsFixed(2)} \$'),
                                    ),
                                  ),
                                ],
                              );
                            }
                            final vente = filteredVentes[index - 1];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8),
                              child: ListTile(
                                leading:
                                    const Icon(Icons.shopping_bag),
                                title: Text(
                                  loc.vendorSaleItemTitle(
                                    vente['id'] ?? 0,
                                    vente['client_name'] ?? '',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  loc.vendorSaleItemSubtitle(
                                    '${vente['total']}',
                                    vente['sale_date'] ?? '',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailSalePage(
                                            saleId: vente['id']),
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
        tooltip: loc.vendorFabNewSale,
      ),
    );
  }
}
