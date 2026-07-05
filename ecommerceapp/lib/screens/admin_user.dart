import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart'; // Import pour Google Fonts

class AdminUsersScreen extends StatefulWidget {
  final String token;

  const AdminUsersScreen({required this.token, super.key});

  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List users = [];
  bool isLoading = false;
  String? errorMessage;

  final _formKey = GlobalKey<FormState>();
  String? _username;
  String? _email;
  String? _role;

  bool isEditing = false;
  String? editingUserId;

  final Color primaryColor = const Color.fromARGB(255, 207, 144, 218);
  final Color primaryDarkColor = const Color.fromARGB(255, 141, 110, 160)!;
  final Color primaryLightColor = Colors.purple[200]!;
  final Color backgroundColor = Colors.grey[100]!;

  // Style de texte avec Montserrat
  TextStyle get montserratStyle => GoogleFonts.montserrat();
  TextStyle get montserratBoldStyle => GoogleFonts.montserrat(fontWeight: FontWeight.bold);
  TextStyle get montserratMediumStyle => GoogleFonts.montserrat(fontWeight: FontWeight.w500);

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/admin/users'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load users';
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

  Future<List> fetchUserFavorites(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/admin/users/$userId/favorites'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec de la récupération des favoris');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  void showFavoritesDialog(List favorites) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Produits favoris',
          style: montserratBoldStyle,
        ),
        content: Container(
          width: double.maxFinite,
          child: favorites.isEmpty
              ? Text(
                  'Aucun produit favori',
                  style: montserratStyle,
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: favorites.length,
                  itemBuilder: (ctx, index) {
                    final product = favorites[index];
                    return ListTile(
                      leading: product['image'] != null
                          ? Image.network(
                              'http://localhost:5000/images/${product['image']}',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported),
                      title: Text(
                        product['name'] ?? 'Produit sans nom',
                        style: montserratStyle,
                      ),
                      subtitle: Text(
                        product['description'] ?? '',
                        style: montserratStyle,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Fermer',
              style: montserratStyle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addOrUpdateUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userData = {
      'username': _username,
      'email': _email,
      'role': _role,
    };

    try {
      http.Response response;
      if (isEditing && editingUserId != null) {
        response = await http.put(
          Uri.parse('http://localhost:5000/api/admin/users/$editingUserId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
          body: json.encode(userData),
        );
      } else {
        return; // Pas de création ici
      }

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save user',
              style: montserratStyle,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: montserratStyle,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void startEditUser(Map user) {
    setState(() {
      isEditing = true;
      editingUserId = user['_id'];
      _username = user['username'];
      _email = user['email'];
      _role = user['role'];
    });
    showUserForm();
  }

  void showUserForm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          isEditing ? 'Modifier l\'utilisateur' : 'Ajouter un utilisateur',
          style: montserratBoldStyle.copyWith(color: primaryDarkColor),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  initialValue: _username,
                  style: montserratStyle,
                  decoration: InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    labelStyle: montserratStyle.copyWith(color: primaryColor),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Entrez un nom d\'utilisateur' : null,
                  onSaved: (value) => _username = value,
                ),
                TextFormField(
                  initialValue: _email,
                  style: montserratStyle,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: montserratStyle.copyWith(color: primaryColor),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Entrez un email' : null,
                  onSaved: (value) => _email = value,
                ),
                TextFormField(
                  initialValue: _role,
                  style: montserratStyle,
                  decoration: InputDecoration(
                    labelText: 'Rôle',
                    labelStyle: montserratStyle.copyWith(color: primaryColor),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Entrez un rôle' : null,
                  onSaved: (value) => _role = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                isEditing = false;
                editingUserId = null;
                _username = null;
                _email = null;
                _role = null;
              });
            },
            child: Text(
              'Annuler',
              style: montserratStyle.copyWith(color: primaryDarkColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: addOrUpdateUser,
            child: Text(
              'Enregistrer',
              style: montserratStyle.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/admin/users/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Échec de la suppression de l\'utilisateur',
              style: montserratStyle,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: $e',
            style: montserratStyle,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget userItem(Map user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 3,
      child: ListTile(
        title: Text(
          user['username'],
          style: montserratBoldStyle.copyWith(color: primaryDarkColor),
        ),
        subtitle: Text(
          '${user['email']} - Rôle: ${user['role']}',
          style: montserratStyle.copyWith(color: Colors.grey[700]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.favorite, color: Colors.redAccent),
              onPressed: () async {
                try {
                  final favorites = await fetchUserFavorites(user['_id']);
                  showFavoritesDialog(favorites);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString(),
                        style: montserratStyle,
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              tooltip: 'Voir favoris',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: primaryColor),
              onPressed: () => startEditUser(user),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteUser(user['_id']),
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Gestion des Utilisateurs',
          style: montserratBoldStyle.copyWith(color: Colors.white),
        ),
        backgroundColor: primaryDarkColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              'http://localhost:5000/images/userbackround.png',
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          Positioned.fill(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  )
                : errorMessage != null
                    ? Center(
                        child: Text(
                          errorMessage!,
                          style: montserratStyle.copyWith(color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (ctx, index) => userItem(users[index]),
                      ),
          ),
        ],
      ),
    );
  }
}