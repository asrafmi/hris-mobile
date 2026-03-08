import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';

class AttendanceService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<Attendance?> getTodayAttendance(String employeeId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final response = await _client
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .eq('work_date', today)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return Attendance.fromJson(response);
  }

  static Future<Attendance> clockIn(String employeeId, {String? notes}) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = <String, dynamic>{
      'employee_id': employeeId,
      'work_date': today,
      'clock_in': DateTime.now().toUtc().toIso8601String(),
    };
    if (notes != null && notes.isNotEmpty) data['notes'] = notes;
    final response = await _client
        .from('attendance')
        .insert(data)
        .select()
        .single();
    return Attendance.fromJson(response);
  }

  static Future<Attendance> clockOut(String attendanceId) async {
    final now = DateTime.now();
    if (now.hour < 17) {
      throw Exception(
        'Belum bisa check out. Check out tersedia mulai pukul 17:00',
      );
    }
    final response = await _client
        .from('attendance')
        .update({'clock_out': now.toUtc().toIso8601String()})
        .eq('id', attendanceId)
        .select()
        .single();
    return Attendance.fromJson(response);
  }

  static Future<List<Attendance>> getAttendanceHistory(
    String employeeId, {
    int limit = 30,
  }) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .order('work_date', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
