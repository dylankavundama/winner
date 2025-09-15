import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:sunmi_printer_plus/enums.dart';

import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:typed_data';

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
      final response = await http.get(Uri.parse(
          '${ApiConstants.baseUrl}/view_invoice.php?id=${widget.invoiceId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['invoice'] != null) {
          setState(() {
            invoice = data['invoice'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                data['message'] ?? 'Erreur lors du chargement de la facture';
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
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: ' \$');

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
                Center(
                  child: Image.asset('assets/logo.png', height: 80),
                ),
                Center(
                  child: Column(
                    children: [
                      const Text('Winner Company',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2c3e50))),
                      const SizedBox(height: 4),
                      Text('Facture #${invoice!['id']}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF34495e))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Date : $date',
                          style: const TextStyle(color: Colors.black87)),
                      const SizedBox(width: 12),
                      const Text('|'),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: status.toLowerCase() == 'payée'
                              ? Colors.green
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Contact : +243 823023277',
                              style: TextStyle(fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Adresse physique : Butembo, Galerie',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Kisunga N° : A01'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Client : ${client['name'] ?? ''}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if ((client['phone'] ?? '').isNotEmpty)
                            Text('Téléphone : ${client['phone']}'),
                          if (imei.isNotEmpty) Text('IMEI : $imei'),
                          // if (garanti.isNotEmpty) Text('Garantie : $garanti'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                        left: BorderSide(color: Colors.blue, width: 3)),
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(fontSize: 18, color: Colors.black),
                        children: [
                          const TextSpan(text: 'Statut de la facture : '),
                          WidgetSpan(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.toLowerCase() == 'payée'
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Table(
                    border: TableBorder.symmetric(
                        inside: BorderSide(color: Colors.grey.shade200)),
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
                            child: Text('Produit',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Quantité',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Prix unitaire',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Total',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...products.map((prod) {
                        final price = (prod['price'] is num)
                            ? (prod['price'] as num).toDouble()
                            : double.tryParse(prod['price'].toString()) ?? 0.0;
                        final qty =
                            int.tryParse(prod['quantity'].toString()) ?? 0;
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
                        decoration:
                            const BoxDecoration(color: Color(0xFFF2F2F2)),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Total :',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(),
                          const SizedBox(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(formatter.format(total),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Garantie valable 7 jours uniquement, hors écran et si l’autocollant reste intact.",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                      'Ce fut un plaisir de faire affaire avec vous. \n God Wine',
                      style: TextStyle(fontSize: 10)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
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

  Future<void> _printFacture() async {
    if (invoice == null) return;

    final client = invoice!['client'] as Map<String, dynamic>;
    final products = invoice!['products'] as List<dynamic>;
    final total = (invoice!['total'] is num)
        ? (invoice!['total'] as num).toDouble()
        : double.tryParse(invoice!['total'].toString()) ?? 0.0;
    final status = invoice!['status'] ?? 'Non payée';
    final date = invoice!['sale_date'];
    final imei = invoice!['imei'] ?? '';
    final garanti = invoice!['garanti'] ?? '';

    try {
      // Vérifier la connexion à l'imprimante Sunmi
      bool? isConnected = await SunmiPrinter.bindingPrinter();
      if (isConnected != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Impossible de se connecter à l\'imprimante Sunmi V2S.')),
          );
        }
        return;
      }

      // Réinitialiser l'imprimante
      await SunmiPrinter.initPrinter();

      // Imprimer le logo si disponible
      try {
        final ByteData logoBytes = await rootBundle.load('assets/logo.png');
        final Uint8List logoData = logoBytes.buffer.asUint8List();
        await SunmiPrinter.printImage(logoData);
        await SunmiPrinter.lineWrap(1);
      } catch (e) {
        print('Erreur lors du chargement du logo: $e');
      }

      // En-tête de l'entreprise
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('Winner Company');
      await SunmiPrinter.bold();
      await SunmiPrinter.setFontSize(SunmiFontSize.XL);
      await SunmiPrinter.printText('Winner Company');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.setFontSize(SunmiFontSize.MD);
      await SunmiPrinter.lineWrap(1);

      // Numéro de facture
      await SunmiPrinter.bold();
      await SunmiPrinter.setFontSize(SunmiFontSize.LG);
      await SunmiPrinter.printText('Facture #${invoice!['id']}');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.setFontSize(SunmiFontSize.MD);
      await SunmiPrinter.lineWrap(2);

      // Date et statut
      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      await SunmiPrinter.printText('Date: $date');
      await SunmiPrinter.printText('Statut: $status');
      await SunmiPrinter.lineWrap(1);

      // Séparateur
      await SunmiPrinter.line();

      // Informations de l'entreprise
      await SunmiPrinter.printText('Contact: +243 823023277');
      await SunmiPrinter.printText('Adresse: Butembo, Galerie');
      await SunmiPrinter.printText('Kisunga N°: A01');
      await SunmiPrinter.lineWrap(1);

      // Informations client
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('INFORMATIONS CLIENT');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.line();

      await SunmiPrinter.printText('Client: ${client['name'] ?? ''}');
      if ((client['phone'] ?? '').isNotEmpty) {
        await SunmiPrinter.printText('Téléphone: ${client['phone']}');
      }
      if (imei.isNotEmpty) {
        await SunmiPrinter.printText('IMEI: $imei');
      }
      // if (garanti.isNotEmpty) {
      //   await SunmiPrinter.printText('Garantie: $garanti');
      // }
      await SunmiPrinter.lineWrap(1);

      // En-tête du tableau des produits
      await SunmiPrinter.line();
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('DÉTAILS DE LA COMMANDE');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.line();

      // Impression optimisée pour Sunmi V2S (largeur 58mm)
      String formatLine(String name, String qty, String price) {
        // Limiter le nom du produit à 20 caractères pour la largeur de 58mm
        String shortName =
            name.length > 20 ? name.substring(0, 17) + '...' : name;
        return '${shortName.padRight(22)} x$qty ${price.padLeft(8)}';
      }

      // Produits
      for (var prod in products) {
        final price = (prod['price'] is num)
            ? (prod['price'] as num).toDouble()
            : double.tryParse(prod['price'].toString()) ?? 0.0;
        final qty = int.tryParse(prod['quantity'].toString()) ?? 0;
        final lineTotal = price * qty;

        await SunmiPrinter.printText(formatLine(prod['name'] ?? '',
            qty.toString(), '${lineTotal.toStringAsFixed(2)}\$'));
      }

      await SunmiPrinter.line();

      // Total
      await SunmiPrinter.bold();
      await SunmiPrinter.setFontSize(SunmiFontSize.LG);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.RIGHT);
      await SunmiPrinter.printText('TOTAL: ${total.toStringAsFixed(2)}\$');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.setFontSize(SunmiFontSize.MD);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.LEFT);
      await SunmiPrinter.lineWrap(2);

      // Notes de garantie
      await SunmiPrinter.setFontSize(SunmiFontSize.SM);
      await SunmiPrinter.printText("Garantie valable 7 jours uniquement");
      await SunmiPrinter.printText("hors écran et si l’autocollant reste intact.");
      await SunmiPrinter.lineWrap(2);

      // Pied de page
      await SunmiPrinter.setFontSize(SunmiFontSize.MD);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText('Ce fut un plaisir de faire');
      await SunmiPrinter.printText('affaire avec vous.');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('God Wine');
      await SunmiPrinter.resetBold();
      await SunmiPrinter.lineWrap(3);

      // Coupe du papier
      await SunmiPrinter.cut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Facture imprimée avec succès !'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur d\'impression: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      try {
        await SunmiPrinter.unbindingPrinter();
      } catch (e) {
        debugPrint('Erreur lors de la déconnexion: $e');
      }
    }
  }
}
