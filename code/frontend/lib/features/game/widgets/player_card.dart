import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/gesture.dart';

class PlayerCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final bool isWinner;
  final bool isLoser;
  final bool gameOver;
  final Gesture? gesture;
  final bool waiting;

  const PlayerCard({
    super.key,
    required this.imagePath,
    required this.label,
    required this.isWinner,
    required this.isLoser,
    required this.gameOver,
    required this.gesture,
    required this.waiting,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? AppColors.primary : AppColors.border,
          width: isWinner ? 2 : 1,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          if (gameOver)
            Align(
              alignment: isWinner ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: isLoser ? 10 : 0, right: isWinner ? 10 : 0),
                child: _Badge(
                  label: isWinner ? l10n.badgeWinner : l10n.badgeLoser,
                  color: isWinner ? AppColors.primary : AppColors.error,
                ),
              ),
            )
          else
            const SizedBox(height: 4),
          const SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _Photo(imagePath: imagePath),
              if (isWinner)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.amber,
                      size: 28,
                      shadows: const [
                        Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              if (gesture != null)
                Positioned(
                  bottom: -15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _GestureChip(
                      emoji: gesture!.emoji,
                      label: gesture!.label,
                      highlight: isWinner,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: gesture != null ? 22 : 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
            child: Column(
              children: [
                Text(label, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                if (gameOver)
                  Text(
                    isWinner ? l10n.badgeVictor : l10n.badgeFocusTarget,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: isWinner ? AppColors.textPrimary : AppColors.error,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  )
                else if (waiting)
                  Text(
                    l10n.waitingLabel,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String imagePath;

  const _Photo({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              Icons.person_rounded,
              size: 72,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: AppTextStyles.captionSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _GestureChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool highlight;

  const _GestureChip({required this.emoji, required this.label, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? AppColors.primary : AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
