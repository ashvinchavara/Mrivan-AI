const { supabaseAdmin } = require('../config/db');

/**
 * 1. Create a new School (Super Admin action)
 */
const createSchool = async (req, res, next) => {
  try {
    const { name, brandingConfig } = req.body;
    if (!name) return res.status(400).json({ error: 'School name is required' });

    const { data, error } = await supabaseAdmin
      .from('schools')
      .insert({ name, branding_config: brandingConfig || {} })
      .select()
      .single();

    if (error) throw error;
    res.status(211).json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * 2. Create a new Class (School Admin action)
 */
const createClass = async (req, res, next) => {
  try {
    const { name, roomNumber } = req.body;
    const schoolId = req.user.schoolId;

    if (!schoolId) return res.status(400).json({ error: 'User is not associated with any school' });
    if (!name) return res.status(400).json({ error: 'Class name is required' });

    const { data, error } = await supabaseAdmin
      .from('classes')
      .insert({ name, room_number: roomNumber || null, school_id: schoolId })
      .select()
      .single();

    if (error) throw error;
    res.status(211).json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * 3. List all classes for the user's school
 */
const getClasses = async (req, res, next) => {
  try {
    const schoolId = req.user.schoolId;
    if (!schoolId) return res.status(400).json({ error: 'User is not associated with any school' });

    const { data, error } = await supabaseAdmin
      .from('classes')
      .select('*')
      .eq('school_id', schoolId)
      .order('name');

    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * 4. List students in the school (optionally filtered by class_id)
 */
const getStudents = async (req, res, next) => {
  try {
    const schoolId = req.user.schoolId;
    const { classId } = req.query;

    if (!schoolId) return res.status(400).json({ error: 'User is not associated with any school' });

    let query = supabaseAdmin
      .from('profiles')
      .select('id, full_name, student_roll_number, class_id')
      .eq('school_id', schoolId)
      .eq('role', 'student');

    if (classId) {
      query = query.eq('class_id', classId);
    }

    const { data, error } = await query;
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * 5. Record/Save Attendance in bulk (Teacher action)
 */
const recordAttendance = async (req, res, next) => {
  try {
    const { classId, date, records } = req.body;
    const schoolId = req.user.schoolId;

    if (!schoolId) return res.status(400).json({ error: 'User is not associated with any school' });
    if (!classId || !date || !records || !Array.isArray(records)) {
      return res.status(400).json({ error: 'Required fields: classId, date, records (array)' });
    }

    // Format records for insertion
    const attendanceInserts = records.map(record => ({
      student_id: record.studentId,
      class_id: classId,
      school_id: schoolId,
      date: date,
      status: record.status // 'present', 'absent', 'late', 'excused'
    }));

    // Upsert attendance records to prevent duplicates on the same day
    const { data, error } = await supabaseAdmin
      .from('attendance')
      .upsert(attendanceInserts, { onConflict: 'student_id,date' }) // unique index helper on DB
      .select();

    // Note: If upsert returns error because constraint was missing, we delete existing records for that day and insert
    if (error) {
      // Fallback: Delete and insert
      const studentIds = records.map(r => r.studentId);
      await supabaseAdmin
        .from('attendance')
        .delete()
        .eq('class_id', classId)
        .eq('date', date)
        .in('student_id', studentIds);

      const { data: insertData, error: insertError } = await supabaseAdmin
        .from('attendance')
        .insert(attendanceInserts)
        .select();
      
      if (insertError) throw insertError;
      return res.json({ message: 'Attendance recorded successfully', data: insertData });
    }

    res.json({ message: 'Attendance recorded successfully', data });
  } catch (err) {
    next(err);
  }
};

/**
 * 6. Get Attendance history
 */
const getAttendance = async (req, res, next) => {
  try {
    const user = req.user;
    const { classId, date, studentId } = req.query;

    let query = supabaseAdmin.from('attendance').select(`
      id,
      status,
      date,
      student:profiles!attendance_student_id_fkey(id, full_name, student_roll_number),
      class:classes(id, name)
    `);

    // Enforce Tenant Boundaries
    if (user.role === 'admin' || user.role === 'teacher') {
      query = query.eq('school_id', user.schoolId);
      if (classId) query = query.eq('class_id', classId);
      if (date) query = query.eq('date', date);
      if (studentId) query = query.eq('student_id', studentId);
    } else if (user.role === 'student') {
      // Students can only see their own attendance
      query = query.eq('student_id', user.id);
      if (date) query = query.eq('date', date);
    } else if (user.role === 'parent') {
      // Parents can only see attendance of students linking to them as parent_id
      const { data: kids } = await supabaseAdmin
        .from('profiles')
        .select('id')
        .eq('parent_id', user.id);
      
      const kidIds = kids ? kids.map(k => k.id) : [];
      if (kidIds.length === 0) return res.json([]);
      
      query = query.in('student_id', kidIds);
      if (studentId && kidIds.includes(studentId)) {
        query = query.eq('student_id', studentId);
      }
      if (date) query = query.eq('date', date);
    }

    const { data, error } = await query.order('date', { ascending: false });
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * 7. Assign Homework (Teacher action)
 */
const assignHomework = async (req, res, next) => {
  try {
    const { title, description, dueDate, classId, attachmentUrl } = req.body;
    const teacherId = req.user.id;

    if (!title || !dueDate || !classId) {
      return res.status(400).json({ error: 'Required fields: title, dueDate, classId' });
    }

    const { data, error } = await supabaseAdmin
      .from('homework')
      .insert({
        title,
        description: description || null,
        due_date: dueDate,
        class_id: classId,
        teacher_id: teacherId,
        attachment_url: attachmentUrl || null
      })
      .select()
      .single();

    if (error) throw error;
    res.status(211).json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * 8. Submit Homework (Student action)
 */
const submitHomework = async (req, res, next) => {
  try {
    const { homeworkId, submissionText, fileUrl } = req.body;
    const studentId = req.user.id;

    if (!homeworkId) return res.status(400).json({ error: 'homeworkId is required' });

    const { data, error } = await supabaseAdmin
      .from('homework_submissions')
      .upsert({
        homework_id: homeworkId,
        student_id: studentId,
        submission_text: submissionText || null,
        file_url: fileUrl || null,
        submitted_at: new Date().toISOString()
      }, { onConflict: 'homework_id,student_id' })
      .select()
      .single();

    if (error) throw error;
    res.json({ message: 'Homework submitted successfully', data });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createSchool,
  createClass,
  getClasses,
  getStudents,
  recordAttendance,
  getAttendance,
  assignHomework,
  submitHomework,
};
