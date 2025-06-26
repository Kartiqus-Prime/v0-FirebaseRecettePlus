import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/services/google_sign_in_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/social_button.dart';
import 'sign_in_page.dart';
import 'package:flutter/foundation.dart'; // Import kDebugMode

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (kDebugMode) {
      print("SignUpPage: Tentative d'inscription par email/mot de passe...");
      print("SignUpPage: Email: ${_emailController.text}");
    }

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (kDebugMode) {
        print("SignUpPage: ✅ Inscription Firebase réussie pour ${userCredential.user?.email}");
        print("SignUpPage: Mise à jour du nom d'affichage de l'utilisateur...");
      }
      // Mettre à jour le nom d'affichage
      await userCredential.user?.updateDisplayName(_fullNameController.text.trim());
      if (kDebugMode) {
        print("SignUpPage: ✅ Nom d'affichage mis à jour.");
        print("SignUpPage: Création du profil Firestore...");
      }

      // Créer le profil dans Firestore
      await FirestoreService.createUserProfile(
        uid: userCredential.user!.uid,
        displayName: _fullNameController.text.trim(),
        email: userCredential.user!.email.toString().trim(),
      );
      if (kDebugMode) {
        print("SignUpPage: ✅ Profil Firestore créé pour ${userCredential.user?.email}");
      }
      Navigator.pop(context); // Pop back after successful sign-up
      
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("SignUpPage: ❌ Erreur Firebase Auth: ${e.code} - ${e.message}");
      }
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      if (kDebugMode) {
        print("SignUpPage: 💥 Erreur inattendue lors de l'inscription: $e");
        print("SignUpPage: Stack Trace: ${StackTrace.current}");
      }
      setState(() {
        _errorMessage = AppStrings.unknownError;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    if (kDebugMode) {
      print("SignUpPage: Tentative d'inscription avec Google...");
    }

    try {
      final UserCredential? userCredential = await GoogleSignInService.signInWithGoogle();
      
      if (userCredential == null) {
        // L'utilisateur a annulé la connexion
        if (kDebugMode) {
          print("SignUpPage: ❌ Inscription Google annulée par l'utilisateur.");
        }
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }
      if (kDebugMode) {
        print("SignUpPage: ✅ Connexion Google réussie: ${userCredential.user?.email}");
        print("SignUpPage: Vérification/Création du profil Firestore pour Google Sign-In...");
      }

      // Créer le profil dans Firestore s'il n'existe pas
      await FirestoreService.createOrUpdateUserProfile(
        displayName: userCredential.user?.displayName ?? 'Utilisateur',
        email: userCredential.user?.email ?? '',
        photoURL: userCredential.user?.photoURL,
      );

      if (kDebugMode) {
        print("SignUpPage: ✅ Profil Firestore créé/mis à jour pour Google Sign-In.");
      }
      Navigator.pop(context); // Pop back after successful Google sign-up
      
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("SignUpPage: ❌ Erreur Firebase Auth (Google): ${e.code} - ${e.message}");
      }
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      if (kDebugMode) {
        print("SignUpPage: 💥 Erreur inattendue lors de l'inscription avec Google: $e");
        print("SignUpPage: Stack Trace: ${StackTrace.current}");
      }
      setState(() {
        _errorMessage = "Erreur lors de l'inscription avec Google. Vérifiez votre configuration.";
      });
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "Cette adresse e-mail est déjà utilisée.";
      case 'invalid-email':
        return "Adresse e-mail invalide.";
      case 'operation-not-allowed':
        return "L'inscription par e-mail n'est pas activée.";
      case 'weak-password':
        return "Le mot de passe est trop faible.";
      default:
        return AppStrings.signUpError;
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return "Un compte existe déjà avec cette adresse e-mail mais avec un autre fournisseur.";
      case 'invalid-credential':
        return "Les informations d'identification sont invalides.";
      case 'operation-not-allowed':
        return "La connexion Google n'est pas activée.";
      case 'user-disabled':
        return "Ce compte a été désactivé.";
      default:
        return "Erreur lors de l'inscription avec Google.";
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.createAccount,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Rejoignez-nous pour découvrir l'univers des saveurs",
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
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
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
                  iconPath: 'https://blobs.vusercontent.net/blob/google-logo-ePwwr2o9C1PaCLZNuLkE9VgHSZA3ah.svg',
                  onPressed: _signUpWithGoogle,
                  isLoading: _isGoogleLoading,
                ),
                const SizedBox(height: 24),

                // Séparateur
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppStrings.or,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 24),

                // Champs de saisie
                CustomTextField(
                  label: AppStrings.fullName,
                  controller: _fullNameController,
                  validator: Validators.validateFullName,
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: AppStrings.email,
                  controller: _emailController,
                  validator: Validators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: AppStrings.password,
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: AppStrings.confirmPassword,
                  controller: _confirmPasswordController,
                  validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Bouton d'inscription
                CustomButton(
                  text: AppStrings.createAccount,
                  onPressed: _signUpWithEmailAndPassword,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 32),

                // Lien vers la connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.alreadyHaveAccount,
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
                            builder: (context) => const SignInPage(),
                          ),
                        );
                      },
                      child: const Text(
                        AppStrings.signIn,
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
