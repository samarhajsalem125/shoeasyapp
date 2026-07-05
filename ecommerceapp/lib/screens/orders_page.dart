import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double shippingFee;
  final String userToken;
  final String userId;
  final String phoneNumber;
  final String address;
  final String paymentMethod;
  final int totalPrice;
  final dynamic order;

  const OrderConfirmationScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.shippingFee,
    required this.userToken,
    required this.userId,
    required this.phoneNumber,
    required this.address,
    required this.paymentMethod,
    required this.totalPrice,
    required this.order,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'Payer sur place';
  bool _isLoading = false;

  double get totalPrice => widget.subtotal + widget.shippingFee;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.address;
    _phoneController.text = widget.phoneNumber;
    _paymentMethod = widget.paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_TN', symbol: 'DT');
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finalisation de commande',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image with overlay
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.darken,
              ),
              child: Image.network(
                'http://localhost:5000/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Main Content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                  child: Column(
                    children: [
                      _buildOrderCard(formatter, now, context),
                      const SizedBox(height: 20),
                      _buildDeliveryInfoCard(),
                      const SizedBox(height: 20),
                      _buildPaymentMethodCard(),
                      const SizedBox(height: 20),
                      _buildConfirmButton(context),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(NumberFormat formatter, DateTime now, BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé de la commande',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 12),
            
            if (widget.cartItems.isEmpty)
              const Text(
                'Votre panier est vide',
                style: TextStyle(fontFamily: 'Montserrat'),
              )
            else
              Column(
                children: widget.cartItems.map((item) => _buildOrderItem(item)).toList(),
              ),
            
            const Divider(height: 30),
            
            _buildPriceRow('Sous-total', widget.subtotal, formatter),
            _buildPriceRow('Frais de livraison', widget.shippingFee, formatter),
            const Divider(height: 20),
            _buildPriceRow('Total', totalPrice, formatter, isTotal: true),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  'Commande passée le ${DateFormat('dd/MM/yyyy à HH:mm').format(now)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? 'Article inconnu';
    final size = item['size']?.toString() ?? 'N/A';
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = item['imageUrl']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[200],
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag),
                    )
                  : const Icon(Icons.shopping_bag),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                  'Taille: $size',
                  style: const TextStyle(fontFamily: 'Montserrat'),
                ),
                Text(
                  'Quantité: $quantity',
                  style: const TextStyle(fontFamily: 'Montserrat'),
                ),
              ],
            ),
          ),
          Text(
            '${price.toStringAsFixed(2)} DT',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations de livraison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  labelStyle: TextStyle(fontFamily: 'Montserrat'),
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontFamily: 'Montserrat'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro';
                  }
                  if (!RegExp(r'^[0-9]{8,15}$').hasMatch(value)) {
                    return 'Numéro invalide (8-15 chiffres)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse complète',
                  labelStyle: TextStyle(fontFamily: 'Montserrat'),
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontFamily: 'Montserrat'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre adresse';
                  }
                  if (value.length < 10) {
                    return 'Adresse trop courte (min 10 caractères)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Méthode de paiement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 15),
            
            RadioListTile(
              title: const Text(
                'Payer sur place',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              value: 'Payer sur place',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value.toString()),
            ),
            
            RadioListTile(
              title: const Text(
                'Payer en ligne (Stripe)',
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
              value: 'Payer en ligne (Stripe)',
              groupValue: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, NumberFormat formatter, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Montserrat',
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleOrderConfirmation,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: Text(
          _paymentMethod == 'Payer sur place' 
              ? 'Confirmer la commande' 
              : 'Payer maintenant',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Future<void> _handleOrderConfirmation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_paymentMethod == 'Payer sur place') {
        await _placeOrder();
      } else {
        await _navigateToCheckout(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToCheckout(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          userToken: widget.userToken,
          userId: widget.userId,
          cartItems: widget.cartItems,
          subtotal: widget.subtotal,
          shippingFee: widget.shippingFee,
          totalPrice: totalPrice,
          address: _addressController.text,
          phoneNumber: _phoneController.text,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OrderSuccessScreen(),
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final orderData = {
        'user': widget.userId,
        'items': widget.cartItems.map((item) => {
          'shoe': item['id'],
          'quantity': item['quantity'],
          'size': item['size'],
          'price': item['price'],
        }).toList(),
        'subtotal': widget.subtotal,
        'shippingFee': widget.shippingFee,
        'totalPrice': totalPrice,
        'shippingAddress': _addressController.text,
        'phone': _phoneController.text,
        'paymentMethod': _paymentMethod,
        'status': 'pending',
      };

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userToken}',
        },
        body: json.encode(orderData),
      ).timeout(const Duration(seconds: 30));

      Navigator.of(context).pop();

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderSuccessScreen(),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la commande (${response.statusCode})');
      }
    } catch (e) {
      Navigator.of(context).pop();
      rethrow;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class CheckoutScreen extends StatefulWidget {
  final String userToken;
  final String userId;
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double shippingFee;
  final double totalPrice;
  final String address;
  final String phoneNumber;

  const CheckoutScreen({
    super.key,
    required this.userToken,
    required this.userId,
    required this.cartItems,
    required this.subtotal,
    required this.shippingFee,
    required this.totalPrice,
    required this.address,
    required this.phoneNumber,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paiement en ligne',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stripe Payment Widget would go here
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _processPayment,
                    child: const Text(
                      'Payer maintenant',
                      style: TextStyle(fontFamily: 'Montserrat'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    
    try {
      await _placeOrderAfterPayment();
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur de paiement: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Montserrat'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _placeOrderAfterPayment() async {
    final orderData = {
      'user': widget.userId,
      'items': widget.cartItems.map((item) => {
        'shoe': item['id'],
        'quantity': item['quantity'],
        'size': item['size'],
        'price': item['price'],
      }).toList(),
      'subtotal': widget.subtotal,
      'shippingFee': widget.shippingFee,
      'totalPrice': widget.totalPrice,
      'shippingAddress': widget.address,
      'phone': widget.phoneNumber,
      'paymentMethod': 'Payer en ligne (Stripe)',
      'status': 'paid',
    };

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.userToken}',
      },
      body: json.encode(orderData),
    );

    if (response.statusCode != 201) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erreur lors de la création de la commande');
    }
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Commande confirmée',
          style: TextStyle(fontFamily: 'Montserrat'),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Commande confirmée!',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Merci pour votre achat <3',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(fontFamily: 'Montserrat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}