import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetteplus/core/services/firestore_service.dart';
import 'package:recetteplus/core/services/google_sign_in_service.dart'; // Import GoogleSignInService
import 'package:flutter/foundation.dart'; // Import kDebugMode
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/social_button.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Diagnostic au démarrage
    GoogleSignInService.diagnoseConfiguration();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (kDebugMode) {
      print("SignInPage: Tentative de connexion par email/mot de passe...");
      print("SignInPage: Email: ${_emailController.text}");
    }

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (kDebugMode) {
        print("SignInPage: ✅ Connexion réussie pour ${userCredential.user?.email}");
      }
      // La redirection sera gérée automatiquement par le StreamBuilder dans main.dart
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("SignInPage: ❌ Erreur de connexion Firebase: ${e.code} - ${e.message}");
      }
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      if (kDebugMode) {
        print("SignInPage: 💥 Erreur inattendue lors de la connexion: $e");
      }
      setState(() {
        _errorMessage = AppStrings.unknownError;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    if (kDebugMode) {
      print("SignInPage: Tentative de connexion avec Google...");
    }

    try {
      final UserCredential? userCredential =
          await GoogleSignInService.signInWithGoogle();

      if (userCredential == null) {
        if (kDebugMode) {
          print("SignInPage: ❌ Connexion Google annulée par l'utilisateur.");
        }
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      // Vérifier si le profil utilisateur existe, sinon le créer
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        if (kDebugMode) {
          print("SignInPage: Création du profil utilisateur Firestore pour Google Sign-In...");
        }
        await FirestoreService.createUserProfile(
          uid: userCredential.user!.uid,
          displayName: userCredential.user!.displayName ?? 'Utilisateur',
          email: userCredential.user!.email ?? '',
          photoURL: userCredential.user!.photoURL,
        );
        if (kDebugMode) {
          print("SignInPage: ✅ Profil utilisateur Firestore créé.");
        }
      } else {
        if (kDebugMode) {
          print("SignInPage: Profil utilisateur Firestore existant pour Google Sign-In.");
        }
      }

      if (kDebugMode) {
        print("SignInPage: ✅ Connexion Google réussie: ${userCredential.user!.displayName}");
      }
      // Succès - la redirection sera gérée par le StreamBuilder
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("SignInPage: ❌ Erreur Firebase Auth (Google): ${e.code} - ${e.message}");
      }
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      String errorMsg = "Erreur de connexion Google";

      if (e.toString().contains('ApiException: 10')) {
        errorMsg =
            "Configuration Google Sign-In incorrecte.Vérifiez le SHA-1 dans Firebase Console.";        if (kDebugMode) {
          print("SignInPage: 💥 Erreur ApiException 10 détectée. Affichage du dialogue de configuration.");
        }
      }

      setState(() {
        _errorMessage = errorMsg;
      });

      // Afficher une boîte de dialogue avec les instructions
      if (mounted && e.toString().contains('ApiException: 10')) {
        _showConfigurationDialog();
      }
      if (kDebugMode) {
        print("SignInPage: 💥 Erreur inattendue lors de la connexion Google: $e");
        print("SignInPage: Stack Trace: ${StackTrace.current}");
      }
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppColors.error),
            SizedBox(width: 8),
            Text("Configuration requise"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pour utiliser Google Sign-In, suivez ces étapes:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text("1. Générez votre SHA-1:"),
            Text(
              "   cd android && ./gradlew signingReport",
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Color(0xFFF5F5F5),
              ),
            ),
            SizedBox(height: 8),
            Text("2. Ajoutez le SHA-1 dans Firebase Console"),
            SizedBox(height: 8),
            Text("3. Téléchargez le nouveau google-services.json"),
            SizedBox(height: 8),
            Text("4. Redémarrez l'application"),
            SizedBox(height: 16),
            Text(
              "Package name: com.recetteplus.app",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Compris"),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return "Aucun utilisateur trouvé avec cette adresse e-mail.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      case 'invalid-email':
        return "Adresse e-mail invalide.";
      case 'user-disabled':
        return "Ce compte a été désactivé.";
      case 'too-many-requests':
        return "Trop de tentatives. Veuillez réessayer plus tard.";
      default:
        return AppStrings.signInError;
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return "Un compte existe déjà avec cette adresse e-mail mais avec un autre fournisseur.";
      case 'invalid-credential':
        return "Les informations d'identification sont invalides.";
      case 'operation-not-allowed':
        return "La connexion Google n'est pas activée dans Firebase.";
      case 'user-disabled':
        return "Ce compte a été désactivé.";
      case 'user-not-found':
        return "Aucun utilisateur trouvé.";
      case 'wrong-password':
        return "Mot de passe incorrect.";
      default:
        return "Erreur lors de la connexion avec Google.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.signInToAccount,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Connectez-vous pour accéder à vos recettes favorites",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Message d'erreur
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Connexion Google en premier
                SocialButton(
                  text: AppStrings.signInWithGoogle,
                  iconPath: 'assets/images/google-logo.svg',
                  onPressed: _signInWithGoogle,
                  isLoading: _isGoogleLoading,
                ),
                const SizedBox(height: 24),

                // Séparateur
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppStrings.or,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 24),

                // Champs de saisie
                CustomTextField(
                  label: AppStrings.email,
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: AppStrings.password,
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                  isPassword: true,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implémenter la réinitialisation du mot de passe
                    },
                    child: Text(
                      AppStrings.forgotPassword,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Bouton de connexion
                CustomButton(
                  text: AppStrings.signIn,
                  onPressed: _signInWithEmailAndPassword,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 32),

                // Lien vers l'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.dontHaveAccount,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
                      child: Text(
                        AppStrings.signUp,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
