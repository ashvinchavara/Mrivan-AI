const { supabaseAdmin } = require('../config/db');

/**
 * 1. Create a new Mock Test (Admin / Teacher action)
 */
const createMockTest = async (req, res, next) => {
  try {
    const { title, description, subject, durationMinutes, totalMarks, questions } = req.body;

    if (!title || !subject || !questions || !Array.isArray(questions)) {
      return res.status(400).json({ error: 'Required fields: title, subject, questions (array)' });
    }

    const { data, error } = await supabaseAdmin
      .from('mock_tests')
      .insert({
        title,
        description: description || null,
        subject,
        duration_minutes: durationMinutes || 60,
        total_marks: totalMarks || 100,
        questions: questions
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
 * 2. Get all Mock Tests (filtered optionally by subject)
 */
const getMockTests = async (req, res, next) => {
  try {
    const { subject } = req.query;

    let query = supabaseAdmin.from('mock_tests').select('id, title, description, subject, duration_minutes, total_marks, created_at');
    if (subject) {
      query = query.eq('subject', subject);
    }

    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * 3. Get Mock Test Details (includes questions for students to take the test)
 */
const getMockTestDetails = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { data, error } = await supabaseAdmin
      .from('mock_tests')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) {
      return res.status(404).json({ error: 'Mock test not found' });
    }

    res.json(data);
  } catch (err) {
    next(err);
  }
};

/**
 * 4. Attempt and Auto-Grade a Mock Test (Student action)
 * Auto-grades Multiple Choice questions and inserts the attempt history.
 */
const attemptMockTest = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { answers } = req.body; // Map: { "questionIndex": "chosenOptionText" }
    const studentId = req.user.id;

    if (!answers || typeof answers !== 'object') {
      return res.status(400).json({ error: 'Answers dictionary is required' });
    }

    // Retrieve the test questions
    const { data: test, error: testError } = await supabaseAdmin
      .from('mock_tests')
      .select('*')
      .eq('id', id)
      .single();

    if (testError || !test) {
      return res.status(404).json({ error: 'Mock test not found' });
    }

    const questions = test.questions;
    let correctCount = 0;
    const gradingDetails = [];

    // Loop through questions and compare correct options
    questions.forEach((q, index) => {
      const studentAnswer = answers[index.toString()];
      const isCorrect = studentAnswer !== undefined && studentAnswer === q.correctAnswer;

      if (isCorrect) correctCount++;

      gradingDetails.push({
        questionIndex: index,
        questionText: q.question,
        studentAnswer: studentAnswer || 'Unanswered',
        correctAnswer: q.correctAnswer,
        isCorrect,
        explanation: q.explanation || ''
      });
    });

    // Calculate score relative to total marks
    const totalQuestions = questions.length;
    const finalScore = totalQuestions > 0 
      ? Math.round((correctCount / totalQuestions) * test.total_marks)
      : 0;

    // Log the test attempt in database
    const { data: attempt, error: attemptError } = await supabaseAdmin
      .from('test_attempts')
      .insert({
        test_id: id,
        student_id: studentId,
        score: finalScore,
        answers: answers,
        completed_at: new Date().toISOString()
      })
      .select()
      .single();

    if (attemptError) throw attemptError;

    res.json({
      attemptId: attempt.id,
      score: finalScore,
      totalMarks: test.total_marks,
      correctCount,
      totalQuestions,
      gradingDetails
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createMockTest,
  getMockTests,
  getMockTestDetails,
  attemptMockTest,
};
