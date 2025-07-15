import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_app_mobile/client_model.dart';
import 'package:gestion_app_mobile/product_model.dart';

class FacturePage extends StatelessWidget {
  final int saleId;
  final Client client;
  final List<SaleProduct> products;
  final double total;
  final String imei;
  final String garantie;
  final DateTime saleDate;

  const FacturePage({
    Key? key,
    required this.saleId,
    required this.client,
    required this.products,
    required this.total,
    required this.imei,
    required this.garantie,
    required this.saleDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facture'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printFacture(context),
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareFacture(context),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildClientInfo(),
            const SizedBox(height: 20),
            _buildProductsTable(currencyFormatter),
            const SizedBox(height: 20),
            _buildTotal(currencyFormatter),
            const SizedBox(height: 20),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WINNER',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Text(
                      'Gestion des Ventes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Facture #$saleId',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(saleDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations Client',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('Nom: ${client.name}'),
            if (imei.isNotEmpty) Text('IMEI: $imei'),
            if (garantie.isNotEmpty) Text('Garantie: $garantie'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTable(NumberFormat currencyFormatter) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails des Produits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Produit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qté',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Prix',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...products.map((product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(product.name),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${product.quantityToSell}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      currencyFormatter.format(product.priceOverride),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      currencyFormatter.format(product.priceOverride * product.quantityToSell),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTotal(NumberFormat currencyFormatter) {
    return Card(
      elevation: 2,
      color: Colors.blueGrey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              currencyFormatter.format(total),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Merci pour votre confiance !',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pour toute question, contactez-nous.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printFacture(BuildContext context) {
    // Ici vous pouvez implémenter l'impression
    // Par exemple, utiliser un package comme printing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impression lancée...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareFacture(BuildContext context) {
    // Ici vous pouvez implémenter le partage
    // Par exemple, utiliser un package comme share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage de la facture...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
} 