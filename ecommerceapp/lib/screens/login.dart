import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import 'admin_dashboard.dart';
import 'shoes_list.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _motDePasse;
  bool _chargement = false;
  String? _messageErreur;
  bool _motDePasseCache = true;

  Future<void> _connexion() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _chargement = true;
      _messageErreur = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _email, 'password': _motDePasse}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userId = data['user']['id'];
        final userRole = data['user']['role'];

        if (!mounted) return;

        if (userRole == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboard(token: token),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ShoesListScreen(token: token, userId: userId),
            ),
          );
        }
      } else {
        setState(() {
          _messageErreur = 'Email ou mot de passe invalide';
        });
      }
    } catch (e) {
      setState(() {
        _messageErreur = 'Erreur de connexion. Veuillez réessayer.';
      });
    } finally {
      setState(() {
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 180, 143, 216),
                  Color.fromARGB(255, 133, 118, 146)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'ShoeEasy',
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous pour continuer',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      decoration: _champTexte('Email', Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || !value.contains('@')
                          ? 'Entrez un email valide'
                          : null,
                      onSaved: (value) => _email = value,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _champTexte(
                        'Mot de passe',
                        Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _motDePasseCache
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _motDePasseCache = !_motDePasseCache;
                            });
                          },
                        ),
                      ),
                      obscureText: _motDePasseCache,
                      validator: (value) => value == null || value.length < 6
                          ? 'Mot de passe trop court'
                          : null,
                      onSaved: (value) => _motDePasse = value,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    if (_messageErreur != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _messageErreur!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _chargement ? null : _connexion,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: const Color(0xFF9D4EDD),
                          elevation: 2,
                        ),
                        child: _chargement
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'SE CONNECTER',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white54)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('OU',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white70)),
                        ),
                        const Expanded(child: Divider(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Vous n'avez pas de compte ? ",
                          style: GoogleFonts.montserrat(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: 'Inscrivez-vous',
                              style: const TextStyle(
                                color: Color(0xFF9D4EDD),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _champTexte(String label, IconData icone, {Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      labelText: label,
      labelStyle: GoogleFonts.montserrat(color: Colors.white),
      prefixIcon: Icon(icone, color: Colors.white70),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white70),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }
}
