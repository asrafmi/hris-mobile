import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leave_request.dart';

class LeaveService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<List<LeaveRequest>> getMyLeaveRequests(
    String employeeId, {
    int limit = 5,
  }) async {
    final response = await _client
        .from('leave_requests')
        .select('*, approver:employees!approver_id(full_name)')
        .eq('employee_id', employeeId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
