import '../models/recipe_models.dart';

const List<RecipeItem> recipeCatalog = [
  RecipeItem(
    name: 'Nitro Cold Brew',
    subtitle: 'Premium Coffee Blend',
    status: RecipeStatus.ready,
    aiRecommended: true,
    favorite: true,
    imageUrl:
        'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=1000&q=80',
    ingredients: const [
      RecipeIngredient(name: 'Cold Brew', amountMl: 180),
      RecipeIngredient(name: 'Milk', amountMl: 80),
      RecipeIngredient(name: 'Vanilla Syrup', amountMl: 20),
      RecipeIngredient(name: 'Ice Water', amountMl: 20),
    ],
  ),
  RecipeItem(
    name: 'Gin Tonic',
    subtitle: 'Classic Botanicals',
    status: RecipeStatus.lowStock,
    aiRecommended: false,
    favorite: false,
    imageUrl:
        'https://images.unsplash.com/photo-1582450871972-ab5ca7f3f4f8?auto=format&fit=crop&w=900&q=80',
    ingredients: const [
      RecipeIngredient(name: 'Gin', amountMl: 50),
      RecipeIngredient(name: 'Tonic Water', amountMl: 170),
      RecipeIngredient(name: 'Lime Juice', amountMl: 20),
      RecipeIngredient(name: 'Soda', amountMl: 10),
    ],
  ),
  RecipeItem(
    name: 'Lime Boost',
    subtitle: 'Energy + Vitamin C',
    status: RecipeStatus.ready,
    aiRecommended: false,
    favorite: true,
    imageUrl:
        'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=900&q=80',
    ingredients: const [
      RecipeIngredient(name: 'Lime Juice', amountMl: 120),
      RecipeIngredient(name: 'Orange Juice', amountMl: 120),
      RecipeIngredient(name: 'Mint Syrup', amountMl: 60),
      RecipeIngredient(name: 'Sparkling Water', amountMl: 100),
    ],
  ),
  RecipeItem(
    name: 'Midnight Berry',
    subtitle: 'Summer Infusion',
    status: RecipeStatus.refillRequired,
    aiRecommended: false,
    favorite: false,
    imageUrl:
        'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=900&q=80',
    ingredients: const [
      RecipeIngredient(name: 'Berry Syrup', amountMl: 100),
      RecipeIngredient(name: 'Cranberry Juice', amountMl: 140),
      RecipeIngredient(name: 'Lemon Juice', amountMl: 60),
      RecipeIngredient(name: 'Soda Water', amountMl: 50),
    ],
  ),
];
