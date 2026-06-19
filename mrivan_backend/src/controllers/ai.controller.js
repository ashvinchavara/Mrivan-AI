const { supabaseAdmin } = require('../config/db');
const geminiService = require('../services/gemini.service');

/**
 * 1. AI Tutor Chat Controller
 * Manages persisting session history and generating responses with Gemini.
 */
const getTutorChat = async (req, res, next) => {
  try {
    const { message, sessionId, subject, gradeLevel } = req.body;
    const userId = req.user.id;

    if (!message) return res.status(400).json({ error: 'Message is required' });

    let activeSessionId = sessionId;

    // Create session if it doesn't exist
    if (!activeSessionId) {
      const { data: session, error: sessionError } = await supabaseAdmin
        .from('ai_chat_sessions')
        .insert({
          user_id: userId,
          title: message.substring(0, 40) + '...',
          subject: subject || 'General'
        })
        .select()
        .single();

      if (sessionError) throw sessionError;
      activeSessionId = session.id;
    }

    // Retrieve past messages (limit history context to last 10 messages for token efficiency)
    const { data: rawHistory, error: historyError } = await supabaseAdmin
      .from('ai_chat_messages')
      .select('sender, content, timestamp')
      .eq('session_id', activeSessionId)
      .order('timestamp', { ascending: true })
      .limit(10);

    if (historyError) throw historyError;

    // Call Gemini API to generate pedagogical response
    const aiResponse = await geminiService.getTutorChatResponse(
      rawHistory || [],
      message,
      subject || 'General',
      gradeLevel || '10'
    );

    // Store user message in DB
    const { error: userMsgError } = await supabaseAdmin
      .from('ai_chat_messages')
      .insert({
        session_id: activeSessionId,
        sender: 'user',
        content: message
      });

    if (userMsgError) throw userMsgError;

    // Store AI response in DB
    const { error: aiMsgError } = await supabaseAdmin
      .from('ai_chat_messages')
      .insert({
        session_id: activeSessionId,
        sender: 'ai',
        content: aiResponse
      });

    if (aiMsgError) throw aiMsgError;

    // Update session update timestamp
    await supabaseAdmin
      .from('ai_chat_sessions')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', activeSessionId);

    res.json({
      sessionId: activeSessionId,
      response: aiResponse
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 2. AI Study Notes Generator
 * Generates and optionally stores notes for the user.
 */
const generateNotes = async (req, res, next) => {
  try {
    const { topic, subject, gradeLevel, saveToLibrary } = req.body;
    const userId = req.user.id;

    if (!topic) return res.status(400).json({ error: 'Topic is required' });

    // Generate markdown notes via Gemini
    const markdownContent = await geminiService.generateStudyNotes(
      topic,
      subject || 'General',
      gradeLevel || '10'
    );

    let noteRecord = null;

    // Save generated notes to database library if requested
    if (saveToLibrary === true) {
      const { data, error } = await supabaseAdmin
        .from('notes')
        .insert({
          user_id: userId,
          title: topic,
          content: markdownContent,
          subject: subject || 'General',
          class_level: gradeLevel || '10',
          is_ai_generated: true
        })
        .select()
        .single();
      
      if (error) throw error;
      noteRecord = data;
    }

    res.json({
      notes: markdownContent,
      noteRecord
    });
  } catch (err) {
    next(err);
  }
};

/**
 * 3. AI Quiz Generator
 * Returns structured JSON quiz questions.
 */
const generateQuiz = async (req, res, next) => {
  try {
    const { subject, topic, count } = req.body;
    
    if (!topic || !subject) {
      return res.status(400).json({ error: 'Required fields: subject, topic' });
    }

    const quizQuestions = await geminiService.generateQuizQuestions(
      subject,
      topic,
      count || 5
    );

    res.json(quizQuestions);
  } catch (err) {
    next(err);
  }
};

/**
 * 4. AI Voice Explanation Helper
 */
const getVoiceTutor = async (req, res, next) => {
  try {
    const { concept, subject } = req.body;
    if (!concept) return res.status(400).json({ error: 'Concept is required' });

    const spokenExplanation = await geminiService.generateVoiceExplanation(
      concept,
      subject || 'General'
    );

    res.json({
      explanation: spokenExplanation
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getTutorChat,
  generateNotes,
  generateQuiz,
  getVoiceTutor,
};
