import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PhotoCaptureStepIndicator extends StatelessWidget {
  final bool player1Done;
  final bool player2Done;

  const PhotoCaptureStepIndicator({
    super.key,
    required this.player1Done,
    required this.player2Done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(label: '1', done: player1Done, active: !player1Done),
        _StepLine(filled: player1Done),
        _StepDot(label: '2', done: player2Done, active: player1Done && !player2Done),
        _StepLine(filled: player2Done),
        _StepDot(
          icon: Icons.sports_esports_rounded,
          done: player1Done && player2Done,
          active: player1Done && player2Done,
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool done;
  final bool active;

  const _StepDot({this.label, this.icon, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = done || active ? AppColors.primary : AppColors.textTertiary;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done || active ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
        border: Border.all(color: color, width: 1.5),
      ),
      child:
          done
              ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 16)
              : icon != null
              ? Icon(icon, color: color, size: 16)
              : Center(
                child: Text(
                  label!,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: active ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool filled;

  const _StepLine({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: filled ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
