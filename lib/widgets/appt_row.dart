import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'modality_style.dart';

class ApptRow extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const ApptRow({super.key, required this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = apptTypeStyle(appointment.type);
    return DashedTicket(
      color: style.color,
      background: style.tint,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Icon(Icons.event_outlined, size: 17, color: style.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: AppFonts.body(size: 14.5, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${style.label} · ${formatDateTimeAsTime(appointment.startTime)}',
                  style: AppFonts.mono(size: 12, color: style.color),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: style.color),
        ],
      ),
    );
  }
}

/// A dashed-border "ticket" card, matching the prototype's appointment
/// styling (`border-2 border-dashed`).
class DashedTicket extends StatelessWidget {
  final Color color;
  final Color background;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const DashedTicket({
    super.key,
    required this.color,
    required this.background,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: color, radius: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const dashWidth = 5.0;
    const dashGap = 4.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
