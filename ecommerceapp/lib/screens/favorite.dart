import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shoes_details.dart';

class FavoritesScreen extends StatefulWidget {
  final String token;
  final String userId;

  const FavoritesScreen({required this.token, required this.userId, super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> favorites = [];
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';

  final String backgroundImageUrl = 'http://localhost:5000/images/background.png';

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/favorites/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          favorites = json.decode(response.body);
          isLoading = false;
          isError = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = 'Failed to load favorites: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> removeFavorite(String shoeId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/favorites'),
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
          const SnackBar(content: Text('Removed from favorites'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove favorite'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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

  Widget _buildFavoriteItem(dynamic shoe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shoe['price']?.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Votre Favoris',
          style: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.6), // assombrit le fond
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (isError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Montserrat'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: fetchFavorites,
                    child: const Text('Try Again', style: TextStyle(fontFamily: 'Montserrat')),
                  ),
                ],
              ),
            )
          else if (favorites.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'No favorites yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap the heart icon to add items to favorites',
                    style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Montserrat'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Browse Shoes', style: TextStyle(fontFamily: 'Montserrat')),
                  ),
                ],
              ),
            )
          else
            RefreshIndicator(
              onRefresh: fetchFavorites,
              color: Colors.white,
              backgroundColor: Colors.black,
              child: ListView.builder(
                padding: EdgeInsets.only(top: kToolbarHeight + 20, bottom: 20),
                itemCount: favorites.length,
                itemBuilder: (context, index) => _buildFavoriteItem(favorites[index]),
              ),
            ),
        ],
      ),
    );
  }
}
