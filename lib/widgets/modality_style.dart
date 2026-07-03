import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_colors.dart';

class ModalityStyle {
  final IconData icon;
  final Color color;
  final Color tint;
  final String label;

  const ModalityStyle({
    required this.icon,
    required this.color,
    required this.tint,
    required this.label,
  });
}

ModalityStyle modalityStyle(Modality modality) {
  switch (modality) {
    case Modality.pharma:
      return ModalityStyle(
        icon: Icons.medication_outlined,
        color: AppColors.pharma,
        tint: AppColors.pharmaTint,
        label: modality.label,
      );
    case Modality.herbal:
      return ModalityStyle(
        icon: Icons.eco_outlined,
        color: AppColors.herbalSupplement,
        tint: AppColors.herbalSupplementTint,
        label: modality.label,
      );
    case Modality.supplement:
      return ModalityStyle(
        icon: Icons.auto_awesome_outlined,
        color: AppColors.herbalSupplement,
        tint: AppColors.herbalSupplementTint,
        label: modality.label,
      );
    case Modality.practice:
      return ModalityStyle(
        icon: Icons.self_improvement_outlined,
        color: AppColors.practice,
        tint: AppColors.practiceTint,
        label: modality.label,
      );
  }
}

class ApptTypeStyle {
  final Color color;
  final Color tint;
  final String label;

  const ApptTypeStyle({required this.color, required this.tint, required this.label});
}

ApptTypeStyle apptTypeStyle(ApptType type) {
  return ApptTypeStyle(
    color: AppColors.appointment,
    tint: AppColors.appointmentTint,
    label: type.label,
  );
}
