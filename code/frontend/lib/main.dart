import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
import 'services/gemma_recipe_generator_service.dart';
import 'services/recipe_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gemma = GemmaRecipeGeneratorService(
    assetPath: 'assets/models/gemma.task',
  );
  RecipeStore.instance.useGenerator(gemma, modelStatus: gemma.status);
  await RecipeStore.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braincell Massacre',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}
