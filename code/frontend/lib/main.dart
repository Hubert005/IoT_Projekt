import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
import 'services/gemma_recipe_generator_service.dart';
import 'services/recipe_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Generate recipes with an on-device LLM (falls back to the mock generator
  // automatically if the model can't be loaded). Wired only here, so tests and
  // test mode keep using the mock and never trigger a model load.
  //
  // The model ships bundled as an asset — fully offline, no API key. Drop the
  // Gemma .task file at assets/models/gemma.task (see that folder's README).
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
