import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifyingPhone = false;
  bool _phoneVerified = false;
  String? _verificationId;
  String? _currentPhoneNumber;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _currentPhoneNumber = user.phoneNumber;
      _phoneController.text = _currentPhoneNumber ?? '';
      _phoneVerified = _currentPhoneNumber != null;

      // Load additional data from Firestore
      final userData = await FirestoreService.getUserProfile();
      if (userData != null && mounted) {
        setState(() {
          _displayNameController.text = userData['displayName'] ?? '';
          if (userData['phoneNumber'] != null) {
            _phoneController.text = userData['phoneNumber'];
            _currentPhoneNumber = userData['phoneNumber'];
            _phoneVerified = true;
          }
        });
      }
    }
  }

  // Fonction pour formater le numéro de téléphone
  String _formatPhoneNumber(String phone) {
    // Supprimer tous les espaces et caractères spéciaux
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Si le numéro ne commence pas par +, ajouter le code pays par défaut
    if (!cleaned.startsWith('+')) {
      // Supposons que c'est un numéro français si pas de code pays
      if (cleaned.startsWith('0')) {
        cleaned = '+33${cleaned.substring(1)}';
      } else {
        cleaned = '+33$cleaned';
      }
    }
    
    return cleaned;
  }

  Future<void> _verifyPhoneNumber() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro de téléphone')),
      );
      return;
    }

    // Formater le numéro de téléphone
    String formattedPhone = _formatPhoneNumber(_phoneController.text);
    
    print('🔍 Tentative de vérification du numéro: $formattedPhone');

    // Si le numéro a changé, marquer comme non vérifié
    if (formattedPhone != _currentPhoneNumber) {
      setState(() {
        _phoneVerified = false;
      });
    }

    setState(() {
      _isVerifyingPhone = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Vérification automatique réussie');
          await _linkPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Échec de la vérification: ${e.code} - ${e.message}');
          setState(() {
            _isVerifyingPhone = false;
          });
          
          String errorMessage = 'Erreur de vérification';
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Numéro de téléphone invalide. Utilisez le format international (+33...)';
              break;
            case 'too-many-requests':
              errorMessage = 'Trop de tentatives. Réessayez plus tard.';
              break;
            case 'quota-exceeded':
              errorMessage = 'Quota SMS dépassé. Réessayez demain.';
              break;
            default:
              errorMessage = 'Erreur: ${e.message}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📱 Code SMS envoyé avec succès');
          setState(() {
            _verificationId = verificationId;
            _isVerifyingPhone = false;
          });
          _showVerificationDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Timeout de récupération automatique');
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      print('💥 Erreur générale: $e');
      setState(() {
        _isVerifyingPhone = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Vérification du téléphone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Un code de vérification a été envoyé au ${_phoneController.text}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _verificationCodeController,
              decoration: const InputDecoration(
                labelText: 'Code de vérification',
                border: OutlineInputBorder(),
                hintText: '123456',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _verificationCodeController.clear();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(onPressed: _verifyCode, child: const Text('Vérifier')),
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null || _verificationCodeController.text.isEmpty) {
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _verificationCodeController.text,
      );

      await _linkPhoneCredential(credential);
      Navigator.of(context).pop(); // Close dialog
    } catch (e) {
      print('❌ Code invalide: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Code invalide: $e')));
    }
  }

  Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
        setState(() {
          _phoneVerified = true;
          _currentPhoneNumber = _formatPhoneNumber(_phoneController.text);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Numéro de téléphone vérifié avec succès!'),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la liaison: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de la liaison: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update display name in Firebase Auth
        await user.updateDisplayName(_displayNameController.text);

        // Update profile in Firestore
        await FirestoreService.updateUserProfile(
          uid: user.uid,
          displayName: _displayNameController.text,
          phoneNumber: _phoneVerified ? _formatPhoneNumber(_phoneController.text) : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès!')),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo de profil
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Nom d'affichage
              CustomTextField(
                controller: _displayNameController,
                label: 'Nom d\'affichage',
                prefixIcon: Icon(Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Numéro de téléphone avec aide
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _phoneController,
                          label: 'Numéro de téléphone',
                          prefixIcon: Icon(Icons.phone),
                          keyboardType: TextInputType.phone,
                          enabled: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isVerifyingPhone ? null : _verifyPhoneNumber,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: _isVerifyingPhone
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _phoneVerified ? 'Re-vérifier' : 'Vérifier',
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                  
                  // Aide pour le format
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Format: +33123456789 (avec indicatif pays)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  
                  if (_phoneVerified && _currentPhoneNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Numéro vérifié: $_currentPhoneNumber',
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  
                  if (!_phoneVerified && _phoneController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Numéro non vérifié',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 40),

              // Bouton de sauvegarde
              CustomButton(
                text: 'Sauvegarder',
                onPressed: _isLoading ? null : _saveProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }
}
