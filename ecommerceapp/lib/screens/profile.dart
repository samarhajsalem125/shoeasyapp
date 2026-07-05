import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shoes_details.dart'; 

class ProfileScreen extends StatefulWidget {
  final String token;
  final String userId;

  const ProfileScreen({super.key, required this.token, required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  List<dynamic> orders = [];
  List<dynamic> favorites = [];
  bool isLoading = true;
  bool isLoadingOrders = true;
  bool isLoadingFavorites = true;
  String? errorMessage;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final String baseUrl = 'http://localhost:5000';
  final String backgroundImageUrl = 'http://localhost:5000/images/background.png';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      await Future.wait([fetchUserProfile(), fetchOrders(), fetchFavorites()]);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          user = data;
          _usernameController.text = data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Profile error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile/${widget.userId}/orders'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = _parseJsonList(data);
          isLoadingOrders = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Orders error: $e';
        isLoadingOrders = false;
      });
    }
  }

  Future<void> fetchFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/favorites/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          favorites = _parseJsonList(data);
          isLoadingFavorites = false;
        });
      } else {
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Favorites error: $e';
        isLoadingFavorites = false;
      });
    }
  }

  List<dynamic> _parseJsonList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data.containsKey('items') && data['items'] is List) {
      return data['items'];
    }
    return [];
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image error: $e')),
      );
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final uri = Uri.parse('$baseUrl/api/auth/profile/${widget.userId}');
      var request = http.MultipartRequest('PUT', uri)
        ..fields['username'] = _usernameController.text
        ..fields['email'] = _emailController.text
        ..headers['Authorization'] = 'Bearer ${widget.token}';

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _image!.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        await fetchUserProfile();
        setState(() => _image = null);
      } else {
        final jsonBody = json.decode(responseBody);
        throw Exception(jsonBody['message'] ?? 'Update failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update error: $e')),
      );
    }
  }

  Widget _buildOrderItem(dynamic order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.85),
      elevation: 4,
      child: ExpansionTile(
        title: Text('Order #${order['_id']?.toString().substring(0, 8)}',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${order['status']?.toUpperCase() ?? 'N/A'} - ${(order['totalPrice'] ?? 0).toStringAsFixed(2)} DT',
          style: GoogleFonts.montserrat(
              color: _getStatusColor(order['status']),
              fontWeight: FontWeight.w500),
        ),
        children: [
          ...(order['items'] as List).map((item) {
            final shoe = item['shoe'];
            return ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text(shoe?['name'] ?? 'Unknown',
                  style: GoogleFonts.montserrat()),
              subtitle: Text(
                'Qty: ${item['quantity']} | Size: ${item['size']}',
                style: GoogleFonts.montserrat(),
              ),
              trailing: Text(
                '${(shoe?['promotionPrice'] ?? shoe?['price'] ?? 0).toStringAsFixed(2)} DT',
                style: GoogleFonts.montserrat(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(dynamic shoe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.85),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => navigateToDetails(shoe),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  shoe['imageUrl'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.shopping_bag, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoe['name'] ?? 'Unknown Shoe',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shoe['price']?.toStringAsFixed(2)} DT',
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () => removeFavorite(shoe['_id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> removeFavorite(String shoeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({'userId': widget.userId, 'shoeId': shoeId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          favorites.removeWhere((shoe) => shoe['_id'] == shoeId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove favorite'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToDetails(dynamic shoe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShoeDetailsScreen(
          shoeId: shoe['_id'],
          token: widget.token,
          userId: widget.userId,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // image arriere plan
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
            child: Image.network(
              backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey[300]),
            ),
          ),
          
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Text(errorMessage!,
                            style: GoogleFonts.montserrat(
                                color: Colors.white, fontSize: 18)),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            // Title de page profil
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text('Mon Profil',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black.withOpacity(0.7),
                                          offset: const Offset(0, 2),
                                        )
                                      ])),
                            ),
                            const SizedBox(height: 20),

                            //semi-transparent arriere plan
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          child: _image != null
                                              ? ClipOval(
                                                  child: Image.file(
                                                    _image!,
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : user?['photo'] != null && user!['photo'] != ''
                                                  ? ClipOval(
                                                      child: Image.network(
                                                        '$baseUrl/${user!['photo']}',
                                                        width: 100,
                                                        height: 100,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => 
                                                            Icon(Icons.person, size: 50, color: Colors.white),
                                                      ),
                                                    )
                                                  : Icon(Icons.person, size: 50, color: Colors.white),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurpleAccent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              color: Colors.white,
                                              onPressed: pickImage,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      'Cliquez pour changer votre photo',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white70,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 25),
                                    TextFormField(
                                      controller: _usernameController,
                                      style: GoogleFonts.montserrat(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Nom d\'utilisateur',
                                        labelStyle: GoogleFonts.montserrat(
                                            color: Colors.white70),
                                        prefixIcon: Icon(Icons.person, color: Colors.white70),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.white),
                                        ),
                                        fillColor: Colors.white.withOpacity(0.1),
                                        filled: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Entrez un nom d\'utilisateur';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _emailController,
                                      style: GoogleFonts.montserrat(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: GoogleFonts.montserrat(
                                            color: Colors.white70),
                                        prefixIcon: Icon(Icons.email, color: Colors.white70),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.white),
                                        ),
                                        fillColor: Colors.white.withOpacity(0.1),
                                        filled: true,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Entrez un email valide';
                                        }
                                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                                          return 'Entrez un email valide';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 25),
                                    ElevatedButton(
                                      onPressed: updateProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.9),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        elevation: 5,
                                        shadowColor: Colors.black.withOpacity(0.3),
                                      ),
                                      child: Text('Mettre à jour',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // partie commandes
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.shopping_bag, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text('Mes commandes',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  isLoadingOrders
                                      ? const Center(child: CircularProgressIndicator())
                                      : orders.isEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: Text(
                                                  'Vous n\'avez aucune commande pour le moment.',
                                                  style: GoogleFonts.montserrat(
                                                      color: Colors.white70)),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: orders.length,
                                              itemBuilder: (context, index) =>
                                                  _buildOrderItem(orders[index]),
                                            ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // partie Favorites 
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.favorite, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text('Mes favoris',
                                          style: GoogleFonts.montserrat(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  isLoadingFavorites
                                      ? const Center(child: CircularProgressIndicator())
                                      : favorites.isEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: Text(
                                                  'Vous n\'avez aucun favori pour le moment.',
                                                  style: GoogleFonts.montserrat(
                                                      color: Colors.white70)),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: favorites.length,
                                              itemBuilder: (context, index) =>
                                                  _buildFavoriteItem(favorites[index]),
                                            ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}