import 'package:flutter/material.dart';

import '../models/regimen_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'glyph.dart';

class DoseRow extends StatelessWidget {
  final RegimenItem item;
  final TimeOfDay time;
  final bool done;
  final VoidCallback onToggle;

  const DoseRow({
    super.key,
    required this.item,
    required this.time,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Glyph(modality: item.modality),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppFonts.body(
                        size: 14.5,
                        color: done ? AppColors.textFaint : AppColors.textPrimary,
                      ).copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [if (item.doseNote != null && item.doseNote!.isNotEmpty) item.doseNote, formatTimeOfDay(time)]
                          .join(' · '),
                      style: AppFonts.mono(size: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: done ? AppColors.herbalSupplement : AppColors.railLine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
