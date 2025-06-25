import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Déconnecter d'abord pour forcer la sélection de compte
      await _googleSignIn.signOut();
      
      if (kDebugMode) {
        print('Tentative de connexion Google...');
      }

      // Déclencher le flux d'authentification
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) {
          print('Connexion Google annulée par l\'utilisateur');
        }
        return null;
      }

      if (kDebugMode) {
        print('Utilisateur Google sélectionné: ${googleUser.email}');
      }

      // Obtenir les détails d'authentification de la demande
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (kDebugMode) {
        print('Token d\'accès obtenu: ${googleAuth.accessToken != null}');
        print('ID Token obtenu: ${googleAuth.idToken != null}');
      }

      // Créer un nouveau credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print('Credential créé, connexion à Firebase...');
      }

      // Une fois connecté, retourner le UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (kDebugMode) {
        print('Connexion Firebase réussie: ${userCredential.user?.email}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Erreur Firebase Auth: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur Google Sign-In: $e');
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la déconnexion: $e');
      }
    }
  }
}
