import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class AdminOrdersScreen extends StatefulWidget {
  final String token;

  const AdminOrdersScreen({required this.token, Key? key}) : super(key: key);

  @override
  _AdminOrdersScreenState createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List orders = [];
  bool isLoading = false;
  String? errorMessage;

  // Couleurs et styles
  final Color primaryColor = const Color.fromARGB(255, 207, 144, 218);
  final Color primaryDarkColor = const Color.fromARGB(255, 141, 110, 160);
  final Color backgroundColor = const Color.fromARGB(255, 141, 110, 160);
  
  TextStyle get montserratStyle => GoogleFonts.montserrat();
  TextStyle get montserratBoldStyle => GoogleFonts.montserrat(fontWeight: FontWeight.bold);
  TextStyle get montserratMediumStyle => GoogleFonts.montserrat(fontWeight: FontWeight.w500);

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/admin/orders'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load orders: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/admin/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut de la commande mis à jour', style: montserratStyle),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage;
        try {
          final responseBody = json.decode(response.body);
          errorMessage = responseBody['message'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de la mise à jour: $errorMessage', style: montserratStyle),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e', style: montserratStyle),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/admin/orders/$orderId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande annulée', style: montserratStyle),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage;
        try {
          final responseBody = json.decode(response.body);
          errorMessage = responseBody['message'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'annulation: $errorMessage', style: montserratStyle),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e', style: montserratStyle),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/admin/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande supprimée', style: montserratStyle),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage;
        try {
          final responseBody = json.decode(response.body);
          errorMessage = responseBody['message'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de la suppression: $errorMessage', style: montserratStyle),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e', style: montserratStyle),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildOrderItem(Map order) {
    final orderId = order['_id'] ?? '';
    final status = order['status'] ?? 'pending';
    final items = order['items'] ?? [];
    final subtotal = order['subtotal']?.toDouble() ?? 0.0;
    final shippingFee = order['shippingFee']?.toDouble() ?? 0.0;
    final totalPrice = order['totalPrice']?.toDouble() ?? 0.0;
    final shippingAddress = order['shippingAddress'] ?? 'Adresse non spécifiée';
    final phone = order['phone'] ?? '';
    final paymentMethod = order['paymentMethod'] ?? 'Méthode inconnue';
    final createdAt = order['createdAt'] != null 
        ? DateTime.parse(order['createdAt']).toLocal()
        : DateTime.now();

    // Déterminez la couleur en fonction du statut
    Color statusColor;
    switch (status) {
      case 'paid':
        statusColor = Colors.blue;
        break;
      case 'processing':
        statusColor = Colors.orange;
        break;
      case 'shipped':
        statusColor = Colors.purple;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default: // pending
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande #${orderId.substring(0, 8)}',
              style: montserratBoldStyle.copyWith(fontSize: 16),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: montserratMediumStyle.copyWith(
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  '${totalPrice.toStringAsFixed(3)} DT',
                  style: montserratBoldStyle.copyWith(
                    color: primaryDarkColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: montserratStyle.copyWith(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Informations client
                Text(
                  'Informations de livraison',
                  style: montserratBoldStyle.copyWith(fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  'Téléphone: $phone',
                  style: montserratStyle,
                ),
                Text(
                  'Adresse: $shippingAddress',
                  style: montserratStyle,
                ),
                SizedBox(height: 16),
                
                // Section Articles
                Text(
                  'Articles (${items.length})',
                  style: montserratBoldStyle.copyWith(fontSize: 14),
                ),
                SizedBox(height: 8),
                ...items.map<Widget>((item) {
                  final shoe = item['shoe'] is Map ? item['shoe'] : null;
                  final shoeName = shoe?['name'] ?? 'Produit inconnu';
                  final quantity = item['quantity'] ?? 0;
                  final size = item['size'] ?? '';
                  final price = item['price']?.toDouble() ?? 0.0;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shoeName,
                                style: montserratMediumStyle,
                              ),
                              Text(
                                'Quantité: $quantity | Taille: $size',
                                style: montserratStyle.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${price.toStringAsFixed(3)} DT',
                          style: montserratMediumStyle,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                SizedBox(height: 16),
                
                // Section Paiement
                Text(
                  'Détails de paiement',
                  style: montserratBoldStyle.copyWith(fontSize: 14),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sous-total:', style: montserratStyle),
                    Text('${subtotal.toStringAsFixed(3)} DT', style: montserratStyle),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Frais de livraison:', style: montserratStyle),
                    Text('${shippingFee.toStringAsFixed(3)} DT', style: montserratStyle),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: montserratBoldStyle),
                    Text(
                      '${totalPrice.toStringAsFixed(3)} DT',
                      style: montserratBoldStyle.copyWith(color: primaryDarkColor),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Méthode de paiement: $paymentMethod',
                  style: montserratStyle,
                ),
                SizedBox(height: 16),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: primaryDarkColor),
                      onSelected: (value) {
                        if (value == 'cancel') {
                          cancelOrder(orderId);
                        } else if (value == 'delete') {
                          deleteOrder(orderId);
                        } else {
                          updateOrderStatus(orderId, value);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pending',
                          child: Text('En attente', style: montserratStyle),
                        ),
                        PopupMenuItem(
                          value: 'paid',
                          child: Text('Payé', style: montserratStyle),
                        ),
                        PopupMenuItem(
                          value: 'processing',
                          child: Text('En traitement', style: montserratStyle),
                        ),
                        PopupMenuItem(
                          value: 'shipped',
                          child: Text('Expédié', style: montserratStyle),
                        ),
                        PopupMenuItem(
                          value: 'delivered',
                          child: Text('Livré', style: montserratStyle),
                        ),
                        PopupMenuItem(
                          value: 'cancelled',
                          child: Text('Annulé', style: montserratStyle),
                        ),
                        PopupMenuDivider(),
                    
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Supprimer la commande',
                            style: montserratStyle.copyWith(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Gestion des Commandes',
          style: montserratBoldStyle.copyWith(color: Colors.white),
        ),
        backgroundColor: primaryDarkColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: montserratStyle.copyWith(color: Colors.red),
                    ),
                  )
                : orders.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune commande trouvée',
                          style: montserratStyle,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchOrders,
                        color: primaryColor,
                        child: ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (context, index) => buildOrderItem(orders[index]),
                        ),
                      ),
      ),
    );
  }
}