import 'package:flutter/material.dart';
import 'package:iot_drink_mixer/core/theme/app_colors.dart';
import 'data/recipe_catalog.dart';
import 'models/recipe_models.dart';
import 'widgets/featured_recipe_card.dart';
import 'widgets/recipe_detail_sheet.dart';
import 'widgets/recipe_filter_bar.dart';
import 'widgets/recipe_search_field.dart';
import 'widgets/recipe_tile.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

enum _RecipeFilter { all, available, favorites }

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
          recipe.subtitle.toLowerCase().contains(query) ||
          recipe.mixSummary.toLowerCase().contains(query);

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
                    return FeaturedRecipeCard(
                      recipe: recipe,
                      onTap: () => _openRecipeDetails(recipe),
                    );
                  }
                  return RecipeTile(
                    recipe: recipe,
                    onTap: () => _openRecipeDetails(recipe),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecipeDetails(RecipeItem recipe) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RecipeDetailSheet(recipe: recipe),
    );
  }
}
