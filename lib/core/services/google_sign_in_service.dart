import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Forcer la sélection de compte
    forceCodeForRefreshToken: true,
  );
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Déconnecter complètement d'abord
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      if (kDebugMode) {
        print('🚀 Démarrage de la connexion Google...');
      }

      // Déclencher le flux d'authentification
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) {
          print('❌ Connexion Google annulée par l\'utilisateur');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ Utilisateur Google sélectionné: ${googleUser.email}');
        print('📧 Display Name: ${googleUser.displayName}');
        print('🆔 ID: ${googleUser.id}');
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (kDebugMode) {
        print('🔑 Access Token: ${googleAuth.accessToken != null ? "✅" : "❌"}');
        print('🎫 ID Token: ${googleAuth.idToken != null ? "✅" : "❌"}');
      }

      // Vérifier que nous avons les tokens nécessaires
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Tokens Google manquants');
      }

      // Créer un nouveau credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print('🔐 Credential créé, connexion à Firebase...');
      }

      // Connexion à Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (kDebugMode) {
        print('🎉 Connexion Firebase réussie!');
        print('👤 User: ${userCredential.user?.email}');
        print('📱 Provider: ${userCredential.user?.providerData.first.providerId}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥 Erreur Firebase Auth: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Erreur Google Sign-In: $e');
        print('📍 Stack trace: ${StackTrace.current}');
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
      if (kDebugMode) {
        print('👋 Déconnexion réussie');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la déconnexion: $e');
      }
    }
  }

  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
