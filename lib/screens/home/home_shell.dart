import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/appointment.dart';
import '../../models/dose_log.dart';
import '../../models/enums.dart';
import '../../models/regimen_item.dart';
import '../../services/appointment_repository.dart';
import '../../services/regimen_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/add_sheet.dart';
import '../../widgets/detail_sheets.dart';
import 'appointments_screen.dart';
import 'regimen_screen.dart';
import 'supply_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _regimenRepo = RegimenRepository();
  final _apptRepo = AppointmentRepository();

  int _tab = 0;
  bool _loading = true;
  String? _error;

  List<RegimenItem> _regimenItems = [];
  List<Appointment> _appointments = [];
  List<DoseLog> _todayLogs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _regimenRepo.fetchAll(),
        _apptRepo.fetchAll(),
        _regimenRepo.logsForDay(DateTime.now()),
      ]);
      setState(() {
        _regimenItems = results[0] as List<RegimenItem>;
        _appointments = results[1] as List<Appointment>;
        _todayLogs = results[2] as List<DoseLog>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleDose(RegimenItem item, TimeOfDay time, bool takenNow) async {
    final now = DateTime.now();
    final scheduledFor = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final userId = Supabase.instance.client.auth.currentUser!.id;

    if (!takenNow) {
      await _regimenRepo.logDose(DoseLog(
        userId: userId,
        regimenItemId: item.id!,
        scheduledFor: scheduledFor,
        status: DoseStatus.taken,
      ));
    }
    // Un-doing a dose (undo taken -> not taken) is intentionally a no-op on
    // the log table; dose_logs is an append-only history. The Today view
    // simply re-derives "done" from whether a taken log exists for the slot,
    // so we just refresh from the source of truth.
    await _load();
  }

  Future<void> _openAdd() async {
    await showAddSheet(context, onSaved: _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.outerBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              color: AppColors.background,
              child: Stack(
                children: [
                  _buildBody(),
                  Positioned(
                    right: 20,
                    bottom: 88,
                    child: FloatingActionButton(
                      onPressed: _openAdd,
                      backgroundColor: AppColors.ink,
                      child: const Icon(Icons.add, color: AppColors.surface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: BottomNavigationBar(
            currentIndex: _tab,
            onTap: (i) => setState(() => _tab = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Today'),
              BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), label: 'Regimen'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Appts'),
              BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Supply'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load data', style: AppFonts.header(size: 16)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: IndexedStack(
        index: _tab,
        children: [
          TodayScreen(
            regimenItems: _regimenItems,
            appointments: _appointments,
            todayLogs: _todayLogs,
            onToggleDose: _toggleDose,
          ),
          RegimenScreen(
            items: _regimenItems,
            onAdd: _openAdd,
            onTapItem: (item) => showRegimenItemDetail(context, item: item, onChanged: _load),
          ),
          AppointmentsScreen(
            appointments: _appointments,
            onAdd: _openAdd,
            onTapAppointment: (appt) => showAppointmentDetail(context, appt: appt, onChanged: _load),
          ),
          SupplyScreen(items: _regimenItems),
        ],
      ),
    );
  }
}
