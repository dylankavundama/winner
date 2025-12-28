import 'package:flutter/material.dart';
import 'package:gestion_app_mobile/constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_localizations.dart';
import 'language_selection_page.dart';
import 'package:gestion_app_mobile/dashboard.dart';
import 'package:gestion_app_mobile/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dash_vendeur.dart';
import 'package:gestion_app_mobile/error_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale _locale = const Locale('fr');
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadPreferredLanguage();
  }

  Future<void> _loadPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language');
    if (langCode != null) {
      setState(() {
        _locale = Locale(langCode);
        _initialized = true;
      });
    } else {
      // Pas encore de langue choisie : afficher l'écran de sélection
      setState(() {
        _initialized = true;
      });
    }
  }

  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
        future: _checkStartupFlow(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data ?? {};
          final needsLanguageSelection =
              data['needsLanguageSelection'] == 'true';

          if (needsLanguageSelection) {
            return const LanguageSelectionPage();
          }

          if (data['phpSessionCookie'] != null) {
            final username = data['loggedInUsername'] ?? 'Utilisateur';
            final userRole = data['user_role'] ?? 'vendeur';

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

  static Future<Map<String, String?>> _checkStartupFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final phpSessionCookie = prefs.getString('phpSessionCookie');
    final loggedInUsername = prefs.getString('loggedInUsername');
    final userRole = prefs.getString('user_role');
    final appLanguage = prefs.getString('app_language');

    final needsLanguageSelection =
        appLanguage == null || appLanguage.isEmpty ? 'true' : 'false';

    return {
      'phpSessionCookie': phpSessionCookie,
      'loggedInUsername': loggedInUsername,
      'user_role': userRole,
      'needsLanguageSelection': needsLanguageSelection,
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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _error = AppLocalizations.of(context).loginErrorEmpty;
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
          'username': _usernameController.text,
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
        _error = "Erreur de connexion ou de décodage JSON: ${ErrorUtils.getUserFriendlyError(e)}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
                  Image.asset('assets/logo.png', height: 170, width: 300),
                  const SizedBox(height: 30),
                  Text(
                  loc.loginTitle,
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
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: loc.loginUsername,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Veuillez entrer votre nom d\'utilisateur'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  // ... votre code existant
                  TextFormField(
                    keyboardType: TextInputType.text,
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: loc.loginPassword,
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
                          child: Text(loc.loginButton),
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
