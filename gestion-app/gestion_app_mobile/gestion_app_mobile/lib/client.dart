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
        final decoded = json.decode(response.body);
        List<Map<String, dynamic>> loadedClients = [];
        if (decoded is List) {
          // Cas où l'API retourne directement une liste
          loadedClients = decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map && decoded['clients'] is List) {
          // Cas où l'API retourne un objet avec une clé 'clients'
          loadedClients = (decoded['clients'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          setState(() {
            errorMessage = 'Format de réponse inattendu.';
            isLoading = false;
          });
          return;
        }
        setState(() {
          clients = loadedClients;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Erreur lors du chargement des clients (${response.statusCode})';
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
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : ListView.separated(
                  itemCount: clients.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
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
 
    );
  }
}
