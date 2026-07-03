import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import '../models/enums.dart';
import '../models/regimen_item.dart';
import '../services/appointment_repository.dart';
import '../services/notification_service.dart';
import '../services/regimen_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/modality_style.dart';

/// Default reminder style at creation time, per modality. User can override
/// per item afterwards.
ReminderStyle defaultReminderStyleFor(Modality modality) {
  switch (modality) {
    case Modality.pharma:
    case Modality.herbal:
      return ReminderStyle.standard;
    case Modality.supplement:
    case Modality.practice:
      return ReminderStyle.gentle;
  }
}

/// Default reminder lead times (minutes before the appointment), per type.
List<int> defaultLeadMinutesFor(ApptType type) {
  switch (type) {
    case ApptType.medical:
      return [1440, 60];
    case ApptType.therapy:
    case ApptType.classType:
    case ApptType.other:
      return [60];
  }
}

String reminderStylePreview(Modality modality) {
  switch (defaultReminderStyleFor(modality)) {
    case ReminderStyle.gentle:
      return 'Gentle reminder — a soft nudge, easy to dismiss.';
    case ReminderStyle.standard:
      return 'Standard reminder, right on time.';
    case ReminderStyle.insistent:
      return 'Insistent reminder — repeats until dismissed.';
  }
}

String apptReminderPreview(ApptType type) {
  final leads = defaultLeadMinutesFor(type);
  if (leads.length > 1) {
    return 'Reminds you a day ahead, then an hour before.';
  }
  return 'Reminds you an hour before.';
}

Future<void> showAddSheet(
  BuildContext context, {
  required VoidCallback onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AddSheetContent(),
  ).then((saved) {
    if (saved == true) onSaved();
  });
}

/// Opens the same form as [showAddSheet], pre-filled for editing an existing
/// regimen item.
Future<void> showEditRegimenItemSheet(
  BuildContext context, {
  required RegimenItem item,
  required VoidCallback onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddSheetContent(editItem: item),
  ).then((saved) {
    if (saved == true) onSaved();
  });
}

/// Opens the same form as [showAddSheet], pre-filled for editing an existing
/// appointment.
Future<void> showEditAppointmentSheet(
  BuildContext context, {
  required Appointment appt,
  required VoidCallback onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddSheetContent(editAppointment: appt),
  ).then((saved) {
    if (saved == true) onSaved();
  });
}

class _AddSheetContent extends StatefulWidget {
  final RegimenItem? editItem;
  final Appointment? editAppointment;

  const _AddSheetContent({this.editItem, this.editAppointment});

  @override
  State<_AddSheetContent> createState() => _AddSheetContentState();
}

enum _Kind { item, appt }

class _AddSheetContentState extends State<_AddSheetContent> {
  _Kind _kind = _Kind.item;
  Modality _modality = Modality.pharma;
  ApptType _apptType = ApptType.medical;

  final _nameController = TextEditingController();
  final _doseNoteController = TextEditingController();
  final _locationController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  DateTime _apptDate = DateTime.now();
  TimeOfDay _apptTime = const TimeOfDay(hour: 9, minute: 0);

  bool _trackSupply = false;
  final _supplyOnHandController = TextEditingController();
  final _supplyPerDoseController = TextEditingController(text: '1');
  final _supplyUnitController = TextEditingController(text: 'doses');
  final _supplyThresholdController = TextEditingController();

  bool _saving = false;
  bool _saved = false;

  final _regimenRepo = RegimenRepository();
  final _apptRepo = AppointmentRepository();

  bool get _isEditing => widget.editItem != null || widget.editAppointment != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    final appt = widget.editAppointment;
    if (item != null) {
      _kind = _Kind.item;
      _modality = item.modality;
      _nameController.text = item.name;
      _doseNoteController.text = item.doseNote ?? '';
      if (item.fixedTimes.isNotEmpty) _time = item.fixedTimes.first;
      _trackSupply = item.tracksSupply;
      if (item.supplyOnHand != null) _supplyOnHandController.text = _formatNum(item.supplyOnHand!);
      if (item.supplyPerDose != null) _supplyPerDoseController.text = _formatNum(item.supplyPerDose!);
      _supplyUnitController.text = item.supplyUnit ?? 'doses';
      if (item.supplyReorderThreshold != null) {
        _supplyThresholdController.text = _formatNum(item.supplyReorderThreshold!);
      }
    } else if (appt != null) {
      _kind = _Kind.appt;
      _apptType = appt.type;
      _nameController.text = appt.title;
      _locationController.text = appt.location ?? '';
      _apptDate = appt.startTime;
      _apptTime = TimeOfDay(hour: appt.startTime.hour, minute: appt.startTime.minute);
    }
  }

  static String _formatNum(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _nameController.dispose();
    _doseNoteController.dispose();
    _locationController.dispose();
    _supplyOnHandController.dispose();
    _supplyPerDoseController.dispose();
    _supplyUnitController.dispose();
    _supplyThresholdController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !_canSave) return;

    setState(() => _saving = true);
    try {
      if (_kind == _Kind.item) {
        final existing = widget.editItem;
        final item = RegimenItem(
          id: existing?.id,
          userId: userId,
          name: _nameController.text.trim(),
          modality: _modality,
          doseNote: _doseNoteController.text.trim().isEmpty ? null : _doseNoteController.text.trim(),
          fixedTimes: [_time],
          reminderStyle: defaultReminderStyleFor(_modality),
          active: existing?.active ?? true,
          supplyOnHand: _trackSupply ? double.tryParse(_supplyOnHandController.text) : null,
          supplyPerDose: _trackSupply ? double.tryParse(_supplyPerDoseController.text) : null,
          supplyUnit: _trackSupply ? _supplyUnitController.text.trim() : null,
          supplyReorderThreshold: _trackSupply ? double.tryParse(_supplyThresholdController.text) : null,
        );
        final saved = existing == null
            ? await _regimenRepo.create(item)
            : await _regimenRepo.update(existing.id!, item.toInsertMap());
        await NotificationService.instance.scheduleForRegimenItem(saved);
      } else {
        final start = DateTime(
          _apptDate.year,
          _apptDate.month,
          _apptDate.day,
          _apptTime.hour,
          _apptTime.minute,
        );
        final existing = widget.editAppointment;
        final appt = Appointment(
          id: existing?.id,
          userId: userId,
          title: _nameController.text.trim(),
          type: _apptType,
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          startTime: start,
          reminderLeadMinutes: defaultLeadMinutesFor(_apptType),
        );
        final saved = existing == null
            ? await _apptRepo.create(appt)
            : await _apptRepo.update(existing.id!, appt.toInsertMap());
        await NotificationService.instance.scheduleForAppointment(saved);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saved) {
      return _SavedConfirmation(kind: _kind, isEditing: _isEditing);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? (_kind == _Kind.item ? 'Edit item' : 'Edit appointment') : 'Add new',
                    style: AppFonts.header(size: 18),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                    style: IconButton.styleFrom(backgroundColor: AppColors.background, shape: const CircleBorder()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isEditing) ...[
                _KindToggle(kind: _kind, onChanged: (k) => setState(() => _kind = k)),
                const SizedBox(height: 20),
              ],
              if (_kind == _Kind.item) _buildItemForm() else _buildApptForm(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSave ? AppColors.ink : AppColors.railLine,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Modality'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final m in Modality.values) ...[
              Expanded(child: _ModalityChoice(modality: m, selected: _modality == m, onTap: () => setState(() => _modality = m))),
              if (m != Modality.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _fieldLabel('Name'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'e.g. Curcumin, Lisinopril, Evening stretch'),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Dose'),
        const SizedBox(height: 6),
        TextField(
          controller: _doseNoteController,
          decoration: const InputDecoration(hintText: 'e.g. 10mg, 2 capsules, 10 min'),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Time'),
        const SizedBox(height: 6),
        _TimePickerField(
          time: _time,
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: _time);
            if (picked != null) setState(() => _time = picked);
          },
        ),
        const SizedBox(height: 16),
        _SupplyToggle(
          value: _trackSupply,
          onChanged: (v) => setState(() => _trackSupply = v),
        ),
        if (_trackSupply) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _supplyOnHandController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'On hand', labelText: 'On hand'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _supplyPerDoseController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Per dose', labelText: 'Per dose'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _supplyUnitController,
                  decoration: const InputDecoration(hintText: 'Unit', labelText: 'Unit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _supplyThresholdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Reorder at', labelText: 'Reorder at'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(reminderStylePreview(_modality), style: AppFonts.body(size: 12, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildApptForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Type'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final t in ApptType.values) ...[
              Expanded(child: _ApptTypeChoice(type: t, selected: _apptType == t, onTap: () => setState(() => _apptType = t))),
              if (t != ApptType.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _fieldLabel('Title'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'e.g. Dr. Barnett — follow-up'),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Location'),
        const SizedBox(height: 6),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(hintText: 'e.g. Carolina Hand & Sports Medicine'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Date'),
                  const SizedBox(height: 6),
                  _DatePickerField(
                    date: _apptDate,
                    onTap: () async {
                      final earliest = DateTime.now().subtract(const Duration(days: 1));
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _apptDate,
                        firstDate: _apptDate.isBefore(earliest) ? _apptDate : earliest,
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) setState(() => _apptDate = picked);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Time'),
                  const SizedBox(height: 6),
                  _TimePickerField(
                    time: _apptTime,
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _apptTime);
                      if (picked != null) setState(() => _apptTime = picked);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '${apptReminderPreview(_apptType)} You can change this after saving.',
            style: AppFonts.body(size: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
        text.toUpperCase(),
        style: AppFonts.mono(size: 11, color: AppColors.textSecondary).copyWith(letterSpacing: 0.5),
      );
}

class _KindToggle extends StatelessWidget {
  final _Kind kind;
  final ValueChanged<_Kind> onChanged;

  const _KindToggle({required this.kind, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Med / Supplement / Practice',
              selected: kind == _Kind.item,
              color: AppColors.pharma,
              onTap: () => onChanged(_Kind.item),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Appointment',
              selected: kind == _Kind.appt,
              color: AppColors.appointment,
              onTap: () => onChanged(_Kind.appt),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: selected ? color : Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppFonts.body(
            size: 13,
            weight: FontWeight.w500,
            color: selected ? AppColors.surface : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _ModalityChoice extends StatelessWidget {
  final Modality modality;
  final bool selected;
  final VoidCallback onTap;

  const _ModalityChoice({required this.modality, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = modalityStyle(modality);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? style.color : AppColors.border),
          color: selected ? style.tint : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(style.icon, size: 16, color: selected ? style.color : AppColors.textFaint),
            const SizedBox(height: 4),
            Text(style.label, style: AppFonts.body(size: 10, color: selected ? style.color : AppColors.textFaint)),
          ],
        ),
      ),
    );
  }
}

class _ApptTypeChoice extends StatelessWidget {
  final ApptType type;
  final bool selected;
  final VoidCallback onTap;

  const _ApptTypeChoice({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = apptTypeStyle(type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? style.color : AppColors.border),
          color: selected ? style.tint : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(style.label, style: AppFonts.body(size: 12, color: selected ? style.color : AppColors.textFaint)),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerField({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(formatTimeOfDay(time), style: AppFonts.mono(size: 14, color: AppColors.textPrimary)),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('${date.month}/${date.day}/${date.year}', style: AppFonts.mono(size: 14, color: AppColors.textPrimary)),
      ),
    );
  }
}

class _SupplyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SupplyToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Track supply on hand', style: AppFonts.body(size: 13)),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.herbalSupplement,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedConfirmation extends StatelessWidget {
  final _Kind kind;
  final bool isEditing;

  const _SavedConfirmation({required this.kind, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.herbalSupplementTint, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 24, color: AppColors.herbalSupplement),
          ),
          const SizedBox(height: 12),
          Text(
            isEditing
                ? 'Changes saved.'
                : 'Added to your ${kind == _Kind.item ? 'regimen' : 'appointments'}.',
            style: AppFonts.body(size: 15),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Done', style: AppFonts.body(size: 13, color: AppColors.pharma, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
