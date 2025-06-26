import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _usersCollection = 'users';
  static const String _preferencesCollection = 'user_preferences';
  static const String _ordersCollection = 'orders';
  static const String _favoritesCollection = 'favorites';

  // Obtenir l'ID de l'utilisateur actuel
  static String? get currentUserId => _auth.currentUser?.uid;

  // === GESTION DU PROFIL UTILISATEUR ===
  
  /// Créer un profil utilisateur lors de l'inscription
  static Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String email,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      Map<String, dynamic> userData = {
        'displayName': displayName,
        'email': email,
        'role': 'user', // Rôle par défaut pour les nouveaux utilisateurs
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Ajouter les champs optionnels s'ils sont fournis
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        userData['phoneNumber'] = phoneNumber;
      }
      if (photoURL != null && photoURL.isNotEmpty) {
        userData['photoURL'] = photoURL;
      }

      await _firestore.collection(_usersCollection).doc(uid).set(userData);
      
      if (kDebugMode) {
        print('✅ Profil utilisateur créé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la création du profil: $e');
      }
      rethrow;
    }
  }

  /// Créer ou mettre à jour le profil utilisateur
  static Future<void> createOrUpdateUserProfile({
    required String displayName,
    required String email,
    String? phoneNumber,
    String? photoURL,
  }) async {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');

    try {
      // Récupérer le profil existant pour conserver le rôle
      DocumentSnapshot userDoc = await _firestore.collection(_usersCollection).doc(currentUserId).get();
      String currentRole = 'user'; // Valeur par défaut
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        currentRole = userData['role'] ?? 'user';
      }

      // Préparer les données pour Firestore (avec tous les champs requis)
      Map<String, dynamic> userData = {
        'displayName': displayName,
        'email': email,
        'role': currentRole, // Conserver le rôle existant
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Ajouter les champs optionnels s'ils sont fournis
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        userData['phoneNumber'] = phoneNumber;
      }
      if (photoURL != null && photoURL.isNotEmpty) {
        userData['photoURL'] = photoURL;
      }

      // Si c'est la première fois, ajouter createdAt
      if (!userDoc.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_usersCollection).doc(currentUserId).set(
        userData,
        SetOptions(merge: true),
      );

      if (kDebugMode) {
        print('✅ Profil utilisateur mis à jour dans Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la mise à jour du profil: $e');
      }
      rethrow;
    }
  }

  /// Récupérer le profil utilisateur
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore.collection(_usersCollection).doc(currentUserId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération du profil: $e');
      }
      return null;
    }
  }

  // === GESTION DES PRÉFÉRENCES ===
  
  /// Sauvegarder les préférences culinaires
  static Future<void> saveUserPreferences({
    required Set<String> cuisineTypes,
    required Set<String> dietaryRestrictions,
    required Set<String> difficultyLevels,
  }) async {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');

    try {
      await _firestore.collection(_preferencesCollection).doc(currentUserId).set({
        'cuisineTypes': cuisineTypes.toList(),
        'dietaryRestrictions': dietaryRestrictions.toList(),
        'difficultyLevels': difficultyLevels.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Préférences sauvegardées dans Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la sauvegarde des préférences: $e');
      }
      rethrow;
    }
  }

  /// Récupérer les préférences culinaires
  static Future<Map<String, Set<String>>> getUserPreferences() async {
    if (currentUserId == null) {
      return {
        'cuisineTypes': <String>{},
        'dietaryRestrictions': <String>{},
        'difficultyLevels': <String>{},
      };
    }

    try {
      final doc = await _firestore.collection(_preferencesCollection).doc(currentUserId).get();
      
      if (!doc.exists) {
        return {
          'cuisineTypes': <String>{},
          'dietaryRestrictions': <String>{},
          'difficultyLevels': <String>{},
        };
      }

      final data = doc.data()!;
      return {
        'cuisineTypes': Set<String>.from(data['cuisineTypes'] ?? []),
        'dietaryRestrictions': Set<String>.from(data['dietaryRestrictions'] ?? []),
        'difficultyLevels': Set<String>.from(data['difficultyLevels'] ?? []),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des préférences: $e');
      }
      return {
        'cuisineTypes': <String>{},
        'dietaryRestrictions': <String>{},
        'difficultyLevels': <String>{},
      };
    }
  }

  // === GESTION DES COMMANDES ===
  
  /// Récupérer l'historique des commandes
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    if (currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des commandes: $e');
      }
      return [];
    }
  }

  /// Créer une commande d'exemple (pour les tests)
  static Future<void> createSampleOrder() async {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');

    try {
      await _firestore.collection(_ordersCollection).add({
        'userId': currentUserId,
        'orderId': '#CMD${DateTime.now().millisecondsSinceEpoch}',
        'total': '25000',
        'currency': 'FCFA',
        'status': 'Livré',
        'items': [
          {'name': 'Épices berbères', 'quantity': 1, 'price': '5000'},
          {'name': 'Huile d\'olive', 'quantity': 2, 'price': '12000'},
          {'name': 'Riz basmati', 'quantity': 1, 'price': '8000'},
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Commande d\'exemple créée');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la création de la commande: $e');
      }
      rethrow;
    }
  }

  // === GESTION DES FAVORIS ===
  
  /// Ajouter une recette aux favoris
  static Future<void> addToFavorites(String recipeId) async {
    if (currentUserId == null) throw Exception('Utilisateur non connecté');

    try {
      await _firestore.collection(_favoritesCollection).add({
        'userId': currentUserId,
        'recipeId': recipeId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Recette ajoutée aux favoris');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'ajout aux favoris: $e');
      }
      rethrow;
    }
  }

  /// Récupérer le nombre de favoris
  static Future<int> getFavoritesCount() async {
    if (currentUserId == null) return 0;

    try {
      final querySnapshot = await _firestore
          .collection(_favoritesCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors du comptage des favoris: $e');
      }
      return 0;
    }
  }

  /// Récupérer le nombre de commandes
  static Future<int> getOrdersCount() async {
    if (currentUserId == null) return 0;

    try {
      final querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors du comptage des commandes: $e');
      }
      return 0;
    }
  }

  // === STATISTIQUES ===
  
  /// Récupérer les statistiques du profil
  static Future<Map<String, int>> getProfileStats() async {
    try {
      final futures = await Future.wait([
        getFavoritesCount(),
        getOrdersCount(),
      ]);

      return {
        'favorites': futures[0],
        'orders': futures[1],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des statistiques: $e');
      }
      return {
        'favorites': 0,
        'orders': 0,
      };
    }
  }
}
