import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/pump_config_store.dart';

Future<void> showPumpConfigSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _PumpConfigSheet(),
  );
}

class _PumpConfigSheet extends StatefulWidget {
  const _PumpConfigSheet();

  @override
  State<_PumpConfigSheet> createState() => _PumpConfigSheetState();
}

class _PumpConfigSheetState extends State<_PumpConfigSheet> {
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _amountControllers = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final store = PumpConfigStore.instance;
    for (var i = 0; i < PumpConfigStore.pumpCount; i++) {
      final c = store.pump(i);
      _nameControllers.add(TextEditingController(text: c.drinkName));
      _amountControllers.add(
        TextEditingController(text: c.amountMl > 0 ? '${c.amountMl}' : ''),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) c.dispose();
    for (final c in _amountControllers) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final next = <PumpConfig>[];
    for (var i = 0; i < PumpConfigStore.pumpCount; i++) {
      next.add(PumpConfig(
        drinkName: _nameControllers[i].text.trim(),
        amountMl: int.tryParse(_amountControllers[i].text.trim()) ?? 0,
      ));
    }
    await PumpConfigStore.instance.save(next);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.pumpConfigTitle,
                    style: AppTextStyles.headingMedium),
                const SizedBox(height: 6),
                Text(l10n.pumpConfigSubtitle,
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 18),
                ...List.generate(PumpConfigStore.pumpCount, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PumpRow(
                      index: i,
                      nameController: _nameControllers[i],
                      amountController: _amountControllers[i],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            _saving ? null : () => Navigator.of(context).pop(),
                        child: Text(l10n.dialogCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.pumpConfigSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PumpRow extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final TextEditingController amountController;

  const _PumpRow({
    required this.index,
    required this.nameController,
    required this.amountController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.pumpLabel(index + 1),
                style: AppTextStyles.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: l10n.pumpDrinkHint,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: amountController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: l10n.pumpAmountHint,
                    hintStyle: const TextStyle(color: Colors.white38),
                    suffixText: 'ml',
                    suffixStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
