import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // Import kDebugMode
import 'package:flutter_svg/flutter_svg.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? _errorMessage;

  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _errorMessage = null; // Clear previous errors
    });
    if (kDebugMode) {
      print("AuthPage: Tentative de connexion par email/mot de passe...");
      print("AuthPage: Email: ${_emailController.text}");
    }
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (kDebugMode) {
        print(
          "AuthPage: ✅ Connexion réussie pour ${userCredential.user?.email}",
        );
      }
      // Navigate to home page and remove all previous routes
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
          "AuthPage: ❌ Erreur de connexion Firebase: ${e.code} - ${e.message}",
        );
      }
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (kDebugMode) {
        print("AuthPage: 💥 Erreur inattendue lors de la connexion: $e");
      }
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _registerWithEmailAndPassword() async {
    setState(() {
      _errorMessage = null; // Clear previous errors
    });
    if (kDebugMode) {
      print("AuthPage: Tentative d'inscription par email/mot de passe...");
      print("AuthPage: Email: ${_emailController.text}");
    }
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (kDebugMode) {
        print(
          "AuthPage: ✅ Inscription réussie pour ${userCredential.user?.email}",
        );
      }
      // Navigate to home page and remove all previous routes
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
          "AuthPage: ❌ Erreur d'inscription Firebase: ${e.code} - ${e.message}",
        );
      }
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (kDebugMode) {
        print("AuthPage: 💥 Erreur inattendue lors de l'inscription: $e");
      }
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null; // Clear previous errors
    });
    if (kDebugMode) {
      print("AuthPage: Tentative de connexion avec Google...");
    }
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        if (kDebugMode) {
          print("AuthPage: ❌ Connexion Google annulée par l'utilisateur.");
        }
        return;
      }

      if (kDebugMode) {
        print(
          "AuthPage: ✅ Utilisateur Google sélectionné: ${googleUser.email}",
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (kDebugMode) {
        print(
          "AuthPage: Access Token Google: ${googleAuth.accessToken != null ? '✅ Obtenu' : '❌ Manquant'}",
        );
        print(
          "AuthPage: ID Token Google: ${googleAuth.idToken != null ? '✅ Obtenu' : '❌ Manquant'}",
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print("AuthPage: Création du credential Firebase...");
      }
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (kDebugMode) {
        print(
          "AuthPage: ✅ Connexion Firebase avec Google réussie pour ${userCredential.user?.email}",
        );
      }
      // Navigate to home page and remove all previous routes
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
          "AuthPage: ❌ Erreur Firebase Auth (Google): ${e.code} - ${e.message}",
        );
      }
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (kDebugMode) {
        print("AuthPage: 💥 Erreur inattendue lors de la connexion Google: $e");
        print("AuthPage: Stack Trace: ${StackTrace.current}");
      }
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentification'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInWithEmailAndPassword,
              child: const Text('Se connecter'),
            ),
            TextButton(
              onPressed: _registerWithEmailAndPassword,
              child: const Text('Créer un compte'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              icon: SvgPicture.asset(
                'assets/images/google-logo.svg',
                height: 24.0,
                width: 24.0,
              ),
              label: const Text('Se connecter avec Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
