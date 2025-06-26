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

  Future<void> _verifyPhoneNumber() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro de téléphone')),
      );
      return;
    }

    setState(() {
      _isVerifyingPhone = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          await _linkPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isVerifyingPhone = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de vérification: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isVerifyingPhone = false;
          });
          _showVerificationDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isVerifyingPhone = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
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
          _currentPhoneNumber = _phoneController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Numéro de téléphone vérifié avec succès!'),
          ),
        );
      }
    } catch (e) {
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
          phoneNumber: _phoneVerified ? _phoneController.text : null,
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

              // Numéro de téléphone
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      label: 'Numéro de téléphone',
                      prefixIcon: Icon(Icons.phone),
                      keyboardType: TextInputType.phone,
                      enabled: !_phoneVerified,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!_phoneVerified)
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
                          : const Text(
                              'Vérifier',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                ],
              ),

              if (_phoneVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Numéro vérifié',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
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
