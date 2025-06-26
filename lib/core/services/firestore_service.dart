import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Profile Methods
  static Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String email,
    String? phoneNumber,
    String role = 'user',
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  static Future<Map<String, dynamic>?> getUserProfile([String? uid]) async {
    try {
      final userId = uid ?? _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération du profil: $e');
      }
      return null;
    }
  }

  static Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (additionalData != null) updateData.addAll(additionalData);

      await _firestore.collection('users').doc(uid).update(updateData);
      if (kDebugMode) {
        print('✅ Profil utilisateur mis à jour avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la mise à jour du profil: $e');
      }
      rethrow;
    }
  }

  // Favorites Methods
  static Future<void> addToFavorites(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await _firestore.collection('favorites').add({
        'userId': userId,
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

  static Future<void> removeFromFavorites(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final query = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('recipeId', isEqualTo: recipeId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
      if (kDebugMode) {
        print('✅ Recette supprimée des favoris');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la suppression des favoris: $e');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Requête simplifiée sans orderBy pour éviter l'index composite
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> favoriteRecipes = [];

      for (var doc in favoritesSnapshot.docs) {
        final favoriteData = doc.data();
        final recipeId = favoriteData['recipeId'];

        // Récupérer les détails de la recette
        final recipeDoc = await _firestore
            .collection('recipes')
            .doc(recipeId)
            .get();

        if (recipeDoc.exists) {
          final recipeData = recipeDoc.data()!;
          recipeData['id'] = recipeDoc.id;
          recipeData['favoriteId'] = doc.id;
          favoriteRecipes.add(recipeData);
        }
      }

      // Trier localement par date de création du favori
      favoriteRecipes.sort((a, b) {
        final aTime = favoritesSnapshot.docs
            .firstWhere((doc) => doc.id == a['favoriteId'])
            .data()['createdAt'] as Timestamp?;
        final bTime = favoritesSnapshot.docs
            .firstWhere((doc) => doc.id == b['favoriteId'])
            .data()['createdAt'] as Timestamp?;

        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return favoriteRecipes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des favoris: $e');
      }
      return [];
    }
  }

  static Future<bool> isFavorite(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final query = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('recipeId', isEqualTo: recipeId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la vérification des favoris: $e');
      }
      return false;
    }
  }

  // Recipes Methods
  static Future<List<Map<String, dynamic>>> getRecipes({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('recipes');

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      final recipes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return recipes.where((recipe) {
          final title = recipe['title']?.toString().toLowerCase() ?? '';
          final description = recipe['description']?.toString().toLowerCase() ?? '';
          final search = searchQuery.toLowerCase();
          return title.contains(search) || description.contains(search);
        }).toList();
      }

      return recipes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des recettes: $e');
      }
      return [];
    }
  }

  // Products Methods
  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('products');

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      query = query.orderBy('name').limit(limit);

      final snapshot = await query.get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return products.where((product) {
          final name = product['name']?.toString().toLowerCase() ?? '';
          final search = searchQuery.toLowerCase();
          return name.contains(search);
        }).toList();
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération des produits: $e');
      }
      return [];
    }
  }

  // User History Methods
  static Future<void> addToHistory(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Remove existing history entry for this recipe
      final existingQuery = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .where('recipeId', isEqualTo: recipeId)
          .get();

      for (var doc in existingQuery.docs) {
        await doc.reference.delete();
      }

      // Add new history entry
      await _firestore.collection('history').add({
        'userId': userId,
        'recipeId': recipeId,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'ajout à l\'historique: $e');
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getUserHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final historyQuery = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .orderBy('viewedAt', descending: true)
          .limit(50)
          .get();

      final List<Map<String, dynamic>> history = [];
      
      for (var historyDoc in historyQuery.docs) {
        final recipeId = historyDoc.data()['recipeId'];
        final recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
        
        if (recipeDoc.exists) {
          final recipeData = recipeDoc.data()!;
          recipeData['id'] = recipeDoc.id;
          recipeData['viewedAt'] = historyDoc.data()['viewedAt'];
          history.add(recipeData);
        }
      }

      return history;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la récupération de l\'historique: $e');
      }
      return [];
    }
  }

  // Orders Methods
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final ordersQuery = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return ordersQuery.docs.map((doc) {
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
}
