import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:gestion_app_mobile/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SortiePage extends StatefulWidget {
  const SortiePage({Key? key}) : super(key: key);

  @override
  State<SortiePage> createState() => _SortiePageState();
}

class _SortiePageState extends State<SortiePage> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> sorties = [];
  String typeFilter = '';
  String date = '';
  String month = '';
  String year = '';

  // Formulaire d'ajout
  final TextEditingController montantController = TextEditingController();
  final TextEditingController motifController = TextEditingController();
  String typeAjout = 'normal';
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    month = DateFormat('yyyy-MM').format(DateTime.now());
    year = DateFormat('yyyy').format(DateTime.now());
    _fetchSorties();
  }

  Future<void> _fetchSorties() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final params = <String, String>{};
      if (typeFilter.isNotEmpty) params['type'] = typeFilter;
      if (date.isNotEmpty) params['date'] = date;
      if (month.isNotEmpty) params['month'] = month;
      if (year.isNotEmpty) params['year'] = year;
      final uri = Uri.parse(ApiConstants.baseUrl + '/sorties.php').replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            sorties = data['sorties'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Erreur lors du chargement des sorties';
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

  Future<void> _addSortie() async {
    setState(() => isAdding = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;
      final montant = double.tryParse(montantController.text) ?? 0.0;
      final motif = motifController.text.trim();
      if (montant <= 0 || motif.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs.')));
        setState(() => isAdding = false);
        return;
      }
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + '/sorties.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'montant': montant,
          'motif': motif,
          'type': typeAjout,
        }),
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        montantController.clear();
        motifController.clear();
        setState(() => typeAjout = 'normal');
        _fetchSorties();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sortie enregistrée avec succès!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Erreur lors de l\'enregistrement.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorties de caisse'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : RefreshIndicator(
                  onRefresh: _fetchSorties,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildAddForm(),
                      const SizedBox(height: 24),
                      _buildFilters(),
                      const SizedBox(height: 12),
                      _buildSortiesTable(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAddForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvelle sortie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: montantController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Montant'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(labelText: 'Motif'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: typeAjout,
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'transaction', child: Text('Transaction')),
              ],
              onChanged: (v) => setState(() => typeAjout = v ?? 'normal'),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: isAdding ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: const Text('Enregistrer la sortie'),
                onPressed: isAdding ? null : _addSortie,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            DropdownButton<String>(
              value: typeFilter.isEmpty ? null : typeFilter,
              hint: const Text('Type'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Tous')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'transaction', child: Text('Transaction')),
              ],
              onChanged: (v) => setState(() { typeFilter = v ?? ''; _fetchSorties(); }),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextField(
                controller: TextEditingController(text: date),
                decoration: const InputDecoration(labelText: 'Jour'),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date.isNotEmpty ? DateTime.parse(date) : DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() { date = DateFormat('yyyy-MM-dd').format(picked); month = ''; year = ''; });
                    _fetchSorties();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextField(
                controller: TextEditingController(text: month),
                decoration: const InputDecoration(labelText: 'Mois'),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: month.isNotEmpty ? DateTime.parse(month + '-01') : DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() { month = DateFormat('yyyy-MM').format(picked); date = ''; year = ''; });
                    _fetchSorties();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextField(
                controller: TextEditingController(text: year),
                decoration: const InputDecoration(labelText: 'Année'),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: year.isNotEmpty ? DateTime(int.parse(year)) : DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() { year = DateFormat('yyyy').format(picked); date = ''; month = ''; });
                    _fetchSorties();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortiesTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: sorties.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune sortie enregistrée.'),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Utilisateur')),
                  DataColumn(label: Text('Montant')),
                  DataColumn(label: Text('Motif')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Date')),
                ],
                rows: sorties.map<DataRow>((s) => DataRow(cells: [
                  DataCell(Text(s['id'].toString())),
                  DataCell(Text(s['username'] ?? '')),
                  DataCell(Text('${s['montant']} \$')),
                  DataCell(Text(s['motif'] ?? '')),
                  DataCell(_buildTypeBadge(s['type'] ?? '')),
                  DataCell(Text(s['date_sortie'] ?? '')),
                ])).toList(),
              ),
            ),
    );
  }

  Widget _buildTypeBadge(String type) {
    if (type == 'normal') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
        child: const Text('Normal', style: TextStyle(color: Colors.white)),
      );
    } else if (type == 'transaction') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
        child: const Text('Transaction', style: TextStyle(color: Colors.black)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8)),
        child: Text(type, style: const TextStyle(color: Colors.white)),
      );
    }
  }
} 