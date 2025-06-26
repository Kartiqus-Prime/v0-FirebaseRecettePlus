import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Configuration spécifique pour Android
    serverClientId: kDebugMode 
        ? null // Laisser null en debug pour utiliser la config automatique
        : "361640124056-e196o9u9pe0rdg35uj4054k4rjplmfec.apps.googleusercontent.com",
  );
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Vérifier la disponibilité des Google Play Services
      if (kDebugMode) {
        print('🔍 Vérification des Google Play Services...');
      }
      
      // Déconnecter complètement d'abord
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      if (kDebugMode) {
        print('🚀 Démarrage de la connexion Google...');
        print('📱 Package: com.recetteplus.app');
      }

      // Déclencher le flux d'authentification avec gestion d'erreur spécifique
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().catchError((error) {
        if (kDebugMode) {
          print('❌ Erreur lors de signIn: $error');
          if (error.toString().contains('ApiException: 10')) {
            print('🔧 Erreur ApiException 10 - Problème de configuration SHA-1');
            print('📋 Vérifiez:');
            print('   1. SHA-1 ajouté dans Firebase Console');
            print('   2. Package name: com.recetteplus.app');
            print('   3. google-services.json à jour');
            print('   4. Google Sign-In activé dans Firebase Auth');
          }
        }
        throw error;
      });
      
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
        print('📍 Stack Trace: ${StackTrace.current}');
        
        // Diagnostic spécifique pour ApiException 10
        if (e.toString().contains('ApiException: 10')) {
          print('');
          print('🚨 DIAGNOSTIC ApiException 10:');
          print('   Cette erreur indique un problème de configuration SHA-1');
          print('   ou de package name dans Firebase Console.');
          print('');
          print('🔧 SOLUTION:');
          print('   1. Générez votre SHA-1: ./gradlew signingReport');
          print('   2. Ajoutez-le dans Firebase Console');
          print('   3. Téléchargez le nouveau google-services.json');
          print('   4. Redémarrez l\'app');
          print('');
        }
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

  // Méthode de diagnostic
  static Future<void> diagnoseConfiguration() async {
    if (kDebugMode) {
      print('🔍 DIAGNOSTIC GOOGLE SIGN-IN:');
      print('📱 Package: com.recetteplus.app');
      
      try {
        final isSignedIn = await _googleSignIn.isSignedIn();
        print('🔐 Déjà connecté: $isSignedIn');
        
        if (isSignedIn) {
          final currentUser = _googleSignIn.currentUser;
          print('👤 Utilisateur actuel: ${currentUser?.email}');
        }
      } catch (e) {
        print('❌ Erreur de diagnostic: $e');
      }
    }
  }
}
