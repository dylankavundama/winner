import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class FacturePage extends StatefulWidget {
  final int invoiceId;
  const FacturePage({Key? key, required this.invoiceId}) : super(key: key);

  @override
  State<FacturePage> createState() => _FacturePageState();
}

class _FacturePageState extends State<FacturePage> {
  Map<String, dynamic>? invoice;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/view_invoice.php?id=${widget.invoiceId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['invoice'] != null) {
          setState(() {
            invoice = data['invoice'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Erreur lors du chargement de la facture';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Facture'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: invoice == null ? null : _printFacture,
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: invoice == null ? null : _shareFacture,
            tooltip: 'Partager',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : _buildFactureContent(),
    );
  }

  Widget _buildFactureContent() {
    final client = invoice!['client'] as Map<String, dynamic>;
    final products = invoice!['products'] as List<dynamic>;
    final total = (invoice!['total'] is num)
        ? (invoice!['total'] as num).toDouble()
        : double.tryParse(invoice!['total'].toString()) ?? 0.0;
    final date = invoice!['sale_date'];
    final status = invoice!['status'] ?? 'Non payée';
    final imei = invoice!['imei'] ?? '';
    final garanti = invoice!['garanti'] ?? '';
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: ' 24');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo centré
                Center(
                  child: Image.asset('assets/logo.png', height: 80),
                ),
              //  const SizedBox(height: 10),
                // Titre société et numéro facture
                Center(
                  child: Column(
                    children: [
                      const Text('Winner Company', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2c3e50))),
                      const SizedBox(height: 4),
                      Text('Facture #${invoice!['id']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF34495e))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Date et statut
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Date : $date', style: const TextStyle(color: Colors.black87)),
                      const SizedBox(width: 12),
                      const Text('|'),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: status.toLowerCase() == 'payée' ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                // Deux colonnes infos société/client
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Contact : +243 823023277', style: TextStyle(fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Adresse physique : Butembo, Galerie', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Kisunga N° : A01'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Client : ${client['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if ((client['phone'] ?? '').isNotEmpty) Text('Téléphone : ${client['phone']}'),
                          if (imei.isNotEmpty) Text('IMEI : $imei'),
                          if (garanti.isNotEmpty) Text('Garantie : $garanti'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Bloc statut
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: Colors.blue, width: 3)),
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 18, color: Colors.black),
                        children: [
                          const TextSpan(text: 'Statut de la facture : '),
                          WidgetSpan(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.toLowerCase() == 'payée' ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tableau produits
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Table(
                    border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade200)),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Quantité', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Prix unitaire', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Total :', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ),
                const SizedBox(height: 20),
                // Notes/remarques
                const Text(
                  "L'autocollant de garantie doit être apposé sur le téléphone. Nous offrons une garantie spéciale de 7 jours pour les problèmes de batterie.\nNB: Veuillez noter que la garantie ne couvre pas les téléphones dont l'écran est fissuré ou rayé.",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                // Remerciement
                const Center(
                  child: Text('Ce fut un plaisir de faire affaire avec vous.', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 8),
                // Signature
                const Center(
                  child: Text('God Wine', style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                // Boutons en bas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer la facture'),
                      onPressed: _printFacture,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _printFacture() async {
    if (invoice == null) return;
    final pdf = pw.Document();
    final client = invoice!['client'] as Map<String, dynamic>;
    final products = invoice!['products'] as List<dynamic>;
    final total = invoice!['total'];
    final date = invoice!['sale_date'];
    final status = invoice!['status'] ?? 'Non payée';
    final imei = invoice!['imei'] ?? '';
    final garanti = invoice!['garanti'] ?? '';
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Facture #${invoice!['id']}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Date : $date'),
            pw.SizedBox(height: 10),
            pw.Text('Client : ${client['name']}'),
            if ((client['address'] ?? '').isNotEmpty) pw.Text('Adresse : ${client['address']}'),
            if ((client['phone'] ?? '').isNotEmpty) pw.Text('Téléphone : ${client['phone']}'),
            if ((client['email'] ?? '').isNotEmpty) pw.Text('Email : ${client['email']}'),
            pw.SizedBox(height: 10),
            if (imei.isNotEmpty) pw.Text('IMEI : $imei'),
            if (garanti.isNotEmpty) pw.Text('Garantie : $garanti'),
            pw.SizedBox(height: 10),
            pw.Text('Statut : $status'),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Produit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Qté', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Prix', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...products.map((prod) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(prod['name'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${prod['quantity']}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${prod['price']} \$'),
                        ),
                      ],
                    )),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                    pw.SizedBox(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('$total \$'),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Merci pour votre confiance !'),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _shareFacture() async {
    if (invoice == null) return;
    final client = invoice!['client'] as Map<String, dynamic>;
    final total = invoice!['total'];
    final date = invoice!['sale_date'];
    final factureText = 'Facture #${invoice!['id']}\nDate : $date\nClient : ${client['name']}\nTotal : $total \$';
    await Share.share(factureText, subject: 'Facture WINNER');
  }
} 