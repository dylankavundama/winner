import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({Key? key}) : super(key: key);

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse(ApiConstants.clientsApi));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          clients = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erreur lors du chargement des clients (${response.statusCode})';
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

  void _showAddClientDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un client'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                  onSaved: (value) => name = value ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => email = value ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => phone = value ?? '',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await _addClient(name, email, phone);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addClient(String name, String email, String phone) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.clientsApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'phone': phone}),
      );
      if (response.statusCode == 200) {
        fetchClients();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client ajouté avec succès')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ajout (${response.statusCode})')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : ListView.separated(
                  itemCount: clients.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(client['name'] ?? 'Nom inconnu'),
                      subtitle: Text(client['email'] ?? ''),
                      trailing: Text(client['phone'] ?? ''),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientDialog,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un client',
      ),
    );
  }
} 