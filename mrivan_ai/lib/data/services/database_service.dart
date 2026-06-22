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

  /// Bulk record attendance for a class (optionally tied to a specific timetable period)
  Future<void> recordAttendanceBulk({
    required String schoolId,
    required String classId,
    required String date,
    required List<Map<String, dynamic>> records,
    String? timetableId,
  }) async {
    try {
      final rowsToInsert = records.map((record) => {
        'student_id': record['student_id'],
        'status': record['status'],
        'date': date,
        'school_id': schoolId,
        'class_id': classId,
        if (timetableId != null) 'timetable_id': timetableId,
      }).toList();

      // Delete existing logs for this class, date & period to avoid duplicates before inserting
      var deleteQuery = _client
          .from('attendance')
          .delete()
          .eq('class_id', classId)
          .eq('date', date);

      if (timetableId != null) {
        deleteQuery = deleteQuery.eq('timetable_id', timetableId);
      } else {
        deleteQuery = deleteQuery.filter('timetable_id', 'is', null);
      }

      await deleteQuery;

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

  /// Get user's daily query count (messages sent by user today)
  Future<int> getDailyQueryCount(String userId) async {
    try {
      final sessions = await fetchAIChatSessions(userId);
      if (sessions.isEmpty) return 0;
      
      final sessionIds = sessions.map((s) => s['id'] as String).toList();
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayStartIso = todayStart.toUtc().toIso8601String();

      final response = await _client
          .from('ai_chat_messages')
          .select('id')
          .inFilter('session_id', sessionIds)
          .eq('sender', 'user')
          .gte('timestamp', todayStartIso);

      return (response as List).length;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getDailyQueryCount: $e');
      }
      return 0;
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
    String? email,
    String? role,
    String? teacherSpecialization,
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
      if (email != null) updates['email'] = email;
      if (role != null) updates['role'] = role;
      if (teacherSpecialization != null) {
        updates['teacher_specialization'] = teacherSpecialization;
      }

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

  /// Fetch all teachers for a given school ID
  Future<List<Map<String, dynamic>>> fetchSchoolTeachers(String schoolId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, email, phone_number, teacher_specialization, role')
          .eq('school_id', schoolId)
          .eq('role', 'teacher')
          .order('full_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchSchoolTeachers: $e');
      }
      throw Exception('Failed to fetch teachers: ${e.toString()}');
    }
  }

  /// Fetch all students for a given school ID
  Future<List<Map<String, dynamic>>> fetchSchoolStudents(String schoolId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, full_name, email, phone_number, class, age, student_roll_number, class_id, role')
          .eq('school_id', schoolId)
          .eq('role', 'student')
          .order('full_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchSchoolStudents: $e');
      }
      throw Exception('Failed to fetch students: ${e.toString()}');
    }
  }

  /// Fetch school details (seats, invite code, branding config)
  Future<Map<String, dynamic>?> fetchSchoolData(String schoolId) async {
    try {
      final response = await _client
          .from('schools')
          .select('id, name, total_seats, invite_code, branding_config')
          .eq('id', schoolId)
          .maybeSingle();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchSchoolData: $e');
      }
      return null;
    }
  }

  /// Save study note targeted at a specific class
  Future<Map<String, dynamic>> saveClassNote({
    required String userId,
    required String title,
    required String content,
    required String subject,
    required String classLevel,
    required String? classId,
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
            'class_id': classId,
            'is_ai_generated': isAiGenerated,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in saveClassNote: $e');
      }
      throw Exception('Failed to save class study note: ${e.toString()}');
    }
  }

  /// Fetch notes for a class ID or created by a user ID
  Future<List<Map<String, dynamic>>> fetchClassNotes(String classId, String userId) async {
    try {
      final response = await _client
          .from('notes')
          .select('id, title, content, subject, class_level, is_ai_generated, created_at')
          .or('class_id.eq.$classId,user_id.eq.$userId')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchClassNotes: $e');
      }
      throw Exception('Failed to fetch class study notes: ${e.toString()}');
    }
  }

  /// Save or update syllabus for a class and subject
  Future<Map<String, dynamic>> saveSyllabus({
    required String schoolId,
    required String classId,
    required String subject,
    required String content,
  }) async {
    try {
      final response = await _client
          .from('syllabus')
          .upsert({
            'school_id': schoolId,
            'class_id': classId,
            'subject': subject,
            'content': content,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'class_id,subject')
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in saveSyllabus: $e');
      }
      throw Exception('Failed to save syllabus: ${e.toString()}');
    }
  }

  /// Fetch all syllabus entries for a given class ID
  Future<List<Map<String, dynamic>>> fetchSyllabus({required String classId}) async {
    try {
      final response = await _client
          .from('syllabus')
          .select('id, school_id, class_id, subject, content, created_at, updated_at')
          .eq('class_id', classId)
          .order('subject');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchSyllabus: $e');
      }
      throw Exception('Failed to fetch syllabus: ${e.toString()}');
    }
  }

  /// Create a class for a school
  Future<Map<String, dynamic>> createClass({
    required String schoolId,
    required String name,
    String? roomNumber,
  }) async {
    try {
      final response = await _client
          .from('classes')
          .insert({
            'school_id': schoolId,
            'name': name,
            if (roomNumber != null) 'room_number': roomNumber,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in createClass: $e');
      }
      throw Exception('Failed to create class: ${e.toString()}');
    }
  }

  /// Delete a class by ID
  Future<void> deleteClass(String classId) async {
    try {
      await _client.from('classes').delete().eq('id', classId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteClass: $e');
      }
      throw Exception('Failed to delete class: ${e.toString()}');
    }
  }

  /// Fetch full school timetable
  Future<List<Map<String, dynamic>>> fetchTimetable(String schoolId) async {
    try {
      final response = await _client
          .from('timetable')
          .select('id, school_id, class_id, teacher_id, subject, day_of_week, time_slot, classes(name), profiles(full_name)')
          .eq('school_id', schoolId)
          .order('day_of_week')
          .order('time_slot');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchTimetable: $e');
      }
      throw Exception('Failed to fetch timetable: ${e.toString()}');
    }
  }

  /// Fetch teacher-specific timetable
  Future<List<Map<String, dynamic>>> fetchTeacherTimetable(String teacherId) async {
    try {
      final response = await _client
          .from('timetable')
          .select('id, school_id, class_id, teacher_id, subject, day_of_week, time_slot, classes(name)')
          .eq('teacher_id', teacherId)
          .order('day_of_week')
          .order('time_slot');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchTeacherTimetable: $e');
      }
      throw Exception('Failed to fetch teacher timetable: ${e.toString()}');
    }
  }

  /// Save new timetable entry
  Future<Map<String, dynamic>> saveTimetableEntry({
    required String schoolId,
    required String classId,
    required String teacherId,
    required String subject,
    required String dayOfWeek,
    required String timeSlot,
  }) async {
    try {
      final response = await _client
          .from('timetable')
          .insert({
            'school_id': schoolId,
            'class_id': classId,
            'teacher_id': teacherId,
            'subject': subject,
            'day_of_week': dayOfWeek,
            'time_slot': timeSlot,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in saveTimetableEntry: $e');
      }
      throw Exception('Failed to save timetable entry: ${e.toString()}');
    }
  }

  /// Delete timetable entry
  Future<void> deleteTimetableEntry(String entryId) async {
    try {
      await _client.from('timetable').delete().eq('id', entryId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteTimetableEntry: $e');
      }
      throw Exception('Failed to delete timetable entry: ${e.toString()}');
    }
  }
}
