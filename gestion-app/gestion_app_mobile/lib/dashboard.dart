import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  // Simuler des données pour l'exemple
  final int totalClients;
  final int totalProducts;
  final int totalSales;
  final int totalInvoices;
  final double totalSalesAmount;
  final double totalChiffreAffaire;

  const DashboardPage({
    Key? key,
    this.totalClients = 12,
    this.totalProducts = 34,
    this.totalSales = 56,
    this.totalInvoices = 20,
    this.totalSalesAmount = 12345.67,
    this.totalChiffreAffaire = 23456.78,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard('Clients', totalClients.toString(), Icons.people, Colors.blue),
                _buildStatCard('Produits', totalProducts.toString(), Icons.inventory, Colors.green),
                _buildStatCard('Ventes', totalSales.toString(), Icons.shopping_cart, Colors.teal),
                _buildStatCard('Factures', totalInvoices.toString(), Icons.receipt_long, Colors.orange),
                _buildStatCard('Total ventes', '${totalSalesAmount.toStringAsFixed(2)} €', Icons.attach_money, Colors.purple),
                _buildStatCard('Chiffre d\'affaire', '${totalChiffreAffaire.toStringAsFixed(2)} €', Icons.bar_chart, Colors.red),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Graphique des ventes par mois (à venir)',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            // Ici, vous pourrez intégrer un graphique Flutter plus tard
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      color: color.withOpacity(0.1),
      child: Container(
        width: 160,
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 