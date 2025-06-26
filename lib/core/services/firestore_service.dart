import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Requête simplifiée sans orderBy pour éviter l'index composite
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
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
      print('❌ Erreur lors de la récupération des favoris: $e');
      return [];
    }
  }
}
