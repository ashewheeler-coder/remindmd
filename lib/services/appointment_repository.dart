import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';

class AppointmentRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Appointment>> fetchAll() async {
    final rows = await _client
        .from('appointments')
        .select()
        .order('start_time');
    return (rows as List)
        .map((row) => Appointment.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> create(Appointment appt) async {
    final row = await _client
        .from('appointments')
        .insert(appt.toInsertMap())
        .select()
        .single();
    return Appointment.fromMap(row);
  }

  Future<Appointment> update(String id, Map<String, dynamic> patch) async {
    final row = await _client
        .from('appointments')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return Appointment.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _client.from('appointments').delete().eq('id', id);
  }
}
