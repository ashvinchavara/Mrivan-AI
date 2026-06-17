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

  /// Fetch classes for a given school
  Future<List<Map<String, dynamic>>> fetchClasses(String schoolId) async {
    try {
      final response = await _client
          .from('classes')
          .select('id, name, room_number')
          .eq('school_id', schoolId)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchClasses: $e');
      }
      throw Exception('Failed to fetch classes: ${e.toString()}');
    }
  }

  /// Fetch students in a given class
  Future<List<Map<String, dynamic>>> fetchStudentsInClass(String classId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, student_roll_number')
          .eq('class_id', classId)
          .eq('role', 'student')
          .order('student_roll_number');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchStudentsInClass: $e');
      }
      throw Exception('Failed to fetch students: ${e.toString()}');
    }
  }

  /// Bulk record attendance for a class
  Future<void> recordAttendanceBulk({
    required String schoolId,
    required String classId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final rowsToInsert = records.map((record) => {
        'student_id': record['student_id'],
        'status': record['status'],
        'date': date,
        'school_id': schoolId,
        'class_id': classId,
      }).toList();

      // Delete existing logs for this class & date to avoid duplicates before inserting
      await _client
          .from('attendance')
          .delete()
          .eq('class_id', classId)
          .eq('date', date);

      await _client.from('attendance').insert(rowsToInsert);
    } catch (e) {
      if (kDebugMode) {
        print('Error in recordAttendanceBulk: $e');
      }
      throw Exception('Failed to record attendance: ${e.toString()}');
    }
  }

  /// Fetch homework for a class
  Future<List<Map<String, dynamic>>> fetchHomework({required String classId}) async {
    try {
      final response = await _client
          .from('homework')
          .select('id, title, description, due_date, class_id, teacher_id, created_at')
          .eq('class_id', classId)
          .order('due_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchHomework: $e');
      }
      throw Exception('Failed to fetch homework: ${e.toString()}');
    }
  }

  /// Assign new homework
  Future<Map<String, dynamic>> assignHomework({
    required String title,
    required String description,
    required String dueDate,
    required String classId,
    required String teacherId,
  }) async {
    try {
      final response = await _client
          .from('homework')
          .insert({
            'title': title,
            'description': description,
            'due_date': dueDate,
            'class_id': classId,
            'teacher_id': teacherId,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in assignHomework: $e');
      }
      throw Exception('Failed to assign homework: ${e.toString()}');
    }
  }

  /// Fetch submissions for a homework assignment
  Future<List<Map<String, dynamic>>> fetchHomeworkSubmissions(String homeworkId) async {
    try {
      final response = await _client
          .from('homework_submissions')
          .select('id, homework_id, student_id, submission_text, file_url, submitted_at, grade, feedback, profiles(full_name, student_roll_number)')
          .eq('homework_id', homeworkId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchHomeworkSubmissions: $e');
      }
      throw Exception('Failed to fetch submissions: ${e.toString()}');
    }
  }

  /// Submit homework
  Future<Map<String, dynamic>> submitHomework({
    required String homeworkId,
    required String studentId,
    required String submissionText,
  }) async {
    try {
      final response = await _client
          .from('homework_submissions')
          .upsert({
            'homework_id': homeworkId,
            'student_id': studentId,
            'submission_text': submissionText,
            'submitted_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'homework_id,student_id')
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in submitHomework: $e');
      }
      throw Exception('Failed to submit homework: ${e.toString()}');
    }
  }

  /// Grade a homework submission
  Future<Map<String, dynamic>> gradeHomeworkSubmission({
    required String submissionId,
    required String grade,
    required String feedback,
  }) async {
    try {
      final response = await _client
          .from('homework_submissions')
          .update({
            'grade': grade,
            'feedback': feedback,
          })
          .eq('id', submissionId)
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in gradeHomeworkSubmission: $e');
      }
      throw Exception('Failed to grade homework: ${e.toString()}');
    }
  }

  /// Fetch AI chat sessions for a user
  Future<List<Map<String, dynamic>>> fetchAIChatSessions(String userId) async {
    try {
      final response = await _client
          .from('ai_chat_sessions')
          .select('id, title, subject, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchAIChatSessions: $e');
      }
      throw Exception('Failed to fetch chat sessions: ${e.toString()}');
    }
  }

  /// Create a new AI chat session
  Future<Map<String, dynamic>> createAIChatSession(String userId, String title, String subject) async {
    try {
      final response = await _client
          .from('ai_chat_sessions')
          .insert({
            'user_id': userId,
            'title': title,
            'subject': subject,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in createAIChatSession: $e');
      }
      throw Exception('Failed to create chat session: ${e.toString()}');
    }
  }

  /// Fetch messages for a session
  Future<List<Map<String, dynamic>>> fetchAIChatMessages(String sessionId) async {
    try {
      final response = await _client
          .from('ai_chat_messages')
          .select('id, session_id, sender, content, timestamp')
          .eq('session_id', sessionId)
          .order('timestamp', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchAIChatMessages: $e');
      }
      throw Exception('Failed to fetch chat messages: ${e.toString()}');
    }
  }

  /// Insert a chat message
  Future<Map<String, dynamic>> insertChatMessage(String sessionId, String sender, String content) async {
    try {
      final response = await _client
          .from('ai_chat_messages')
          .insert({
            'session_id': sessionId,
            'sender': sender,
            'content': content,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in insertChatMessage: $e');
      }
      throw Exception('Failed to insert chat message: ${e.toString()}');
    }
  }

  /// Fetch notes for a user
  Future<List<Map<String, dynamic>>> fetchNotes(String userId) async {
    try {
      final response = await _client
          .from('notes')
          .select('id, title, content, subject, class_level, is_ai_generated, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchNotes: $e');
      }
      throw Exception('Failed to fetch study notes: ${e.toString()}');
    }
  }

  /// Save study note
  Future<Map<String, dynamic>> saveNote({
    required String userId,
    required String title,
    required String content,
    required String subject,
    required String classLevel,
    required bool isAiGenerated,
  }) async {
    try {
      final response = await _client
          .from('notes')
          .insert({
            'user_id': userId,
            'title': title,
            'content': content,
            'subject': subject,
            'class_level': classLevel,
            'is_ai_generated': isAiGenerated,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in saveNote: $e');
      }
      throw Exception('Failed to save study note: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullName,
    String? schoolId,
    String? classId,
    String? paymentPlan,
    String? className,
    String? age,
    String? phoneNumber,
  }) async {
    try {
      final updates = <String, dynamic>{'id': userId};
      if (fullName != null) updates['full_name'] = fullName;
      if (schoolId != null) updates['school_id'] = schoolId;
      if (classId != null) updates['class_id'] = classId;
      if (paymentPlan != null) updates['payment_plan'] = paymentPlan;
      if (className != null) updates['class'] = className;
      if (age != null) updates['age'] = age;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      final response = await _client
          .from('profiles')
          .upsert(updates)
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateUserProfile: $e');
      }
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
}
