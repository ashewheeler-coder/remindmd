import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/regimen_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_utils.dart';
import '../../widgets/modality_style.dart';

class RegimenScreen extends StatelessWidget {
  final List<RegimenItem> items;
  final VoidCallback onAdd;
  final void Function(RegimenItem item) onTapItem;

  const RegimenScreen({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    const groups = Modality.values;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Regimen', style: AppFonts.header()),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16, color: AppColors.pharma),
                label: Text('Add', style: AppFonts.body(size: 13, weight: FontWeight.w500, color: AppColors.pharma)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No regimen items yet. Tap Add to create one.',
                  style: AppFonts.body(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            for (final modality in groups) ...[
              if (items.any((i) => i.modality == modality)) ...[
                _GroupHeader(modality: modality),
                const SizedBox(height: 8),
                for (final item in items.where((i) => i.modality == modality))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RegimenRow(item: item, onTap: () => onTapItem(item)),
                  ),
                const SizedBox(height: 12),
              ],
            ],
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final Modality modality;

  const _GroupHeader({required this.modality});

  @override
  Widget build(BuildContext context) {
    final style = modalityStyle(modality);
    return Row(
      children: [
        Icon(style.icon, size: 14, color: style.color),
        const SizedBox(width: 8),
        Text(
          style.label.toUpperCase(),
          style: AppFonts.mono(size: 11, color: style.color, weight: FontWeight.w500).copyWith(letterSpacing: 0.6),
        ),
      ],
    );
  }
}

class _RegimenRow extends StatelessWidget {
  final RegimenItem item;
  final VoidCallback onTap;

  const _RegimenRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timesLabel = item.fixedTimes.map(formatTimeOfDay).join(', ');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppFonts.body(size: 14)),
                    if (item.doseNote != null && item.doseNote!.isNotEmpty)
                      Text(item.doseNote!, style: AppFonts.mono(size: 11.5)),
                  ],
                ),
              ),
              if (timesLabel.isNotEmpty) Text(timesLabel, style: AppFonts.mono(size: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
