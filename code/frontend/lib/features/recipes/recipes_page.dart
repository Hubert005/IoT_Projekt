import 'package:flutter/material.dart';
import 'data/recipe_catalog.dart';
import 'models/recipe_models.dart';
import 'widgets/featured_recipe_card.dart';
import 'widgets/recipe_filter_bar.dart';
import 'widgets/recipe_search_field.dart';
import 'widgets/recipe_tile.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

enum _RecipeFilter { all, available, favorites }

enum _RecipeStatus { ready, lowStock, refillRequired }

class _RecipeItem {
  final String name;
  final String subtitle;
  final String volumeAndTime;
  final _RecipeStatus status;
  final bool aiRecommended;
  final bool favorite;
  final String imageUrl;

  const _RecipeItem({
    required this.name,
    required this.subtitle,
    required this.volumeAndTime,
    required this.status,
    required this.aiRecommended,
    required this.favorite,
    required this.imageUrl,
  });
}

class _RecipesPageState extends State<RecipesPage> {
  final TextEditingController _searchController = TextEditingController();
  RecipeFilter _filter = RecipeFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RecipeItem> get _filteredRecipes {
    final query = _searchController.text.trim().toLowerCase();

    return recipeCatalog.where((recipe) {
      final matchesFilter = switch (_filter) {
        RecipeFilter.all => true,
        RecipeFilter.available => recipe.status != RecipeStatus.refillRequired,
        RecipeFilter.favorites => recipe.favorite,
      };

      final matchesQuery =
          query.isEmpty ||
          recipe.name.toLowerCase().contains(query) ||
          recipe.subtitle.toLowerCase().contains(query);

      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _filteredRecipes;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Column(
          children: [
            RecipeSearchField(controller: _searchController, onChanged: (_) => setState(() {})),
            const SizedBox(height: 10),
            RecipeFilterBar(
              selected: _filter,
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  if (index == 0) {
                    return FeaturedRecipeCard(recipe: recipe);
                  }
                  return RecipeTile(recipe: recipe);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
