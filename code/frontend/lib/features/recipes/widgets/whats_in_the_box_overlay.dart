import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/pump_setup.dart';

/// Bottom-sheet overlay with four inputs (Pumpe 1..4) for the drinks currently
/// loaded into the machine. Returns the new [PumpSetup] on save, or null on
/// cancel.
class WhatsInTheBoxOverlay extends StatefulWidget {
  final PumpSetup initial;

  const WhatsInTheBoxOverlay({super.key, required this.initial});

  /// Shows the overlay and resolves to the entered setup (or null if dismissed).
  static Future<PumpSetup?> show(BuildContext context, PumpSetup initial) {
    return showModalBottomSheet<PumpSetup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhatsInTheBoxOverlay(initial: initial),
    );
  }

  @override
  State<WhatsInTheBoxOverlay> createState() => _WhatsInTheBoxOverlayState();
}

class _WhatsInTheBoxOverlayState extends State<WhatsInTheBoxOverlay> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (i) => TextEditingController(text: widget.initial.drinkAt(i)),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isComplete => _controllers.every((c) => c.text.trim().isNotEmpty);

  void _save() {
    if (!_isComplete) return;
    Navigator.of(context).pop(PumpSetup(_controllers.map((c) => c.text.trim()).toList()));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text("What's in the box?", style: AppTextStyles.headingMedium),
            const SizedBox(height: 4),
            Text(
              'Trag ein, welches Getränk an welcher Pumpe hängt. Daraus werden Cocktails generiert.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 4; i++) ...[
              _PumpField(label: 'Pumpe ${i + 1}', controller: _controllers[i], onChanged: (_) {
                setState(() {});
              }),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isComplete ? _save : null,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Cocktails generieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PumpField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PumpField({required this.label, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
