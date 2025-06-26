import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  // Préférences culinaires
  final List<String> _cuisineTypes = [
    'Cuisine française',
    'Cuisine italienne',
    'Cuisine asiatique',
    'Cuisine africaine',
    'Cuisine malienne',
    'Cuisine méditerranéenne',
    'Cuisine mexicaine',
    'Cuisine indienne',
  ];

  // Restrictions alimentaires
  final List<String> _dietaryRestrictions = [
    'Végétarien',
    'Végétalien',
    'Sans gluten',
    'Sans lactose',
    'Halal',
    'Casher',
    'Sans noix',
    'Sans fruits de mer',
  ];

  // Niveaux de difficulté préférés
  final List<String> _difficultyLevels = [
    'Facile',
    'Moyen',
    'Difficile',
  ];

  Set<String> _selectedCuisines = {};
  Set<String> _selectedRestrictions = {};
  Set<String> _selectedDifficulties = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    // TODO: Charger les préférences depuis Firestore
    // Pour l'instant, on utilise des valeurs par défaut
    setState(() {
      _selectedCuisines = {'Cuisine française', 'Cuisine malienne'};
      _selectedDifficulties = {'Facile', 'Moyen'};
    });
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Sauvegarder dans Firestore
      await Future.delayed(const Duration(seconds: 1)); // Simulation

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences sauvegardées avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Préférences culinaires',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Types de cuisine préférés
            _buildSection(
              'Types de cuisine préférés',
              'Sélectionnez vos cuisines favorites',
              _cuisineTypes,
              _selectedCuisines,
              (value) {
                setState(() {
                  if (_selectedCuisines.contains(value)) {
                    _selectedCuisines.remove(value);
                  } else {
                    _selectedCuisines.add(value);
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // Restrictions alimentaires
            _buildSection(
              'Restrictions alimentaires',
              'Indiquez vos restrictions ou régimes spéciaux',
              _dietaryRestrictions,
              _selectedRestrictions,
              (value) {
                setState(() {
                  if (_selectedRestrictions.contains(value)) {
                    _selectedRestrictions.remove(value);
                  } else {
                    _selectedRestrictions.add(value);
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // Niveaux de difficulté
            _buildSection(
              'Niveaux de difficulté préférés',
              'Choisissez les niveaux qui vous conviennent',
              _difficultyLevels,
              _selectedDifficulties,
              (value) {
                setState(() {
                  if (_selectedDifficulties.contains(value)) {
                    _selectedDifficulties.remove(value);
                  } else {
                    _selectedDifficulties.add(value);
                  }
                });
              },
            ),

            const SizedBox(height: 32),

            // Bouton de sauvegarde
            CustomButton(
              text: 'Sauvegarder les préférences',
              onPressed: _savePreferences,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String subtitle,
    List<String> options,
    Set<String> selectedOptions,
    Function(String) onToggle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return GestureDetector(
                onTap: () => onToggle(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
