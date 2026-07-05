import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _username;
  String? _email;
  String? _password;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  static const String baseUrl = 'http://localhost:5000/api/auth';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _username,
          'email': _email,
          'password': _password,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        final data = json.decode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? "Échec de l'inscription";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion. Veuillez réessayer.';
      });
    } finally {
      setState(() {
        _isLoading = false;
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
                colors: [Color(0xFFB48FD8), Color(0xFF857692)],
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      'Créer votre compte',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Nom d'utilisateur
                    TextFormField(
                      decoration: _inputDecoration('Nom d\'utilisateur', Icons.person),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Entrez un nom d\'utilisateur' : null,
                      onSaved: (value) => _username = value,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      decoration: _inputDecoration('Adresse e-mail', Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@') ? 'Entrez une adresse e-mail valide' : null,
                      onSaved: (value) => _email = value,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Mot de passe
                    TextFormField(
                      decoration: _inputDecoration(
                        'Mot de passe',
                        Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) =>
                          value == null || value.length < 6 ? 'Mot de passe trop court' : null,
                      onSaved: (value) => _password = value,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: const Color(0xFF9D4EDD),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'S\'INSCRIRE',
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
                          child: Text('OU', style: GoogleFonts.montserrat(color: Colors.white70)),
                        ),
                        const Expanded(child: Divider(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Vous avez déjà un compte ? ',
                          style: GoogleFonts.montserrat(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
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

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      labelText: label,
      labelStyle: GoogleFonts.montserrat(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white70),
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
