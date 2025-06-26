import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      await _firestore.collection('users').doc(uid).set(userData);
      print('✅ Profil utilisateur créé avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création du profil: $e');
      rethrow;
    }
  }

  static Future<void> updateUserProfile({
    required String displayName,
    required String email,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer le profil existant pour conserver le rôle
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      String currentRole = 'user'; // Valeur par défaut
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        currentRole = userData['role'] ?? 'user';
      }

      // Mettre à jour Firebase Auth
      await user.updateDisplayName(displayName);
      await user.updateEmail(email);

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

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      print('✅ Profil utilisateur mis à jour avec succès');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }
}
