import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/gemma_recipe_parsing.dart';
import '../../services/recipe_store.dart';
import 'widgets/generated_cocktail_tile.dart';
import 'widgets/whats_in_the_box_overlay.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  Future<void> _openBox(BuildContext context) async {
    final store = RecipeStore.instance;
    final result = await WhatsInTheBoxOverlay.show(context, store.setup);
    if (result != null) {
      await store.updateSetupAndRegenerate(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = RecipeStore.instance;

    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Rezepte', style: AppTextStyles.headingLarge),
                    ),
                    _BoxButton(onTap: () => _openBox(context)),
                  ],
                ),
                if (store.setup.isComplete) ...[
                  const SizedBox(height: 10),
                  _PumpSummary(drinks: store.setup.drinks),
                ],
                const SizedBox(height: 14),
                Expanded(child: _buildContent(context, store)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, RecipeStore store) {
    if (store.isGenerating) {
      return _GeneratingView(modelStatus: store.modelStatus);
    }

    if (!store.hasPool) {
      return _EmptyState(onTap: () => _openBox(context));
    }

    return ListView.separated(
      itemCount: store.pool.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == store.pool.length) {
          return _RegenerateButton(onTap: store.regenerate);
        }
        return GeneratedCocktailTile(
          cocktail: store.pool[index],
          setup: store.setup,
        );
      },
    );
  }
}

class _BoxButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BoxButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.inventory_2_outlined, size: 18),
      label: const Text("What's in the box"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _PumpSummary extends StatelessWidget {
  final List<String> drinks;
  const _PumpSummary({required this.drinks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (var i = 0; i < drinks.length; i++)
            Text(
              'P${i + 1}: ${drinks[i]}',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_bar_outlined, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Noch keine Cocktails', style: AppTextStyles.headingSmall),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tippe auf "What\'s in the box" und trag deine vier Getränke ein, '
              'dann werden passende Cocktails generiert.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: const Text("What's in the box"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while a pool is being generated. When an on-device model is wired in,
/// the first run also surfaces the model download / startup progress.
class _GeneratingView extends StatelessWidget {
  final ValueListenable<GemmaModelStatus>? modelStatus;
  const _GeneratingView({required this.modelStatus});

  @override
  Widget build(BuildContext context) {
    final status = modelStatus;
    if (status == null) return _column('Cocktails werden generiert…');

    return ValueListenableBuilder<GemmaModelStatus>(
      valueListenable: status,
      builder: (context, value, _) {
        switch (value.phase) {
          case GemmaModelPhase.downloading:
            return _column('KI-Modell wird geladen … ${value.downloadPercent}%');
          case GemmaModelPhase.loading:
            return _column('KI-Modell wird gestartet…');
          default:
            return _column('Cocktails werden generiert…');
        }
      },
    );
  }

  Widget _column(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(label, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RegenerateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RegenerateButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Neu generieren'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
