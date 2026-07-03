import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/regimen_item.dart';
import '../services/appointment_repository.dart';
import '../services/notification_service.dart';
import '../services/regimen_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'add_sheet.dart';
import 'modality_style.dart';

/// Shows regimen item details with active toggle, edit, and delete. Edit and
/// delete both reschedule/cancel the item's local notifications so the
/// on-device queue always matches the current record.
Future<void> showRegimenItemDetail(
  BuildContext context, {
  required RegimenItem item,
  required VoidCallback onChanged,
}) {
  final repo = RegimenRepository();
  final style = modalityStyle(item.modality);

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 16, color: style.color),
              const SizedBox(width: 8),
              Expanded(child: Text(item.name, style: AppFonts.header(size: 18))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.fixedTimes.map(formatTimeOfDay).join(', '),
            style: AppFonts.mono(size: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Active', style: AppFonts.body(size: 14)),
            value: item.active,
            activeThumbColor: AppColors.herbalSupplement,
            onChanged: (v) async {
              final updated = await repo.update(item.id!, {'active': v});
              if (v) {
                await NotificationService.instance.scheduleForRegimenItem(updated);
              } else {
                await NotificationService.instance.cancelForRegimenItem(item.id!);
              }
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    showEditRegimenItemSheet(context, item: item, onSaved: onChanged);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink),
                  label: Text('Edit', style: AppFonts.body(size: 13, color: AppColors.ink)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await repo.delete(item.id!);
                    await NotificationService.instance.cancelForRegimenItem(item.id!);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    onChanged();
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.warning),
                  label: Text('Delete', style: AppFonts.body(size: 13, color: AppColors.warning)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> showAppointmentDetail(
  BuildContext context, {
  required Appointment appt,
  required VoidCallback onChanged,
}) {
  final repo = AppointmentRepository();
  final style = apptTypeStyle(appt.type);

  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appt.title, style: AppFonts.header(size: 18)),
          const SizedBox(height: 4),
          Text(
            '${style.label} · ${formatDateTimeAsTime(appt.startTime)}',
            style: AppFonts.mono(size: 12, color: style.color),
          ),
          if (appt.location != null && appt.location!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(appt.location!, style: AppFonts.body(size: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    showEditAppointmentSheet(context, appt: appt, onSaved: onChanged);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink),
                  label: Text('Edit', style: AppFonts.body(size: 13, color: AppColors.ink)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await repo.delete(appt.id!);
                    await NotificationService.instance.cancelForAppointment(appt.id!);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    onChanged();
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.warning),
                  label: Text('Delete', style: AppFonts.body(size: 13, color: AppColors.warning)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
