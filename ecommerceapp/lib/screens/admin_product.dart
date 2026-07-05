import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminProductsScreen extends StatefulWidget {
  final String token;
  const AdminProductsScreen({required this.token, super.key});

  @override
  _AdminProductsScreenState createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List products = [];
  List filteredProducts = [];
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';

  final _formKey = GlobalKey<FormState>();
  String? _name, _description, _imageUrl, _category, _brand;
  double? _price, _promotionPrice;
  int? _stock;
  List<String> _sizes = [];
  bool isEditing = false;
  String? editingProductId;

  final Color primaryColor = Colors.purple;
  final Color primaryDarkColor = Colors.purple[800]!;
  final Color backgroundColor = Colors.grey[100]!;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/admin/products'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List allProducts = json.decode(response.body);
        setState(() {
          products = allProducts;
          filteredProducts = allProducts;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Échec du chargement des produits';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur: $e';
        isLoading = false;
      });
    }
  }

  void filterProducts(String query) {
    final filtered = products.where((product) {
      final name = product['name'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      searchQuery = query;
      filteredProducts = filtered;
    });
  }

  Future<void> addOrUpdateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final productData = {
      'name': _name,
      'brand': _brand,
      'description': _description,
      'price': (_price! * 100).toInt(),
      'promotionPrice': _promotionPrice != null ? (_promotionPrice! * 100).toInt() : null,
      'imageUrl': _imageUrl,
      'size': _sizes,
      'category': _category,
      'stock': _stock,
    };

    try {
      http.Response response;
      if (isEditing && editingProductId != null) {
        response = await http.put(
          Uri.parse('http://localhost:5000/api/admin/products/$editingProductId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode(productData),
        );
      } else {
        response = await http.post(
          Uri.parse('http://localhost:5000/api/admin/products'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode(productData),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.of(context).pop();
        fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Échec de l'enregistrement du produit"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void startEditProduct(Map product) {
    setState(() {
      isEditing = true;
      editingProductId = product['_id'];
      _name = product['name'];
      _brand = product['brand'];
      _description = product['description'];
      _price = (product['price'] / 100).toDouble();
      _promotionPrice = product['promotionPrice'] != null
          ? (product['promotionPrice'] / 100).toDouble()
          : null;
      _imageUrl = product['imageUrl'];
      _sizes = List<String>.from(product['size'] ?? []);
      _category = product['category'];
      _stock = product['stock'];
    });
    showProductForm();
  }

  void showProductForm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          isEditing ? 'Modifier le produit' : 'Ajouter un produit',
          style: TextStyle(color: primaryDarkColor, fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(child: Column(children: [..._buildFormFields()])),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              resetForm();
            },
            child: Text('Annuler', style: TextStyle(color: primaryDarkColor, fontFamily: 'Montserrat')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: addOrUpdateProduct,
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
          ),
        ],
      ),
    );
  }

  void resetForm() {
    setState(() {
      isEditing = false;
      editingProductId = null;
      _name = null;
      _brand = null;
      _description = null;
      _price = null;
      _promotionPrice = null;
      _imageUrl = null;
      _sizes = [];
      _category = null;
      _stock = null;
    });
  }

  List<Widget> _buildFormFields() {
    return [
      _buildTextField('Nom', _name, (v) => _name = v, isRequired: true),
      _buildTextField('Marque', _brand, (v) => _brand = v, isRequired: true),
      _buildTextField('Description', _description, (v) => _description = v),
      _buildTextField('Prix (DT)', _price?.toString(), (v) => _price = double.tryParse(v!), isNumeric: true, isRequired: true),
      _buildTextField('Prix Promo (DT)', _promotionPrice?.toString(), (v) => _promotionPrice = double.tryParse(v!), isNumeric: true),
      _buildTextField('URL de l\'image', _imageUrl, (v) => _imageUrl = v),
      _buildTextField('Catégorie', _category, (v) => _category = v),
      _buildTextField('Stock', _stock?.toString(), (v) => _stock = int.tryParse(v!), isNumeric: true),
      _buildSizeField(),
    ];
  }

  Widget _buildSizeField() {
    final sizeController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tailles', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8.0,
          children: _sizes.map((size) {
            return Chip(
              label: Text(size, style: const TextStyle(fontFamily: 'Montserrat')),
              onDeleted: () => setState(() => _sizes.remove(size)),
            );
          }).toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: sizeController,
                decoration: const InputDecoration(labelText: 'Ajouter une taille'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (sizeController.text.trim().isNotEmpty) {
                  setState(() => _sizes.add(sizeController.text.trim()));
                  sizeController.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String? initial, Function(String?) onSaved, 
      {bool isNumeric = false, bool isRequired = false}) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (value) => isRequired && (value == null || value.isEmpty) ? 'Champ requis' : null,
      onSaved: onSaved,
      style: const TextStyle(fontFamily: 'Montserrat'),
    );
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/admin/products/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryDarkColor,
        title: TextField(
          style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
          decoration: const InputDecoration(
            hintText: 'Rechercher une chaussure...',
            hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white),
          ),
          onChanged: filterProducts,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              resetForm();
              showProductForm();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'http://localhost:5000/images/shoesbackround.jpg',
              fit: BoxFit.cover,
            ),
          ),
          if (isLoading)
            Center(child: CircularProgressIndicator(color: primaryColor))
          else if (errorMessage != null)
            Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontFamily: 'Montserrat')))
          else
            ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, index) {
                final product = filteredProducts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white.withOpacity(0.8),
                  child: ListTile(
                    leading: product['imageUrl'] != null
                        ? Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                        : const SizedBox(width: 50, height: 50),
                    title: Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat', color: primaryDarkColor)),
                    subtitle: Text(
                      'Marque: ${product['brand'] ?? 'N/A'}\nTailles: ${product['size'].join(", ")}\nCatégorie: ${product['category'] ?? 'N/A'}\nStock: ${product['stock'] ?? 0}\nPrix: ${(product['price'] / 100).toStringAsFixed(3)} DT\nPromo: ${product['promotionPrice'] != null ? (product['promotionPrice'] / 100).toStringAsFixed(3) + " DT" : "Aucune"}',
                      style: const TextStyle(fontFamily: 'Montserrat'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit, color: primaryColor), onPressed: () => startEditProduct(product)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteProduct(product['_id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}