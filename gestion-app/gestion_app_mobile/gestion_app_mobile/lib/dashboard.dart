// lib/dashboard_page.dart (Existing file from previous response)
import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/benefice_page.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/invoice_list_page.dart';
import 'package:gestion_app_mobile/main.dart';
import 'package:gestion_app_mobile/product_page.dart';
import 'package:gestion_app_mobile/report_page.dart';
import 'package:gestion_app_mobile/sale_list_page.dart';
import 'package:gestion_app_mobile/vente_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gestion_app_mobile/client.dart';

import 'sortie_page.dart';
import 'package:gestion_app_mobile/detail_sale_page.dart';

class DashboardPage extends StatefulWidget {
  final String loggedInUsername;
  final int loggedInUserId;

  const DashboardPage({
    Key? key,
    required this.loggedInUsername,
    required this.loggedInUserId,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalClients = 0;
  int totalProducts = 0;
  int totalSales = 0;
  int totalInvoices = 0;
  double totalSalesAmount = 0.0;
  double totalChiffreAffaire = 0.0;
  List<String> chartMonths = [];
  List<double> chartTotals = [];

  bool isLoading = true;
  String? errorMessage;
  String? _phpSessionCookie; // To store the session cookie

  // Ajout pour le sélecteur de période
  String selectedPeriod = '6mois'; // '6mois', '12mois', 'annee'

  List<String> get filteredChartMonths {
    if (selectedPeriod == '6mois' && chartMonths.length > 6) {
      return chartMonths.sublist(chartMonths.length - 6);
    } else if (selectedPeriod == '12mois' && chartMonths.length > 12) {
      return chartMonths.sublist(chartMonths.length - 12);
    } else if (selectedPeriod == 'annee') {
      final now = DateTime.now();
      return [
        for (int i = 0; i < chartMonths.length; i++)
          if (chartMonths[i].contains(now.year.toString())) chartMonths[i]
      ];
    }
    return chartMonths;
  }

  List<double> get filteredChartTotals {
    if (selectedPeriod == '6mois' && chartTotals.length > 6) {
      return chartTotals.sublist(chartTotals.length - 6);
    } else if (selectedPeriod == '12mois' && chartTotals.length > 12) {
      return chartTotals.sublist(chartTotals.length - 12);
    } else if (selectedPeriod == 'annee') {
      final now = DateTime.now();
      List<double> result = [];
      for (int i = 0; i < chartMonths.length; i++) {
        if (chartMonths[i].contains(now.year.toString()))
          result.add(chartTotals[i]);
      }
      return result;
    }
    return chartTotals;
  }

  @override
  void initState() {
    super.initState();
    _loadSessionAndFetchData();
  }

  Future<void> _loadSessionAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _phpSessionCookie = prefs.getString('phpSessionCookie');

    if (_phpSessionCookie == null || _phpSessionCookie!.isEmpty) {
      setState(() {
        errorMessage = "Session non trouvée. Veuillez vous reconnecter.";
        isLoading = false;
      });
      // Immediately redirect to login if no session is found
      _navigateToLogin();
      return;
    }

    // Now fetch data using the loaded session cookie
    await _fetchDashboardData();
    await _fetchChartData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Add the Cookie header to the request
      final response = await http.get(
        Uri.parse(ApiConstants.dashboardStatsApi),
        headers: {
          'Cookie': _phpSessionCookie!, // Send the PHPSESSID
        },
      );
      print('Dashboard stats response status: ${response.statusCode}');
      print('Dashboard stats response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalClients = data['total_clients'] ?? 0;
          totalProducts = data['total_products'] ?? 0;
          totalSales = data['total_sales'] ?? 0;
          totalInvoices = data['total_invoices'] ?? 0;
          totalSalesAmount =
              (data['total_sales_amount'] as num?)?.toDouble() ?? 0.0;
          totalChiffreAffaire =
              (data['total_chiffre_affaire'] as num?)?.toDouble() ?? 0.0;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage =
              "Non autorisé. Session expirée ou invalide. Veuillez vous reconnecter.";
          isLoading = false;
        });
        _navigateToLogin(); // Redirect on 401
      } else {
        setState(() {
          errorMessage =
              "Échec du chargement des données du tableau de bord: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur de connexion au serveur: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchChartData() async {
    try {
      // Add the Cookie header to the request
      final response = await http.get(
        Uri.parse(ApiConstants.salesChartDataApi),
        headers: {
          'Cookie': _phpSessionCookie!, // Send the PHPSESSID
        },
      );
      print('Chart data response status: ${response.statusCode}');
      print('Chart data response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          chartMonths = List<String>.from(data['months'] ?? []);
          chartTotals = (data['totals'] as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              [];
        });
      } else if (response.statusCode == 401) {
        // Handle 401 for chart data as well
        print(
            "Chart data: Non autorisé. Redirection vers la page de connexion.");
        _navigateToLogin();
      } else {
        print("Failed to load chart data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching chart data: $e");
    }
  }

  Future<void> _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phpSessionCookie'); // Clear stored session
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VentePage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un client',
      ),
      appBar: AppBar(
        title: const Text(
          'Tableau de bord du POS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[800],
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _navigateToLogin, // Use the helper function
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey[700],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset('assets/logo.png', height: 80),
                  // SizedBox(height: 10),
                  const Text(
                    'Winner Company',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.people_alt_outlined),
              title: Text('Clients'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ClientPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('Produits'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProductPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart_outlined),
              title: Text('Ventes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SaleListPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('Factures'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InvoiceListPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart_outlined),
              title: Text('Rapports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Bénéfice'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BeneficePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_downward),
              title: Text('Sorties'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SortiePage()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent),
              title: Text('Déconnexion',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _navigateToLogin,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildUserInfoCard(widget.loggedInUsername),
                      const SizedBox(height: 30),
                      const Text(
                        'Statistiques clés',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 2;

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.3,
                            children: [
                              _buildStatCard('Clients', totalClients.toString(),
                                  Icons.people_alt_outlined, Colors.blueAccent),
                              _buildStatCard(
                                  'Produits',
                                  totalProducts.toString(),
                                  Icons.inventory_2_outlined,
                                  Colors.green),
                              _buildStatCard('Ventes', totalSales.toString(),
                                  Icons.shopping_cart_outlined, Colors.teal),
                              _buildStatCard(
                                  'Factures',
                                  totalInvoices.toString(),
                                  Icons.receipt_long_outlined,
                                  Colors.orange),
                              _buildStatCard(
                                  'Total des ventes',
                                  '${totalSalesAmount.toStringAsFixed(2)} \$',
                                  Icons.payments_outlined,
                                  Colors.purple),
                              _buildStatCard(
                                  'Chiffre d\'affaires',
                                  '${totalChiffreAffaire.toStringAsFixed(2)} \$',
                                  Icons.area_chart_outlined,
                                  Colors.red),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Aperçu des performances',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Sélecteur de période
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          DropdownButton<String>(
                            value: selectedPeriod,
                            items: const [
                              DropdownMenuItem(
                                  value: '6mois',
                                  child: Text('6 derniers mois')),
                              DropdownMenuItem(
                                  value: '12mois',
                                  child: Text('12 derniers mois')),
                              DropdownMenuItem(
                                  value: 'annee',
                                  child: Text('Année en cours')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => selectedPeriod = v);
                            },
                          ),
                        ],
                      ),
                      Container(
                        height: 320,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: filteredChartTotals.isNotEmpty
                            ? Column(
                                children: [
                                  SizedBox(
                                    height: 180,
                                    child: PieChart(
                                      PieChartData(
                                        sections: _getPieSections(),
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 40,
                                        borderData: FlBorderData(show: false),
                                        pieTouchData: PieTouchData(
                                          touchCallback: (event, response) {},
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: filteredChartMonths.length,
                                      itemBuilder: (context, index) {
                                        final color = _pieColors[
                                            index % _pieColors.length];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                filteredChartMonths[index],
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${filteredChartTotals[index].toStringAsFixed(2)} \$',
                                                style: const TextStyle(
                                                    color: Colors.blueGrey),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Text(
                                  'Aucune donnée de vente disponible pour le graphique.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Helper methods remain the same
  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 35, color: color),
              ],
            ),
            // const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.blueGrey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, size: 28, color: Colors.blueGrey[700]),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String username) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blueGrey[700],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.account_circle,
                  size: 50, color: Colors.blueGrey[700]),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Bienvenue sur votre tableau de bord!',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey[200]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(chartTotals.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: chartTotals[index],
            color: Colors.blueAccent,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [],
      );
    });
  }

  double _getLeftTitlesInterval() {
    if (chartTotals.isEmpty) return 1.0;
    double maxTotal = chartTotals.reduce((a, b) => a > b ? a : b);
    if (maxTotal <= 100) return 20.0;
    if (maxTotal <= 500) return 100.0;
    if (maxTotal <= 1000) return 200.0;
    if (maxTotal <= 5000) return 1000.0;
    if (maxTotal <= 10000) return 2000.0;
    return 5000.0;
  }

  // Helpers pour le graphique filtré
  List<BarChartGroupData> _getBarGroupsFiltered() {
    final List<Color> gradientColors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.pinkAccent,
    ];
    return List.generate(filteredChartTotals.length, (index) {
      final color = gradientColors[index % gradientColors.length];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: filteredChartTotals[index],
            color: color,
            width: 16,
            borderRadius: BorderRadius.circular(4),
            // Affichage de la valeur sur la barre
            rodStackItems: [],
            borderSide: BorderSide.none,
            backDrawRodData: BackgroundBarChartRodData(show: false),
          ),
        ],
        showingTooltipIndicators: [0],
        barsSpace: 2,
      );
    });
  }

  double _getLeftTitlesIntervalFiltered() {
    if (filteredChartTotals.isEmpty) return 1.0;
    double maxTotal = filteredChartTotals.reduce((a, b) => a > b ? a : b);
    if (maxTotal <= 100) return 20.0;
    if (maxTotal <= 500) return 100.0;
    if (maxTotal <= 1000) return 200.0;
    if (maxTotal <= 5000) return 1000.0;
    if (maxTotal <= 10000) return 2000.0;
    return 5000.0;
  }

  // Helpers pour le PieChart
  final List<Color> _pieColors = [
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.pinkAccent,
  ];

  List<PieChartSectionData> _getPieSections() {
    final total = filteredChartTotals.fold(0.0, (a, b) => a + b);
    return List.generate(filteredChartTotals.length, (i) {
      final value = filteredChartTotals[i];
      final percent = total > 0 ? (value / total * 100) : 0;
      return PieChartSectionData(
        color: _pieColors[i % _pieColors.length],
        value: value,
        title: '${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }
}
