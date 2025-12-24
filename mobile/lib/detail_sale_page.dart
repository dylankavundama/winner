import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:intl/intl.dart';

class DetailSalePage extends StatefulWidget {
  final int saleId;
  const DetailSalePage({Key? key, required this.saleId}) : super(key: key);

  @override
  State<DetailSalePage> createState() => _DetailSalePageState();
}

class _DetailSalePageState extends State<DetailSalePage> {
  Map<String, dynamic>? sale;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSale();
  }

  Future<void> _fetchSale() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/detail_sale.php?id=${widget.saleId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['sale'] != null) {
          setState(() {
            sale = data['sale'];
            isLoading = false;
          });
        } else {
          final loc = AppLocalizations.of(context);
          setState(() {
            errorMessage = data['message'] ?? loc.detailSaleLoadError;
            isLoading = false;
          });
        }
      } else {
        final loc = AppLocalizations.of(context);
        setState(() {
          errorMessage = loc.detailSaleServerError(response.statusCode);
          isLoading = false;
        });
      }
    } catch (e) {
      final loc = AppLocalizations.of(context);
      setState(() {
        errorMessage = loc.detailSaleConnectionError(e.toString());
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.detailSaleTitle),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : _buildSaleContent(),
    );
  }

  Widget _buildSaleContent() {
    final loc = AppLocalizations.of(context);
    final client = sale!['client'] as Map<String, dynamic>;
    final products = sale!['products'] as List<dynamic>;
    final total = (sale!['total'] is num)
        ? (sale!['total'] as num).toDouble()
        : double.tryParse(sale!['total'].toString()) ?? 0.0;
    final date = sale!['date'] ?? '';
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '\$');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.detailSaleId(sale!['id'] ?? 0), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(loc.detailSaleDate(date)),
              const SizedBox(height: 10),
              Text(loc.detailSaleClient(client['name'] ?? '')),
              if ((client['phone'] ?? '').isNotEmpty) Text(loc.detailSalePhone(client['phone'])),
              if ((client['address'] ?? '').isNotEmpty) Text(loc.detailSaleAddress(client['address'])),
              const SizedBox(height: 20),
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF2F2F2)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(loc.detailSaleProduct, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(loc.detailSaleQuantity, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(loc.detailSaleUnitPrice, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(loc.detailSaleTotal, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...products.map((prod) {
                    final price = (prod['price'] is num)
                        ? (prod['price'] as num).toDouble()
                        : double.tryParse(prod['price'].toString()) ?? 0.0;
                    final qty = int.tryParse(prod['quantity'].toString()) ?? 0;
                    final lineTotal = price * qty;
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(prod['name'] ?? ''),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('$qty'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(formatter.format(price)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(formatter.format(lineTotal)),
                        ),
                      ],
                    );
                  }),
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF2F2F2)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(loc.detailSaleTotalLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(),
                      const SizedBox(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(formatter.format(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 