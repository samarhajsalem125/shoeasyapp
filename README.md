# 👟 ShoEasy

**ShoEasy** est une application mobile e-commerce dédiée à la vente de chaussures. Ce projet a été réalisé dans le cadre d'un **Projet de Fin d'Études (PFE)** afin de mettre en pratique les compétences en développement mobile, développement backend et gestion de bases de données.

---

## 📱 Aperçu

ShoEasy permet aux utilisateurs de :

* 🔐 Créer un compte et se connecter.
* 👟 Parcourir une large collection de chaussures.
* 🔍 Rechercher des produits par nom ou catégorie.
* ❤️ Ajouter des produits aux favoris.
* 🛒 Ajouter des articles au panier.
* 📦 Passer des commandes.
* 👤 Gérer leur profil personnel.
* 📜 Consulter l'historique des commandes.

L'administrateur peut :

* ➕ Ajouter de nouveaux produits.
* ✏️ Modifier les informations des produits.
* ❌ Supprimer des produits.
* 📊 Gérer les commandes des clients.
* 👥 Gérer les utilisateurs.

---

## 🛠️ Technologies utilisées

### Frontend (Mobile)

* Flutter
* Dart
* Provider / Bloc (selon votre architecture)
* HTTP Package

### Backend

* Node.js
* Express.js

### Base de données

* MongoDB
* Mongoose

### Outils

* Git & GitHub
* Postman
* Visual Studio Code
* Android Studio

---

## 📂 Architecture du projet

```text
ShoEasy/
│
├── frontend/          # Application Flutter
│
├── backend/           # API Node.js + Express
│
├── database/          # Scripts ou configuration MongoDB
│
└── README.md
```

---

## ⚙️ Installation

### 1. Cloner le projet

```bash
git clone https://github.com/your-username/shoeasy.git
cd shoeasy
```

---

### 2. Lancer le Backend

```bash
cd backend
npm install
npm start
```

Le serveur sera lancé sur :

```text
http://localhost:5000
```

---

### 3. Lancer l'application Flutter

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🔑 Variables d'environnement

Créer un fichier **.env** dans le dossier backend :

```env
PORT=5000

MONGODB_URI=your_mongodb_connection

JWT_SECRET=your_secret_key
```

---

## 📸 Captures d'écran

Ajoutez ici des captures d'écran de votre application.

* Écran de connexion
* Accueil
* Liste des produits
* Détails du produit
* Panier
* Paiement
* Profil

---

## 🚀 Fonctionnalités

* Authentification JWT
* Gestion des utilisateurs
* Gestion des produits
* Recherche de produits
* Panier dynamique
* Liste de favoris
* Gestion des commandes
* API REST
* Base de données MongoDB

---

## 📌 API Principales

### Auth

```
POST /api/auth/register
POST /api/auth/login
```

### Produits

```
GET /api/products
GET /api/products/:id
POST /api/products
PUT /api/products/:id
DELETE /api/products/:id
```

### Panier

```
GET /api/cart
POST /api/cart
DELETE /api/cart/:id
```

### Commandes

```
POST /api/orders
GET /api/orders
```

---

## 👨‍💻 Auteur

Projet réalisé par **samar haj salem**

Projet de Fin d'Études (PFE)

Année universitaire : **2025 - 2026**

---

## 📄 Licence

Ce projet est réalisé uniquement à des fins pédagogiques dans le cadre d'un Projet de Fin d'Études.
