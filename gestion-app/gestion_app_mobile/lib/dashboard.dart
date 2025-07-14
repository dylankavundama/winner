// lib/dashboard_page.dart (Existing file from previous response)
import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/main.dart';
import 'package:gestion_app_mobile/vente_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gestion_app_mobile/client.dart';
 

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
          totalSalesAmount = (data['total_sales_amount'] as num?)?.toDouble() ?? 0.0;
          totalChiffreAffaire = (data['total_chiffre_affaire'] as num?)?.toDouble() ?? 0.0;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = "Non autorisé. Session expirée ou invalide. Veuillez vous reconnecter.";
          isLoading = false;
        });
        _navigateToLogin(); // Redirect on 401
      } else {
        setState(() {
          errorMessage = "Échec du chargement des données du tableau de bord: ${response.statusCode}";
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
          chartTotals = (data['totals'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [];
        });
      } else if (response.statusCode == 401) {
        // Handle 401 for chart data as well
        print("Chart data: Non autorisé. Redirection vers la page de connexion.");
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
        onPressed: (){


            Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VentePage()),
                        );
        },
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un client',
      ) ,
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
                              _buildStatCard(
                                  'Clients',
                                  totalClients.toString(),
                                  Icons.people_alt_outlined,
                                  Colors.blueAccent),
                              _buildStatCard(
                                  'Produits',
                                  totalProducts.toString(),
                                  Icons.inventory_2_outlined,
                                  Colors.green),
                              _buildStatCard(
                                  'Ventes',
                                  totalSales.toString(),
                                  Icons.shopping_cart_outlined,
                                  Colors.teal),
                              _buildStatCard(
                                  'Factures',
                                  totalInvoices.toString(),
                                  Icons.receipt_long_outlined,
                                  Colors.orange),
                _buildStatCard(
                                  'Total des ventes',
                    '${totalSalesAmount.toStringAsFixed(2)} €',
                                  Icons.payments_outlined,
                    Colors.purple),
                _buildStatCard(
                                  'Chiffre d\'affaires',
                    '${totalChiffreAffaire.toStringAsFixed(2)} €',
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
                      Container(
                        height: 280,
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
                        child: chartTotals.isNotEmpty
                            ? BarChart(
                                BarChartData(
                                  barGroups: _getBarGroups(),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            space: 4,
                                            child: Text(
                                              chartMonths[value.toInt()],
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        },
                                        interval: 1,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: _getLeftTitlesInterval(),
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()}€',
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                        reservedSize: 30,
                                      ),
                                    ),
                                    rightTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: _getLeftTitlesInterval(),
                                    drawHorizontalLine: true,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.withOpacity(0.2),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipBgColor: Colors.blueGrey,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          '${chartMonths[group.x.toInt()]}\n',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: '${rod.toY.toStringAsFixed(2)} €',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'Aucune donnée de vente disponible pour le graphique.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      _buildNavButton(context, 'Produits', Icons.inventory_2_outlined, () {
                        print('Navigating to Produits');
                      }),
                      _buildNavButton(context, 'Ventes', Icons.shopping_cart_outlined, () {
                        print('Navigating to Ventes');
                      }),
                      _buildNavButton(context, 'Factures', Icons.receipt_long_outlined, () {
                        print('Navigating to Factures');
                      }),
                      _buildNavButton(context, 'Clients', Icons.people_alt_outlined, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ClientPage()),
                        );
                      }),
                      _buildNavButton(context, 'Rapports', Icons.bar_chart_outlined, () {
                        print('Navigating to Rapports');
                      }),
                      _buildNavButton(context, 'Stock', Icons.archive_outlined, () {
                        print('Navigating to Stock');
                      }),
                      _buildNavButton(context, 'Bénéfice', Icons.attach_money, () {
                        print('Navigating to Bénéfice');
                      }),
                      _buildNavButton(context, 'Sorties', Icons.arrow_downward, () {
                        print('Navigating to Sorties');
                      }),
                    ],
                  ),
                ),
    );
  }

  // Helper methods remain the same
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildNavButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
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
                const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
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
            Icon(Icons.person_pin_circle, size: 60, color: Colors.blueGrey[100]),
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
}