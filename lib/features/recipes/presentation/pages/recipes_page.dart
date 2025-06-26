import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Toutes';
  
  final List<String> _categories = [
    'Toutes',
    'Entrées',
    'Plats principaux',
    'Desserts',
    'Boissons',
    'Végétarien',
    'Rapide',
  ];
  
  final List<Map<String, dynamic>> _recipes = [
    {
      'title': 'Pasta Carbonara',
      'category': 'Plats principaux',
      'time': '20 min',
      'difficulty': 'Facile',
      'rating': 4.8,
      'image': 'https://via.placeholder.com/150x100/FF6B35/FFFFFF?text=Pasta',
      'description': 'Un classique italien crémeux et délicieux',
    },
    {
      'title': 'Salade César',
      'category': 'Entrées',
      'time': '15 min',
      'difficulty': 'Facile',
      'rating': 4.5,
      'image': 'https://via.placeholder.com/150x100/4ECDC4/FFFFFF?text=Salade',
      'description': 'Salade fraîche avec croûtons et parmesan',
    },
    {
      'title': 'Tiramisu',
      'category': 'Desserts',
      'time': '30 min',
      'difficulty': 'Moyen',
      'rating': 4.9,
      'image': 'https://via.placeholder.com/150x100/45B7D1/FFFFFF?text=Tiramisu',
      'description': 'Dessert italien au café et mascarpone',
    },
    {
      'title': 'Smoothie Tropical',
      'category': 'Boissons',
      'time': '5 min',
      'difficulty': 'Facile',
      'rating': 4.3,
      'image': 'https://via.placeholder.com/150x100/F7DC6F/FFFFFF?text=Smoothie',
      'description': 'Boisson rafraîchissante aux fruits exotiques',
    },
    {
      'title': 'Buddha Bowl',
      'category': 'Végétarien',
      'time': '25 min',
      'difficulty': 'Facile',
      'rating': 4.6,
      'image': 'https://via.placeholder.com/150x100/58D68D/FFFFFF?text=Buddha',
      'description': 'Bol nutritif avec légumes et quinoa',
    },
    {
      'title': 'Omelette Express',
      'category': 'Rapide',
      'time': '8 min',
      'difficulty': 'Facile',
      'rating': 4.2,
      'image': 'https://via.placeholder.com/150x100/F1948A/FFFFFF?text=Omelette',
      'description': 'Petit-déjeuner rapide et protéiné',
    },
  ];
  
  List<Map<String, dynamic>> get _filteredRecipes {
    return _recipes.where((recipe) {
      final matchesCategory = _selectedCategory == 'Toutes' || 
                             recipe['category'] == _selectedCategory;
      final matchesSearch = recipe['title']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec recherche
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recettes',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher une recette...',
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Filtres par catégorie
            Container(
              height: 60,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Liste des recettes
            Expanded(
              child: _filteredRecipes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune recette trouvée',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _filteredRecipes[index];
                        return _buildRecipeCard(recipe);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ouverture de ${recipe['title']}')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image de la recette
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    recipe['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.restaurant,
                        color: AppColors.primary,
                        size: 32,
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations de la recette
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(Icons.access_time, recipe['time']),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.bar_chart, recipe['difficulty']),
                        const SizedBox(width: 8),
                        _buildRatingChip(recipe['rating']),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingChip(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
