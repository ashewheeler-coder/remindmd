import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/appointment.dart';
import '../../models/dose_log.dart';
import '../../models/enums.dart';
import '../../models/regimen_item.dart';
import '../../models/today_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/appt_row.dart';
import '../../widgets/dose_row.dart';
import '../../widgets/modality_style.dart';

class TodayScreen extends StatelessWidget {
  final List<RegimenItem> regimenItems;
  final List<Appointment> appointments;
  final List<DoseLog> todayLogs;
  final void Function(RegimenItem item, TimeOfDay time, bool takenNow) onToggleDose;

  const TodayScreen({
    super.key,
    required this.regimenItems,
    required this.appointments,
    required this.todayLogs,
    required this.onToggleDose,
  });

  List<TodayEntry> _buildEntries() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final entries = <TodayEntry>[];

    for (final item in regimenItems.where((i) => i.active && i.scheduleKind == ScheduleKind.fixedTimes)) {
      for (final time in item.fixedTimes) {
        final taken = todayLogs.any((log) =>
            log.regimenItemId == item.id &&
            log.status == DoseStatus.taken &&
            log.scheduledFor.hour == time.hour &&
            log.scheduledFor.minute == time.minute);
        entries.add(TodayEntry.dose(item: item, time: time, doseTaken: taken));
      }
    }

    for (final appt in appointments) {
      final apptDay = DateTime(appt.startTime.year, appt.startTime.month, appt.startTime.day);
      if (apptDay == today) {
        entries.add(TodayEntry.appointment(
          appt: appt,
          time: TimeOfDay(hour: appt.startTime.hour, minute: appt.startTime.minute),
        ));
      }
    }

    entries.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();
    final doseCount = entries.where((e) => e.isDose).length;
    final doneCount = entries.where((e) => e.isDose && e.doseTaken).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Today', style: AppFonts.header()),
              Text(
                DateFormat('EEE MMM d').format(DateTime.now()).toUpperCase(),
                style: AppFonts.mono(size: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            doseCount == 0
                ? 'Nothing scheduled yet — add a regimen item to get started.'
                : "$doneCount of $doseCount done — you're on track.",
            style: AppFonts.body(size: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('Nothing on the rail today.', style: AppFonts.body(color: AppColors.textSecondary)),
              ),
            )
          else
            _DayRail(entries: entries, onToggleDose: onToggleDose),
        ],
      ),
    );
  }
}

class _DayRail extends StatelessWidget {
  final List<TodayEntry> entries;
  final void Function(RegimenItem item, TimeOfDay time, bool takenNow) onToggleDose;

  const _DayRail({required this.entries, required this.onToggleDose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 6,
          top: 4,
          bottom: 4,
          child: Container(width: 1, color: AppColors.railLine),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -20,
                        top: 16,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: entry.isDose
                                  ? modalityStyle(entry.regimenItem!.modality).color
                                  : apptTypeStyle(entry.appointment!.type).color,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      entry.isDose
                          ? DoseRow(
                              item: entry.regimenItem!,
                              time: entry.time,
                              done: entry.doseTaken,
                              onToggle: () => onToggleDose(entry.regimenItem!, entry.time, entry.doseTaken),
                            )
                          : ApptRow(appointment: entry.appointment!),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
