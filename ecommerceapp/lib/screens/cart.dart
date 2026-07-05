import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'orders_page.dart';
import 'shoes_details.dart';

class CartScreen extends StatefulWidget {
  final String token;
  final String userId;

  const CartScreen({
    required this.token,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic> cartData = {'items': []};
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  double totalAmount = 0.0;
  final double shippingFee = 7.0;
  final String backgroundImageUrl = 'http://localhost:5000/images/téléchargé (1).jpeg';

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    try {
      setState(() {
        isLoading = true;
        isError = false;
      });

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/cart/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          cartData = data['success'] == true 
              ? _removeDuplicates(data['cart'] ?? {'items': []})
              : {'items': []};
          totalAmount = calculateTotal(cartData['items']);
          isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Échec du chargement du panier');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Map<String, dynamic> _removeDuplicates(Map<String, dynamic> cart) {
    final uniqueItems = <Map<String, dynamic>>[];
    final seenItems = <String>{};

    for (final item in cart['items']) {
      final key = '${item['shoe']['_id']}-${item['size']}';
      if (!seenItems.contains(key)) {
        seenItems.add(key);
        uniqueItems.add(item);
      }
    }

    return {...cart, 'items': uniqueItems};
  }

  double calculateTotal(List<dynamic> items) {
    return items.fold<double>(0, (sum, item) {
      final shoe = item['shoe'] ?? {};
      final price = (shoe['price'] is num) ? shoe['price'].toDouble() : 0.0;
      final quantity = (item['quantity'] is int) ? item['quantity'] : 1;
      return sum + (price * quantity);
    });
  }

  Future<void> updateQuantity(String shoeId, String size, int newQuantity) async {
    if (newQuantity < 1) {
      await removeFromCart(shoeId, size);
      return;
    }

    try {
      setState(() => isLoading = true);

      // Vérifier le stock d'abord
      final stockResponse = await http.get(
        Uri.parse('http://localhost:5000/api/shoes/$shoeId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (stockResponse.statusCode == 200) {
        final shoeData = json.decode(stockResponse.body);
        if ((shoeData['stock'] as int) < newQuantity) {
          throw Exception('Stock insuffisant');
        }
      }

      final response = await http.put(
        Uri.parse('http://localhost:5000/api/cart/${widget.userId}/items/$shoeId/$size'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'quantity': newQuantity}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          final index = cartData['items'].indexWhere((item) => 
              item['shoe']['_id'] == shoeId && item['size'] == size);
          if (index != -1) {
            cartData['items'][index]['quantity'] = newQuantity;
            totalAmount = calculateTotal(cartData['items']);
          }
        });
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Erreur de stock'),
            backgroundColor: Colors.orange,
          ),
        );
        await fetchCart();
      } else {
        throw Exception(data['message'] ?? 'Échec de la mise à jour');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> removeFromCart(String shoeId, String size) async {
    try {
      setState(() => isLoading = true);

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/cart/${widget.userId}/items/$shoeId/$size'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          cartData['items'].removeWhere((item) => 
              item['shoe']['_id'] == shoeId && item['size'] == size);
          totalAmount = calculateTotal(cartData['items']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article retiré du panier'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(data['message'] ?? 'Échec de la suppression');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> clearCart() async {
    try {
      setState(() => isLoading = true);

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/cart/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          cartData = {'items': []};
          totalAmount = 0.0;
        });
      } else {
        throw Exception(data['message'] ?? 'Échec de la suppression du panier');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void navigateToDetails(String shoeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoeDetailsScreen(
          shoeId: shoeId,
          token: widget.token,
          userId: widget.userId,
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item) {
    final shoe = item['shoe'] ?? {};
    final shoeId = shoe['_id']?.toString() ?? '';
    final name = shoe['name'] ?? 'Produit inconnu';
    final imageUrl = shoe['imageUrl'] ?? '';
    final price = (shoe['price'] is num) ? shoe['price'].toDouble() : 0.0;
    final quantity = (item['quantity'] is int) ? item['quantity'] : 1;
    final size = item['size']?.toString() ?? '';
    final subtotal = price * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        color: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => navigateToDetails(shoeId),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${price.toStringAsFixed(2)} DT',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Taille: $size',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () => updateQuantity(shoeId, size, quantity - 1),
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => updateQuantity(shoeId, size, quantity + 1),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => removeFromCart(shoeId, size),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final hasItems = cartData['items'].isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasItems) ...[
            _buildTotalRow('Sous-total', totalAmount),
            const SizedBox(height: 8),
            _buildTotalRow('Livraison', shippingFee),
            const Divider(height: 24),
            _buildTotalRow('Total', totalAmount + shippingFee, isTotal: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: navigateToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'PASSER LA COMMANDE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _navigateToHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'PARCOURIR LES ARTICLES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Montserrat',
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} DT',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  void navigateToCheckout() {
    if (cartData['items'].isEmpty) return;
    
    final formattedItems = cartData['items'].map<Map<String, dynamic>>((item) {
      final shoe = item['shoe'] ?? {};
      return {
        'id': shoe['_id'],
        'name': shoe['name'],
        'price': shoe['price']?.toDouble() ?? 0.0,
        'imageUrl': shoe['imageUrl'],
        'quantity': item['quantity'],
        'size': item['size'],
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          cartItems: formattedItems,
          userId: widget.userId,
          shippingFee: 5.99,
          subtotal: totalAmount,
          userToken: widget.token,
          phoneNumber: '', // À remplir avec les données utilisateur
          address: '', // À remplir avec les données utilisateur
          paymentMethod: '', // À remplir avec les données utilisateur
          totalPrice: (totalAmount + shippingFee).toInt(),
          order: null,
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Montserrat',
            ),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Votre Panier', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _navigateToHome,
          ),
          actions: [
            if (cartData['items'].isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: clearCart,
                tooltip: 'Vider le panier',
              ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: fetchCart,
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Image d'arrière-plan
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
            // Contenu principal
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : isError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Réessayer',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          const SizedBox(height: kToolbarHeight + 20),
                          Expanded(
                            child: cartData['items'].isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.shopping_cart_outlined, 
                                            size: 64, color: Colors.white),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Votre panier est vide',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _navigateToHome,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                          ),
                                          child: const Text(
                                            'Parcourir les articles',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: fetchCart,
                                    child: ListView(
                                      padding: const EdgeInsets.only(bottom: 100),
                                      children: [
                                        ...cartData['items'].map((item) => _buildCartItem(item)).toList(),
                                      ],
                                    ),
                                  ),
                          ),
                          _buildTotalSection(),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}