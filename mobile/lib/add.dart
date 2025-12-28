// Fichier : lib/add_product_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String? _phpSessionCookie;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _prixVenteController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessionCookie();
  }

  Future<void> _loadSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phpSessionCookie = prefs.getString('phpSessionCookie');
    });
  }

  // Fonction pour envoyer la requête d'ajout de produit
  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String name = _nameController.text;
      final String description = _descriptionController.text;
      final double price = double.tryParse(_priceController.text) ?? 0.0;
      final double prixVente = double.tryParse(_prixVenteController.text) ?? 0.0;
      final int quantity = int.tryParse(_quantityController.text) ?? 0;

      final Map<String, dynamic> productData = {
        'name': name,
        'description': description,
        'price': price,
        'prix_vente': prixVente,
        'quantity': quantity,
      };

      try {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/add_product.php'), // Créez ce fichier PHP
          headers: {
            'Content-Type': 'application/json',
            'Cookie': _phpSessionCookie!,
          },
          body: jsonEncode(productData),
        );

        final loc = AppLocalizations.of(context);
        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);
          if (responseBody['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.addProductSuccess), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true); // Fermer la page et retourner true pour indiquer le succès
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.addProductError(responseBody['message'] ?? '')), backgroundColor: Colors.red),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.addProductHttpError(response.statusCode)), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.addProductConnectionError(ErrorUtils.getUserFriendlyError(e))), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addProductTitle),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(context, _nameController, loc.addProductNameLabel),
              const SizedBox(height: 16),
              _buildTextField(context, _descriptionController, loc.addProductDescriptionLabel, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(context, _priceController, loc.addProductPriceLabel, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(context, _prixVenteController, loc.addProductSalePriceLabel, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(context, _quantityController, loc.addProductQuantityLabel, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(loc.addProductButton, style: const TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    final loc = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loc.addProductFieldRequired;
        }
        if (keyboardType == TextInputType.number && double.tryParse(value) == null) {
          return loc.addProductInvalidNumber;
        }
        return null;
      },
    );
  }
}