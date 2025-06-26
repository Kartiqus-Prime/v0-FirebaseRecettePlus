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

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Mettre à jour le nom d'affichage
      await userCredential.user?.updateDisplayName(_fullNameController.text.trim());

      // Créer le profil dans Firestore
      await FirestoreService.createUserProfile(
        uid: userCredential.user!.uid,
        displayName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
      );
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
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

    try {
      final UserCredential? userCredential = await GoogleSignInService.signInWithGoogle();
      
      if (userCredential == null) {
        // L'utilisateur a annulé la connexion
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      // Créer le profil dans Firestore s'il n'existe pas
      await FirestoreService.createOrUpdateUserProfile(
        displayName: userCredential.user?.displayName ?? 'Utilisateur',
        email: userCredential.user?.email ?? '',
        photoURL: userCredential.user?.photoURL,
      );

      // La redirection sera gérée automatiquement par le StreamBuilder dans main.dart
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'inscription avec Google. Vérifiez votre configuration.';
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
        return 'Cette adresse e-mail est déjà utilisée.';
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'operation-not-allowed':
        return 'L\'inscription par e-mail n\'est pas activée.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      default:
        return AppStrings.signUpError;
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cette adresse e-mail mais avec un autre fournisseur.';
      case 'invalid-credential':
        return 'Les informations d\'identification sont invalides.';
      case 'operation-not-allowed':
        return 'La connexion Google n\'est pas activée.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      default:
        return 'Erreur lors de l\'inscription avec Google.';
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
                      AppStrings.createAccount,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rejoignez-nous pour découvrir l\'univers des saveurs',
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
                        Icon(Icons.error_outline, color: AppColors.error, size: 20),
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
                  iconPath: 'https://blobs.vusercontent.net/blob/google-logo-ePwwr2o9C1PaCLZNuLkE9VgHSZA3ah.svg',
                  onPressed: _signUpWithGoogle,
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
                    Text(
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
                      child: Text(
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
