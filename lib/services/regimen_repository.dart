import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dose_log.dart';
import '../models/regimen_item.dart';

class RegimenRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<RegimenItem>> fetchAll() async {
    final rows = await _client
        .from('regimen_items')
        .select()
        .order('created_at');
    return (rows as List)
        .map((row) => RegimenItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<RegimenItem> create(RegimenItem item) async {
    final row = await _client
        .from('regimen_items')
        .insert(item.toInsertMap())
        .select()
        .single();
    return RegimenItem.fromMap(row);
  }

  Future<RegimenItem> update(String id, Map<String, dynamic> patch) async {
    final row = await _client
        .from('regimen_items')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return RegimenItem.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _client.from('regimen_items').delete().eq('id', id);
  }

  Future<void> logDose(DoseLog log) async {
    await _client.from('dose_logs').insert(log.toInsertMap());
  }

  Future<List<DoseLog>> logsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from('dose_logs')
        .select()
        .gte('scheduled_for', start.toUtc().toIso8601String())
        .lt('scheduled_for', end.toUtc().toIso8601String());
    return (rows as List)
        .map((row) => DoseLog.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
