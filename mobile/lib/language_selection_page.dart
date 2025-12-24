import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import 'main.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  String _selectedLang = 'fr';
  bool _saving = false;

  Future<void> _saveAndContinue() async {
    setState(() {
      _saving = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _selectedLang);

    // Recréer l'app avec la nouvelle locale via MyAppState
    if (!mounted) return;
    final myAppState =
        context.findAncestorStateOfType<MyAppState>();
    myAppState?.setLocale(Locale(_selectedLang));

    // Si on vient d'un écran (dashboard, etc.), on revient dessus.
    // Sinon (premier lancement), on va vers la page de login (qui gérera la session).
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.languageSelectTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                loc.languageSelectDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              RadioListTile<String>(
                value: 'fr',
                groupValue: _selectedLang,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _selectedLang = v;
                  });
                },
                title: Text(loc.languageFrench),
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: _selectedLang,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _selectedLang = v;
                  });
                },
                title: Text(loc.languageEnglish),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _saveAndContinue,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(loc.languageContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


