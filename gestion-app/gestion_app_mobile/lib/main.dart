import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
      routes: {
        '/home': (context) => HomePage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<String> _usernames = [];
  String? _selectedUsername;
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsernames();
  }

  Future<void> _fetchUsernames() async {
    final response = await http.get(Uri.parse(
        'http://192.168.1.69/winner/gestion-app/gestion-app/api/usernames.php'));
    print('Réponse usernames: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> users = jsonDecode(response.body);
      setState(() {
        _usernames = users.cast<String>();
      });
    } else {
      setState(() {
        _error = "Erreur lors du chargement des utilisateurs";
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await http.post(
      Uri.parse(
          'http://192.168.1.69/winner/gestion-app/gestion-app/api/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _selectedUsername,
        'password': _passwordController.text,
      }),
    );
    print('Réponse login: ${response.body}');
    setState(() {
      _loading = false;
    });
    try {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
 
            ),
          ),
        );
      } else {
        setState(() {
          _error = data['message'] ?? 'Erreur inconnue';
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur de décodage JSON ou de connexion";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                DropdownButtonFormField<String>(
                  value: _selectedUsername,
                  items: _usernames
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedUsername = val),
                  decoration: const InputDecoration(labelText: "Nom d'utilisateur"),
                  validator: (val) => val == null ? 'Sélectionnez un utilisateur' : null,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _selectedUsername == null ? null : _login,
                        child: const Text('Se connecter'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              // Retour à la page de login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('B]'),
      ),
    );
  }
}

// Exemple de page d'accueil après connexion
// class HomePage extends StatelessWidget {
//   final String username;
//   final String role;
//   final int userId;

//   const HomePage({required this.username, required this.role, required this.userId, Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Accueil')),
//       body: Center(
//         child: Text('Bienvenue $username ($role) [ID: $userId]'),
//       ),
//     );
//   }
// }
