import 'package:flutter/material.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Image de fond
          SizedBox.expand(
            child: Image.network(
              'http://localhost:5000/images/shoesbackround.jpg', // Remplace si besoin par un bon chemin local ou réseau
              fit: BoxFit.cover,
            ),
          ),

          // Overlay sombre pour lisibilité
          Container(
            // Tu peux ajouter une couleur sombre avec transparence ici si besoin
          ),

          // Contenu centré
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "ShoeEasy", // Nom de l'app, peut rester en anglais si c'est une marque
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Des chaussures de qualité livrées chez vous",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Commencer',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
