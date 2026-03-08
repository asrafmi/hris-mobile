import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee.dart';

class EmployeeService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<Employee?> getEmployeeByUserId(String userId) async {
    final response = await _client
        .from('employees')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Employee.fromJson(response);
  }

  static Future<List<Employee>> getAllEmployees() async {
    final response = await _client
        .from('employees')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Employee.fromJson(e)).toList();
  }
}
