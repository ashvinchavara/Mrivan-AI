import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DatabaseService handles all direct database transactions with Supabase.
/// This isolates query operations from the UI screens, keeping the code scalable.
class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Private constructor
  DatabaseService._privateConstructor();

  // Singleton instance
  static final DatabaseService instance = DatabaseService._privateConstructor();

  /// 1. Fetch the user's role from the profiles table.
  /// Used upon app startup to redirect user to their specific dashboard.
  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return response['role'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserRole: $e');
      }
      return null;
    }
  }

  /// 2. Fetch attendance records.
  /// - If [studentId] is provided, it filters attendance for that specific student.
  /// - Under the hood, Supabase Row-Level Security (RLS) automatically enforces
  ///   access control so students only see theirs, and teachers see their school's.
  Future<List<Map<String, dynamic>>> fetchAttendance({String? studentId}) async {
    try {
      var query = _client.from('attendance').select('''
        id,
        status,
        date,
        school_id,
        profiles (
          full_name,
          student_roll_number
        )
      ''');

      if (studentId != null) {
        query = query.eq('student_id', studentId);
      }

      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchAttendance: $e');
      }
      throw Exception('Failed to fetch attendance: ${e.toString()}');
    }
  }

  /// 3. Update an attendance record status (Teacher/Admin action).
  /// Respects RLS validation rules defined on the database level.
  Future<Map<String, dynamic>> updateAttendance(String recordId, String status) async {
    try {
      final response = await _client
          .from('attendance')
          .update({'status': status})
          .eq('id', recordId)
          .select()
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateAttendance: $e');
      }
      throw Exception('Failed to update attendance: ${e.toString()}');
    }
  }
}
