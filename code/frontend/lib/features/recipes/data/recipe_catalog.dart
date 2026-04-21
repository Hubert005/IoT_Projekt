import '../models/recipe_models.dart';

const List<RecipeItem> recipeCatalog = [
  RecipeItem(
    name: 'Nitro Cold Brew',
    subtitle: 'Premium Coffee Blend',
    volumeAndTime: '300 ml  -  45 sec',
    status: RecipeStatus.ready,
    aiRecommended: true,
    favorite: true,
    imageUrl:
        'https://images.unsplash.com/photo-1517701604599-bb29b565090c?auto=format&fit=crop&w=1000&q=80',
  ),
  RecipeItem(
    name: 'Gin Tonic',
    subtitle: 'Classic Botanicals',
    volumeAndTime: '250 ml  -  30 sec',
    status: RecipeStatus.lowStock,
    aiRecommended: false,
    favorite: false,
    imageUrl:
        'https://images.unsplash.com/photo-1582450871972-ab5ca7f3f4f8?auto=format&fit=crop&w=900&q=80',
  ),
  RecipeItem(
    name: 'Lime Boost',
    subtitle: 'Energy + Vitamin C',
    volumeAndTime: '400 ml  -  20 sec',
    status: RecipeStatus.ready,
    aiRecommended: false,
    favorite: true,
    imageUrl:
        'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=900&q=80',
  ),
  RecipeItem(
    name: 'Midnight Berry',
    subtitle: 'Summer Infusion',
    volumeAndTime: '350 ml  -  50 sec',
    status: RecipeStatus.refillRequired,
    aiRecommended: false,
    favorite: false,
    imageUrl:
        'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=900&q=80',
  ),
];
