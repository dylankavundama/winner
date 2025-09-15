import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:gestion_app_mobile/dashboard.dart';
import 'package:gestion_app_mobile/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'Dash_vendeur.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: FutureBuilder<Map<String, String?>>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData &&
              snapshot.data!['phpSessionCookie'] != null) {
            final username =
                snapshot.data!['loggedInUsername'] ?? 'Utilisateur';
            final userRole = snapshot.data!['user_role'] ?? 'vendeur';

            if (userRole == 'vendeur' || userRole == 'magasinier') {
              return DashboardPageVendeur(loggedInUsername: username);
            } else {
              return DashboardPage(
                loggedInUsername: username,
                loggedInUserId: 0,
              );
            }
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }

  static Future<Map<String, String?>> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final phpSessionCookie = prefs.getString('phpSessionCookie');
    final loggedInUsername = prefs.getString('loggedInUsername');
    final userRole = prefs.getString('user_role');

    return {
      'phpSessionCookie': phpSessionCookie,
      'loggedInUsername': loggedInUsername,
      'user_role': userRole,
    };
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  List<String> _usernames = [];
  String? _selectedUsername;
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _usernamesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsernames();
    _fetchUsernames();
    _passwordVisible = false; // Initialisez la variable
  }

  bool _passwordVisible = false; // <-- Ajoutez cette ligne
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsernames() async {
    setState(() {
      _usernamesLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(ApiConstants.usernamesApi));
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        setState(() {
          _usernames = users.cast<String>();
          if (_usernames.isNotEmpty) {
            _selectedUsername = _usernames[0];
          }
        });
      } else {
        setState(() {
          _error =
              "Erreur lors du chargement des utilisateurs: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur de connexion au serveur \npour les utilisateurs ";
      });
    } finally {
      setState(() {
        _usernamesLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUsername == null || _passwordController.text.isEmpty) {
      setState(() {
        _error =
            "Veuillez sélectionner un nom d'utilisateur et entrer un mot de passe.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginApi),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _selectedUsername,
          'password': _passwordController.text,
        }),
      );

      setState(() {
        _loading = false;
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        String? phpSessionCookie;
        if (response.headers.containsKey('set-cookie')) {
          final setCookieHeader = response.headers['set-cookie']!;
          final cookies = setCookieHeader.split(';');
          for (var cookie in cookies) {
            if (cookie.trim().startsWith('PHPSESSID=')) {
              phpSessionCookie = cookie.trim();
              break;
            }
          }
        }

        if (phpSessionCookie != null && phpSessionCookie.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('phpSessionCookie', phpSessionCookie);
          await prefs.setString('user_role', data['role'] ?? '');
          await prefs.setString('loggedInUsername', data['username'] ?? '');

          final User loggedInUser = User.fromJson(data);

          Widget dashboard;
          if (loggedInUser.role == 'vendeur' ||
              loggedInUser.role == 'magasinier') {
            dashboard =
                DashboardPageVendeur(loggedInUsername: loggedInUser.username);
          } else {
            dashboard = DashboardPage(
              loggedInUsername: loggedInUser.username,
              loggedInUserId: loggedInUser.userId,
            );
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => dashboard,
            ),
          );
        } else {
          setState(() {
            _error = "Login réussi, mais cookie de session non trouvé.";
          });
          return;
        }
      } else {
        setState(() {
          _error = data['message'] ??
              'Nom d\'utilisateur ou mot de passe incorrect.';
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur de connexion ou de décodage JSON: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon(
                  //   Icons.storefront,
                  //   size: 60,
                  //   color: Theme.of(context).primaryColor,
                  // ),
                  Image.asset('assets/logo.png', height: 150, width: 300),
                  const SizedBox(height: 30),
                  Text(
                    'Connectez-vous à votre compte',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _usernamesLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value: _selectedUsername,
                          items: _usernames
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedUsername = val),
                          decoration: const InputDecoration(
                            labelText: "Nom d'utilisateur",
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (val) => val == null
                              ? 'Veuillez sélectionner un utilisateur'
                              : null,
                          isExpanded: true,
                        ),
                  const SizedBox(height: 15),
                  // ... votre code existant
                  TextFormField(
                    keyboardType: TextInputType
                        .number, // Modifiez pour un clavier de texte normal
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        // <-- Ajoutez ce widget
                        icon: Icon(
                          // Bascule entre les icônes basées sur l'état
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          // Mettez à jour l'état de la variable _passwordVisible
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText:
                        !_passwordVisible, // <-- Utilisez la variable d'état ici
                    validator: (val) => val == null || val.isEmpty
                        ? 'Veuillez entrer votre mot de passe'
                        : null,
                  ),
// ... votre code existant
                  const SizedBox(height: 30),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text('Se connecter'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
