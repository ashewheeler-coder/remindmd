import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_utils.dart';
import '../../widgets/appt_row.dart';
import '../../widgets/modality_style.dart';

class AppointmentsScreen extends StatelessWidget {
  final List<Appointment> appointments;
  final VoidCallback onAdd;
  final void Function(Appointment appt) onTapAppointment;

  const AppointmentsScreen({
    super.key,
    required this.appointments,
    required this.onAdd,
    required this.onTapAppointment,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...appointments]..sort((a, b) => a.startTime.compareTo(b.startTime));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Appointments', style: AppFonts.header()),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16, color: AppColors.pharma),
                label: Text('Add', style: AppFonts.body(size: 13, weight: FontWeight.w500, color: AppColors.pharma)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No appointments yet. Tap Add to create one.',
                  style: AppFonts.body(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            for (final appt in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AppointmentCard(appt: appt, onTap: () => onTapAppointment(appt)),
              ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reminder timing defaults by type — medical visits nudge a day and an hour ahead; '
                  'therapy and classes remind an hour before. Edit any reminder per event.',
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

class _AppointmentCard extends StatelessWidget {
  final Appointment appt;
  final VoidCallback onTap;

  const _AppointmentCard({required this.appt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = apptTypeStyle(appt.type);
    return DashedTicket(
      color: style.color,
      background: style.tint,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                style.label.toUpperCase(),
                style: AppFonts.mono(size: 11, color: style.color, weight: FontWeight.w500).copyWith(letterSpacing: 0.6),
              ),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: style.color),
                  const SizedBox(width: 4),
                  Text(formatDateTimeAsTime(appt.startTime), style: AppFonts.mono(size: 12, color: style.color)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(appt.title, style: AppFonts.body(size: 15, color: AppColors.textPrimary)),
          if (appt.location != null && appt.location!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(appt.location!, style: AppFonts.body(size: 12.5, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
