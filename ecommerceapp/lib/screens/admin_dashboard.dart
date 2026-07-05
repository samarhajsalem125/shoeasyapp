import 'package:ecommerceapp/screens/admin_return.dart';
import 'package:flutter/material.dart';

// Importation des autres écrans d'administration
import 'admin_order.dart';
import 'admin_product.dart';
import 'admin_user.dart';

/// Écran principal du tableau de bord administrateur
/// Affiche des cartes cliquables pour naviguer vers les différentes sections d'administration
class AdminDashboard extends StatelessWidget {
  final String token; // Token d'authentification pour les requêtes API

  const AdminDashboard({required this.token, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Configuration de l'AppBar
      appBar: AppBar(
        title: const Text(
          'Tableau de bord Admin',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0, // Supprime l'ombre de l'AppBar
      ),
      extendBodyBehindAppBar: true, // Permet au body d'étendre derrière l'AppBar
      
      // Corps de la page - Grille de cartes
      body: GridView.count(
        crossAxisCount: 2, // 2 colonnes
        padding: const EdgeInsets.all(20), // Marge autour de la grille
        children: [
          // Carte pour la gestion des produits
          _buildDashboardCard(
            context,
            Icons.shopping_bag,
            'Chaussures',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminProductsScreen(token: token),
              ),
            ),
          ),
          
          // Carte pour la gestion des commandes
          _buildDashboardCard(
            context,
            Icons.receipt_long,
            'Commandes',
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminOrdersScreen(token: token),
              ),
            ),
          ),
          
          // Carte pour la gestion des utilisateurs
          _buildDashboardCard(
            context,
            Icons.people,
            'Utilisateurs',
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminUsersScreen(token: token),
              ),
            ),
          ),
          
          // Carte pour la gestion des retours
          _buildDashboardCard(
            context,
            Icons.keyboard_return,
            'Retours',
            const Color.fromARGB(255, 0, 255, 179),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminReturnsScreen(token: token),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Méthode helper pour construire une carte du tableau de bord
  /// 
  /// Paramètres:
  /// - context: Le contexte BuildContext
  /// - icon: L'icône à afficher
  /// - title: Le titre de la carte
  /// - color: La couleur de fond de la carte
  /// - onTap: Fonction à exécuter lors du clic sur la carte
  Widget _buildDashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 5, // Ombre portée
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Bords arrondis
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap, // Gestion du clic
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color], // Dégradé (ici une seule couleur)
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          // Contenu de la carte (icône + titre)
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10), // Espacement
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}