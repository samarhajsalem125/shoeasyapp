// lib/widgets/stripe_payment_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripePaymentWidget extends StatefulWidget {
  final String clientSecret;
  final Function(String) onSuccess;
  final double amount;

  const StripePaymentWidget({
    super.key, 
    required this.clientSecret,
    required this.onSuccess,
    required this.amount,
  });

  @override
  // ignore: library_private_types_in_public_api
  _StripePaymentWidgetState createState() => _StripePaymentWidgetState();
}

class _StripePaymentWidgetState extends State<StripePaymentWidget> {
  bool _isProcessing = false;

  Future<void> _handlePayment() async {
    try {
      setState(() => _isProcessing = true);

      // Initialiser Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: widget.clientSecret,
          style: ThemeMode.light,
          merchantDisplayName: 'Votre Boutique',
        ),
      );

      // Afficher le formulaire de paiement
      await Stripe.instance.presentPaymentSheet();

      // Paiement réussi
      final paymentIntent = await Stripe.instance.retrievePaymentIntent(widget.clientSecret);
      widget.onSuccess(paymentIntent.id);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _isProcessing ? null : _handlePayment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('PAY €${widget.amount.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }
}