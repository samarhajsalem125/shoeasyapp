import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'cart.dart';

class ShoeDetailsScreen extends StatefulWidget {
  final String shoeId;
  final String token;
  final String userId;

  const ShoeDetailsScreen({
    Key? key,
    required this.shoeId,
    required this.token,
    required this.userId,
  }) : super(key: key);

  @override
  State<ShoeDetailsScreen> createState() => _ShoeDetailsScreenState();
}

class _ShoeDetailsScreenState extends State<ShoeDetailsScreen> {
  Map<String, dynamic>? shoe;
  bool isLoading = true;
  bool isAddingToCart = false;
  int quantity = 1;
  String? selectedSize;
  List<String> sizes = [];

  @override
  void initState() {
    super.initState();
    fetchShoeDetails();
  }

  Future<void> fetchShoeDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/shoes/${widget.shoeId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          shoe = json.decode(response.body);
          if (shoe != null && shoe!['size'] != null) {
            sizes = shoe!['size'] is String 
                ? (shoe!['size'] as String).split(',').map((s) => s.trim()).toList()
                : List<String>.from(shoe!['size']);
            selectedSize = sizes.isNotEmpty ? sizes[0] : null;
          }
          isLoading = false;
        });
      } else {
        _showError('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Connection Error: ${e.toString()}');
    }
  }

  Future<void> addToCart() async {
    if (shoe == null || shoe!['stock'] == 0) {
      _showError('Product is out of stock');
      return;
    }

    if (selectedSize == null) {
      _showError('Please select a size before adding to cart');
      return;
    }

    if (quantity > (shoe!['stock'] as int)) {
      _showError('Not enough stock available');
      return;
    }

    setState(() => isAddingToCart = true);

    try {
      // First check if item already exists in cart
      final cartResponse = await http.get(
        Uri.parse('http://localhost:5000/api/cart/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (cartResponse.statusCode == 200) {
        final cartData = json.decode(cartResponse.body);
        final items = cartData['items'] ?? [];
        
        // Check for existing item with same shoe and size
        final existingItemIndex = items.indexWhere((item) => 
            item['shoe']['_id'] == widget.shoeId && item['size'] == selectedSize);

        if (existingItemIndex != -1) {
          // Update quantity if item exists
          final newQuantity = items[existingItemIndex]['quantity'] + quantity;
          await http.put(
            Uri.parse('http://localhost:5000/api/cart/${widget.userId}/items/${widget.shoeId}/$selectedSize'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: json.encode({'quantity': newQuantity}),
          );
          _showSuccess('Quantity updated in cart');
        } else {
          // Add new item if it doesn't exist
          await http.post(
            Uri.parse('http://localhost:5000/api/cart'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: json.encode({
              'user': widget.userId,
              'items': [{
                'shoe': widget.shoeId,
                'quantity': quantity,
                'size': selectedSize,
              }]
            }),
          );
          _showSuccess('Item added to cart');
        }

        // Navigate to cart after successful operation
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CartScreen(
              userId: widget.userId,
              token: widget.token,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() => isAddingToCart = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void incrementQuantity() {
    if (shoe != null && quantity < shoe!['stock']) {
      setState(() => quantity++);
    } else {
      _showError('Maximum stock reached');
    }
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() => quantity--);
    }
  }

  String formatPrice(double price) {
    return NumberFormat.currency(symbol: 'DT ', decimalDigits: 2).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(
                  userId: widget.userId,
                  token: widget.token,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shoe == null) {
      return const Center(child: Text('Product not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(),
          const SizedBox(height: 20),
          _buildBrandAndName(),
          const SizedBox(height: 16),
          _buildPriceAndStock(),
          const SizedBox(height: 20),
          _buildDescription(),
          const SizedBox(height: 24),
          _buildSizeSelection(),
          const SizedBox(height: 24),
          _buildQuantityControl(),
          const SizedBox(height: 40),
          _buildAddToCartButton(),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Image.network(
          shoe!['imageUrl'] ?? 'https://via.placeholder.com/300',
          fit: BoxFit.contain,
          height: 200,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 50),
        ),
      ),
    );
  }

  Widget _buildBrandAndName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shoe!['brand'] ?? 'Brand',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shoe!['name'] ?? 'Product Name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndStock() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          formatPrice(shoe!['price']?.toDouble() ?? 0),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Stock: ${shoe!['stock']}',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shoe!['description'] ?? 'No description available',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Size',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (sizes.isEmpty)
          const Text(
            'No sizes available',
            style: TextStyle(color: Colors.red, fontSize: 16),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) => _buildSizeOption(size)).toList(),
          ),
      ],
    );
  }

  Widget _buildSizeOption(String size) {
    final isSelected = selectedSize == size;
    return GestureDetector(
      onTap: () => setState(() => selectedSize = size),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: decrementQuantity,
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                quantity.toString(),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: incrementQuantity,
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: (shoe!['stock'] == 0 || isAddingToCart) ? null : addToCart,
        child: isAddingToCart
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'ADD TO CART',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}