// Fichier : lib/add_product_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gestion_app_mobile/constants.dart'; // Assurez-vous que ce fichier existe

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

        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);
          if (responseBody['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produit ajouté avec succès !'), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true); // Fermer la page et retourner true pour indiquer le succès
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur : ${responseBody['message']}'), backgroundColor: Colors.red),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur HTTP: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion : $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Produit'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Nom du produit'),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description', maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(_priceController, 'Prix d\'achat', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_prixVenteController, 'Prix de vente', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_quantityController, 'Quantité', keyboardType: TextInputType.number),
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
                      child: const Text('Ajouter le produit', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
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
          return 'Ce champ est obligatoire';
        }
        if (keyboardType == TextInputType.number && double.tryParse(value) == null) {
          return 'Veuillez entrer un nombre valide';
        }
        return null;
      },
    );
  }
}