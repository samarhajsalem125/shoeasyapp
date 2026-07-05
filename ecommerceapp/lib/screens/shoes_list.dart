import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'favorite.dart';
import 'cart.dart';
import 'chatbot.dart';
import 'notification_screen.dart';
import 'profile.dart';

import 'return_screen.dart';
import 'shoes_details.dart';
import 'package:google_fonts/google_fonts.dart';

class ShoesListScreen extends StatefulWidget {
  final String token;
  final String userId;

  const ShoesListScreen({super.key, required this.token, required this.userId});

  @override
  State<ShoesListScreen> createState() => _ShoesListScreenState();
}

class _ShoesListScreenState extends State<ShoesListScreen> {
  List<dynamic> shoes = [];
  List<dynamic> filteredShoes = [];
  List<dynamic> recommendedShoes = [];
  Set<String> favoriteShoeIds = {};
  bool isLoading = true;
  bool isLoadingRecommendations = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isFrench = true;
  int notificationCount = 0;
  String selectedCategory = 'all';
  bool _showOnlyPromotions = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkForPromotions();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _fetchFavorites(),
        _fetchShoes(),
        _fetchNotifications(),
        _fetchRecommendations(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRecommendations() async {
    if (widget.userId.isEmpty) return;
    
    setState(() => isLoadingRecommendations = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/recommendations/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        setState(() {
          recommendedShoes = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
    } finally {
      setState(() => isLoadingRecommendations = false);
    }
  }

  Future<void> _fetchFavorites() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/favorites/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          favoriteShoeIds = (jsonDecode(response.body) as List)
              .map((shoe) => shoe['_id'].toString())
              .toSet();
        });
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  Future<void> _fetchShoes() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/shoes'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          shoes = jsonDecode(response.body);
          _applyFilters();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error fetching shoes: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/notifications/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final notifications = jsonDecode(response.body) as List;
        setState(() {
          notificationCount = notifications.where((n) => !n['isRead']).length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> _checkForPromotions() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/shoes/promotions/current?limit=3'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final promotions = jsonDecode(response.body) as List;
        if (promotions.isNotEmpty) {
          _showPromotionNotification(promotions);
        }
      }
    } catch (e) {
      debugPrint('Error checking promotions: $e');
    }
  }

  void _showPromotionNotification(List<dynamic> promotions) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFrench 
              ? '${promotions.length} nouvelles promotions disponibles!'
              : '${promotions.length} new promotions available!',
          style: GoogleFonts.montserrat(),
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: _isFrench ? 'Voir' : 'View',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _showOnlyPromotions = true;
              _applyFilters();
            });
          },
        ),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      filteredShoes = shoes.where((shoe) {
        if (_showOnlyPromotions && shoe['promotionPrice'] == null) {
          return false;
        }
        
        bool matchesCategory = selectedCategory == 'all' || shoe['category'] == selectedCategory;
        
        bool matchesSearch = _searchController.text.isEmpty ||
            shoe['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (shoe['brand']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
            (shoe['category']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
        
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(String shoeId) async {
    try {
      final isFavorite = favoriteShoeIds.contains(shoeId);
      final url = Uri.parse('http://localhost:5000/api/favorites');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };
      final body = jsonEncode({'userId': widget.userId, 'shoeId': shoeId});

      final response = isFavorite
          ? await http.delete(url, headers: headers, body: body)
          : await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          isFavorite ? favoriteShoeIds.remove(shoeId) : favoriteShoeIds.add(shoeId);
        });
        _fetchRecommendations();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isFrench ? 'Collection Chaussures' : 'Shoe Collection',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isFrench = !_isFrench),
            tooltip: _isFrench ? 'English' : 'Français',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(
                      token: widget.token,
                      userId: widget.userId,
                    ),
                  ),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FavoritesScreen(
                  token: widget.token,
                  userId: widget.userId,
                ),
              ),
            ),
          ),
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
          IconButton(
            icon: const Icon(Icons.person_2),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  token: widget.token,
                  userId: widget.userId,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.reset_tv_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>ReturnRequestNewScreen(
                  token: widget.token, 
                  userId: widget.userId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('http://localhost:5000/images/téléchargé (1).jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search and filter section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _isFrench ? 'Recherche...' : 'Search...',
                    hintStyle: GoogleFonts.montserrat(),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  style: GoogleFonts.montserrat(),
                  onChanged: (value) => _applyFilters(),
                ),
              ),
              
              // Category filters
              SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        _categoryButton('All'),
                        _categoryButton('Men'),
                        _categoryButton('Women'),
                        _categoryButton('Kids'),
                        const SizedBox(width: 8),
                        ToggleButtons(
                          isSelected: [_showOnlyPromotions],
                          onPressed: (index) {
                            setState(() {
                              _showOnlyPromotions = !_showOnlyPromotions;
                              _applyFilters();
                            });
                          },
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_offer, 
                                      color: _showOnlyPromotions ? Colors.white : Colors.purple),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isFrench ? 'Promotions' : 'Sales',
                                    style: GoogleFonts.montserrat(
                                      color: _showOnlyPromotions ? Colors.white : Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          color: Colors.purple,
                          selectedColor: Colors.white,
                          fillColor: Colors.purple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content with flexible space
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Main shoes list
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 340,
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Colors.purple,
                                ),
                              )
                            : filteredShoes.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        _isFrench ? 'Aucun résultat trouvé' : 'No results found',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    itemCount: filteredShoes.length,
                                    itemBuilder: (context, index) {
                                      final shoe = filteredShoes[index];
                                      final isFavorite = favoriteShoeIds.contains(shoe['_id']);
                                      final hasPromotion = shoe['promotionPrice'] != null;
                                      final discountPercent = hasPromotion
                                          ? (((shoe['price'] - shoe['promotionPrice']) / shoe['price']) * 100).round()
                                          : 0;

                                      return Container(
                                        width: 260,
                                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Card(
                                          elevation: 8,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(20),
                                            onTap: () => _navigateToDetails(shoe),
                                            child: Stack(
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    // Image container
                                                    Container(
                                                      height: 180,
                                                      decoration: BoxDecoration(
                                                        borderRadius: const BorderRadius.vertical(
                                                            top: Radius.circular(20)),
                                                        image: DecorationImage(
                                                          image: NetworkImage(shoe['imageUrl'] ?? ''),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    // Content section
                                                    Padding(
                                                      padding: const EdgeInsets.all(12.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            shoe['name'] ?? 'Unknown',
                                                            style: GoogleFonts.montserrat(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          if (hasPromotion)
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  '${shoe['price']?.toStringAsFixed(2)} DT',
                                                                  style: GoogleFonts.montserrat(
                                                                    fontSize: 14,
                                                                    color: Colors.grey,
                                                                    decoration: TextDecoration.lineThrough,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      '${shoe['promotionPrice']?.toStringAsFixed(2)} DT',
                                                                      style: GoogleFonts.montserrat(
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Colors.purple,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                          horizontal: 6, vertical: 2),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.purple.withOpacity(0.2),
                                                                        borderRadius: BorderRadius.circular(4),
                                                                      ),
                                                                      child: Text(
                                                                        '-$discountPercent%',
                                                                        style: GoogleFonts.montserrat(
                                                                          color: Colors.purple,
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            )
                                                          else
                                                            Text(
                                                              '${shoe['price']?.toStringAsFixed(2)} DT',
                                                              style: GoogleFonts.montserrat(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (hasPromotion)
                                                  Positioned(
                                                    top: 10,
                                                    left: 10,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.purple,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        _isFrench ? 'PROMO' : 'SALE',
                                                        style: GoogleFonts.montserrat(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                Positioned(
                                                  top: 10,
                                                  right: 10,
                                                  child: CircleAvatar(
                                                    backgroundColor: Colors.white,
                                                    child: IconButton(
                                                      icon: Icon(
                                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                                        color: isFavorite ? Colors.red : Colors.black54,
                                                      ),
                                                      onPressed: () => _toggleFavorite(shoe['_id']),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ),

                    // Recommendations section - Updated to prevent overflow
                    if (recommendedShoes.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 24, bottom: 8),
                                child: Text(
                                  _isFrench ? 'Recommandations pour vous' : 'Recommended for you',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 180,
                                  maxHeight: 220,
                                ),
                                child: isLoadingRecommendations
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.purple,
                                        ),
                                      )
                                    : ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        itemCount: recommendedShoes.length,
                                        itemBuilder: (context, index) {
                                          final shoe = recommendedShoes[index];
                                          final isFavorite = favoriteShoeIds.contains(shoe['_id']);
                                          final hasPromotion = shoe['promotionPrice'] != null;

                                          return Container(
                                            width: 140,
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Card(
                                              elevation: 5,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(15),
                                                onTap: () => _navigateToDetails(shoe),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Image with fixed aspect ratio
                                                    AspectRatio(
                                                      aspectRatio: 1,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: const BorderRadius.vertical(
                                                              top: Radius.circular(15)),
                                                          image: DecorationImage(
                                                            image: NetworkImage(shoe['imageUrl'] ?? ''),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Content with constrained height
                                                    Container(
                                                      height: 60,
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            shoe['name'] ?? 'Unknown',
                                                            style: GoogleFonts.montserrat(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            hasPromotion
                                                                ? '${shoe['promotionPrice']?.toStringAsFixed(2)} DT'
                                                                : '${shoe['price']?.toStringAsFixed(2)} DT',
                                                            style: GoogleFonts.montserrat(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: hasPromotion 
                                                                  ? Colors.purple 
                                                                  : Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatbotScreen(
                token: widget.token,
                userId: widget.userId,
              ),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 190, 139, 175),
        child: const Icon(Icons.support_agent, color: Colors.black),
      ),
    );
  }

  void _navigateToDetails(dynamic shoe) {
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

  Widget _categoryButton(String category) {
    final isSelected = selectedCategory == category.toLowerCase() || 
                      (category == 'All' && selectedCategory == 'all');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            selectedCategory = category.toLowerCase() == 'all' ? 'all' : category;
            _applyFilters();
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.purple.withOpacity(0.2) : null,
          side: BorderSide(
            color: isSelected ? Colors.purple : Colors.grey,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          category,
          style: GoogleFonts.montserrat(
            color: isSelected ? Colors.purple : Colors.black,
          ),
        ),
      ),
    );
  }
}