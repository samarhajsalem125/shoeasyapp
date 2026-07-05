import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class ReturnRequestNewScreen extends StatefulWidget {
  final String token;
  final String userId;

  const ReturnRequestNewScreen({
    required this.token,
    required this.userId,
    super.key,
  });

  @override
  _ReturnRequestNewScreenState createState() => _ReturnRequestNewScreenState();
}

class _ReturnRequestNewScreenState extends State<ReturnRequestNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  List<dynamic> _userOrders = [];
  String? _selectedOrderId;

  final Color primaryColor = const Color.fromARGB(255, 145, 120, 150);
  final Color errorColor = Colors.red[700]!;
  final Color successColor = Colors.green[600]!;

  final String backgroundImageUrl = 'http://localhost:5000/images/background.png';

  @override
  void initState() {
    super.initState();
    fetchUserOrders();
  }

  Future<void> fetchUserOrders() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/orders/user/${widget.userId}/for-return'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userOrders = data['orders'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Échec du chargement des commandes disponibles pour le retour',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la récupération des commandes',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> submitReturnRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final body = json.encode({
      'user': widget.userId,
      'order': _selectedOrderId,
      'reason': _reasonController.text.trim(),
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/returns'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Demande de retour soumise avec succès',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: successColor,
          ),
        );
        _reasonController.clear();
        setState(() {
          _selectedOrderId = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Échec de l’envoi de la demande de retour',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: errorColor,
          ),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Délai d’attente dépassé. Veuillez réessayer.',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: errorColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l’envoi de la demande. Veuillez réessayer.',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(backgroundImageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 32, left: 8, right: 8, bottom: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              },
            ),
            Expanded(
              child: Text(
                'Demande de retour produit',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48), // To balance the leading IconButton
          ],
        ),
      ),
    ),
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 40),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Sélectionnez votre commande et indiquez la raison du retour',
                        style: GoogleFonts.montserrat(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      DropdownButtonFormField<String>(
                        value: _selectedOrderId,
                        items: _userOrders.map<DropdownMenuItem<String>>((order) {
                          return DropdownMenuItem<String>(
                            value: order['_id'],
                            child: Text(
                              'Commande #${order['_id'].substring(0, 8)}',
                              style: GoogleFonts.montserrat(),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedOrderId = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Sélectionnez une commande',
                          labelStyle: GoogleFonts.montserrat(),
                          prefixIcon: const Icon(Icons.receipt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez sélectionner une commande';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: 'Raison du retour',
                          labelStyle: GoogleFonts.montserrat(),
                          hintText: 'Expliquez pourquoi vous souhaitez retourner ce produit',
                          hintStyle: GoogleFonts.montserrat(),
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.edit),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez fournir une raison du retour';
                          }
                          if (value.trim().length < 10) {
                            return 'Veuillez fournir plus de détails (au moins 10 caractères)';
                          }
                          return null;
                        },
                        style: GoogleFonts.montserrat(),
                      ),
                      const SizedBox(height: 36),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : submitReturnRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'ENVOYER LA DEMANDE',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.montserrat(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
