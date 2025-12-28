import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/app_localizations.dart';
import 'package:gestion_app_mobile/error_utils.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({Key? key}) : super(key: key);

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;
  String? errorMessage;
  String? errorType; // 'unexpected', 'load', 'connection'
  int? errorCode;
  String? errorDetails;

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
            errorType = 'unexpected';
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
          errorType = 'load';
          errorCode = response.statusCode;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorType = 'connection';
        errorDetails = ErrorUtils.getUserFriendlyError(e);
        isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.clientTitle),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorType != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _getErrorMessage(loc),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : clients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.clientEmptyTitle,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.clientEmptyHint,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: clients.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(
                            client['name'] ?? loc.clientUnknownName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            client['email'] ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: SizedBox(
                            width: 100,
                            child: Text(
                              client['phone'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        );
                      },
                    ),
 
    );
  }

  String _getErrorMessage(AppLocalizations loc) {
    switch (errorType) {
      case 'unexpected':
        return loc.clientUnexpectedFormat;
      case 'load':
        return loc.clientLoadError(errorCode ?? 0);
      case 'connection':
        return loc.clientConnectionError(errorDetails ?? '');
      default:
        return loc.clientUnexpectedFormat;
    }
  }
}
