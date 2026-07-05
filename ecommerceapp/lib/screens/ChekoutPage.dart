import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'orders_page.dart';

class CheckoutScreen extends StatefulWidget {
  final String token;
  final String userId;
  final String orderId;
  final double totalPrice;
  final List<dynamic> cartItems;

  const CheckoutScreen({
    Key? key,
    required this.token,
    required this.userId,
    required this.orderId,
    required this.totalPrice,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  final String _apiBaseUrl = Constants.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    try {
      Stripe.publishableKey = Constants.stripePublicKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur Stripe : ${e.toString()}';
      });
    }
  }

  Future<void> _handleStripePayment() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final paymentIntent = await _createPaymentIntent();
      final clientSecret = paymentIntent['clientSecret'];

      if (clientSecret == null) {
        throw Exception('Client secret manquant.');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SmartEase',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _verifyAndCompleteOrder(paymentMethod: 'stripe', status: 'paid');
    } catch (e) {
      if (e is StripeException) {
        setState(() {
          _errorMessage = 'Paiement annulé.';
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur paiement : ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent() async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/payment/create-payment-intent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: json.encode({
        'amount': (widget.totalPrice * 100).toInt(),
        'currency': 'eur',
        'metadata': {
          'orderId': widget.orderId,
          'userId': widget.userId,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur de création PaymentIntent : ${response.body}');
    }

    return json.decode(response.body);
  }

  Future<void> _verifyAndCompleteOrder({
    required String paymentMethod,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$_apiBaseUrl/orders/${widget.orderId}/confirm-payment'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'paymentMethod': paymentMethod,
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec confirmation commande : ${response.body}');
    }

    final order = json.decode(response.body);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          order: order,
          cartItems: widget.cartItems.cast<Map<String, dynamic>>(),
          subtotal: order['subtotal'] ?? widget.totalPrice,
          shippingFee: order['shippingFee'] ?? 0.0,
          userToken: widget.token,
          userId: widget.userId,
          phoneNumber: order['phoneNumber'] ?? '',
          address: order['address'] ?? '',
          paymentMethod: paymentMethod,
          totalPrice: order['totalPrice'] ?? widget.totalPrice,
        ),
      ),
    );
  }

  Future<void> _handleCashOnDelivery() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _verifyAndCompleteOrder(
        paymentMethod: 'cash_on_delivery',
        status: 'pending',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Paiement', style: GoogleFonts.montserrat()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              '${Constants.apiBaseUrl}/images/background_payment.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey[200]),
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.85),
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Méthode de paiement',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${widget.totalPrice.toStringAsFixed(2)} €',
                  style: GoogleFonts.montserrat(fontSize: 18),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.montserrat(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (_isProcessing)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Traitement du paiement...'),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.indigo,
                      ),
                      onPressed: _handleStripePayment,
                      child: Text(
                        'Payer avec Stripe',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.indigo),
                      ),
                      onPressed: _handleCashOnDelivery,
                      child: Text(
                        'Payer à la livraison',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
