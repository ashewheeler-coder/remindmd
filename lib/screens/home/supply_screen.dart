import 'package:flutter/material.dart';

import '../../models/regimen_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glyph.dart';

class SupplyScreen extends StatelessWidget {
  final List<RegimenItem> items;

  const SupplyScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final tracked = items.where((i) => i.tracksSupply).toList()
      ..sort((a, b) => (a.remainingDays ?? double.infinity).compareTo(b.remainingDays ?? double.infinity));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Supply', style: AppFonts.header()),
          const SizedBox(height: 4),
          Text(
            'Tracked manually — tell RemindMD what you have on hand and it counts down.',
            style: AppFonts.body(size: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          if (tracked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Nothing tracked yet. Turn on "Track supply on hand" when adding a regimen item.',
                  style: AppFonts.body(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (final item in tracked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SupplyRow(item: item),
              ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Refill reminders trigger at your chosen threshold, quietly — no daily nagging.',
                  style: AppFonts.body(size: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplyRow extends StatelessWidget {
  final RegimenItem item;

  const _SupplyRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final remaining = item.remainingDays;
    final low = item.isLowSupply;
    final unit = item.supplyUnit ?? 'units';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Glyph(modality: item.modality, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppFonts.body(size: 14)),
                const SizedBox(height: 2),
                Text(
                  remaining == null
                      ? '${item.supplyOnHand?.toStringAsFixed(0) ?? '—'} $unit on hand'
                      : '${remaining.toStringAsFixed(remaining < 10 ? 1 : 0)} days left',
                  style: AppFonts.mono(size: 11.5),
                ),
              ],
            ),
          ),
          if (low)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'reorder soon',
                style: AppFonts.mono(size: 11, color: AppColors.warning),
              ),
            ),
        ],
      ),
    );
  }
}
