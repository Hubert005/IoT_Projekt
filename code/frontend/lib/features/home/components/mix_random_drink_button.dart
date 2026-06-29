import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/ble_mixer_service.dart';
import '../../../services/ble_service.dart';
import '../../../services/mixer_service.dart';
import '../../../services/recipe_store.dart';

/// Secondary home-screen button: picks a random cocktail from the generated
/// pool and sends its pump amounts to the hardware — no game required.
///
/// On real hardware it waits for the `mix_ok` confirmation (via
/// [BleMixerService]); in test mode it uses [MockMixerService] so the home
/// screen — which has no debug panel to inject `mix_ok` — doesn't hang.
class MixRandomDrinkButton extends StatefulWidget {
  const MixRandomDrinkButton({super.key});

  @override
  State<MixRandomDrinkButton> createState() => _MixRandomDrinkButtonState();
}

class _MixRandomDrinkButtonState extends State<MixRandomDrinkButton> {
  bool _isMixing = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _mixRandom() async {
    final ble = BleService.instance;
    if (!ble.isConnected && !ble.isTestMode) {
      _snack('Bitte zuerst ESP32 verbinden oder Test Modus aktivieren.');
      return;
    }

    final pool = RecipeStore.instance.pool;
    if (pool.isEmpty) {
      _snack('Erst im Rezepte-Tab Cocktails generieren.');
      return;
    }

    final cocktail = pool[Random().nextInt(pool.length)];
    setState(() => _isMixing = true);
    _snack('Mixe ${cocktail.name}…');

    final MixerService mixer =
        ble.isTestMode ? MockMixerService() : BleMixerService();
    try {
      await mixer.orderDrink(cocktail.toDrink());
      _snack('Fertig: ${cocktail.name}');
    } catch (e) {
      _snack('Mix fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _isMixing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _isMixing ? null : _mixRandom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isMixing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryLight,
                  ),
                )
              else
                const Icon(Icons.casino_outlined,
                    color: AppColors.primaryLight, size: 22),
              const SizedBox(width: 8),
              Text(
                _isMixing ? 'MIXE…' : 'MIX RANDOM DRINK',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
