export interface CodeFile {
  path: string;
  language: string;
  description: string;
  content: string;
}

export const MRIVAN_FILES: CodeFile[] = [
  {
    path: "mrivan_backend/README.md",
    language: "markdown",
    description: "Backend deployment guidelines, architecture mapping, and full API endpoint documentation.",
    content: `# Mrivan AI - Backend API Server

This is the Node.js + Express backend server for **Mrivan AI (School CRM & AI Tutor Platform)**. It connects to your PostgreSQL database hosted on Supabase and integrates Google Gemini API for pedagogical tutoring.

---

## 🚀 Quick Start (Local Setup)

### 1. Database Setup (Supabase)
1. Go to your **Supabase Dashboard** and open the **SQL Editor**.
2. Copy the contents of \`supabase_schema.sql\`.
3. Paste the script and click **Run** to generate the required CRM & AI tables, relationships, and scale-optimized indexes.

### 2. Environment Configuration
1. Create a \`.env\` file in the root of the \`mrivan_backend\` folder:
   \`\`\`bash
   cp .env.example .env
   \`\`\`
2. Populate the variables inside \`.env\`:
   - **\`SUPABASE_URL\`**: Your Supabase project API URL.
   - **\`SUPABASE_ANON_KEY\`**: Your project API anon key.
   - **\`SUPABASE_SERVICE_ROLE_KEY\`**: Bypasses Row Level Security (RLS) on server-side queries.
   - **\`GEMINI_API_KEY\`**: Get a key from Google AI Studio.

### 3. Install Dependencies & Run
\`\`\`bash
# Install NPM packages
npm install

# Start the server in Development mode
npm run dev

# Start the server in Production mode
npm run start
\`\`\`
The server will boot up at **http://localhost:3000**.

---

## ⚙️🔑 API Reference Documentation

All endpoints require authentication. Pass the Supabase JWT token in the request headers:
\`Authorization: Bearer <your_supabase_jwt_token>\`

### 1. Authentication
*   **\`POST /api/auth/sync\`**: Synchronizes a logged-in Supabase user with our custom public \`profiles\` table. Handles names and user roles.

### 2. CRM Operations
*   **\`POST /api/crm/schools\`**: (Admin only) Creates a school tenant.
*   **\`POST /api/crm/classes\`**: (Admin only) Creates a classroom section.
*   **\`GET /api/crm/classes\`**: (Admin/Teacher) Lists all classrooms.
*   **\`GET /api/crm/students\`**: (Admin/Teacher) Lists students (filter by \`classId\` query parameters).
*   **\`POST /api/crm/attendance\`**: (Teacher only) Records daily attendance for students in bulk.
*   **\`GET /api/crm/attendance\`**: (All Roles) Retrieves attendance logs with tenant filtering (students only see theirs, parents see children's, teachers see class's).
*   **\`POST /api/crm/homework\`**: (Teacher only) Assigns homework to a classroom.
*   **\`POST /api/crm/homework/submit\`**: (Student only) Submits text/file links for homework assignments.

### 3. AI Learning Tools (Gemini SDK)
*   **\`POST /api/ai/tutor/chat\`**: Handles conversation with **Mr. Ivan AI** (empathetic step-by-step tutoring prompt). Persists chat history dynamically in the database.
*   **\`POST /api/ai/notes\`**: Generates and saves clean markdown study guides on a specific topic.
*   **\`POST /api/ai/quiz\`**: Generates structured multiple-choice questions (JSON format).
*   **\`POST /api/ai/voice\`**: Short, conversational concepts for text-to-speech reading.

### 4. CBT Mock Tests
*   **\`POST /api/tests\`**: (Admin/Teacher) Creates a multiple choice mock test.
*   **\`GET /api/tests\`**: Lists available tests.
*   **\`GET /api/tests/:id\`**: Gets test questions.
*   **\`POST /api/tests/:id/attempt\`**: Submits attempt sheet, auto-grades answers, and logs history.`
  },
  {
    path: "mrivan_backend/package.json",
    language: "json",
    description: "Backend dependencies manifest showcasing external modules and NPM startup configurations.",
    content: `{
  "name": "mrivan-backend",
  "version": "1.0.0",
  "description": "Node.js + Express backend server for Mrivan AI - School CRM & AI Tutor",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "@google/generative-ai": "^0.11.0",
    "@supabase/supabase-js": "^2.43.4",
    "cloudinary": "^2.2.0",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2"
  },
  "devDependencies": {
    "nodemon": "^3.1.2"
  },
  "engines": {
    "node": ">=18.0.0"
  },
  "private": true
}`
  },
  {
    path: "mrivan_backend/src/app.js",
    language: "javascript",
    description: "Express framework initialization, modular routing mounts, and default middleware bindings.",
    content: `const express = require('express');
const cors = require('cors');
const { errorHandler } = require('./middleware/error.middleware');

// Route imports
const authRoutes = require('./routes/auth.routes');
const crmRoutes = require('./routes/crm.routes');
const aiRoutes = require('./routes/ai.routes');
const testRoutes = require('./routes/test.routes');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Base Server Verification Route
app.get('/', (req, res) => {
  res.json({
    name: 'Mrivan AI API Server',
    status: 'Operational',
    version: '1.0.0',
    documentation: '/readme'
  });
});

// Mount modular API routes
app.use('/api/auth', authRoutes);
app.use('/api/crm', crmRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/tests', testRoutes);

// Global Error Handler Middleware
app.use(errorHandler);

module.exports = app;`
  },
  {
    path: "mrivan_backend/src/controllers/ai.controller.js",
    language: "javascript",
    description: "Orchestration controller for chat histories, notes generation, and automated quiz creation.",
    content: `const { supabaseAdmin } = require('../config/db');
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

    // Store user message in DB
    const { error: userMsgError } = await supabaseAdmin
      .from('ai_chat_messages')
      .insert({
        session_id: activeSessionId,
        sender: 'user',
        content: message
      });

    if (userMsgError) throw userMsgError;

    // Call Gemini API to generate pedagogical response
    const aiResponse = await geminiService.getTutorChatResponse(
      rawHistory || [],
      message,
      subject || 'General',
      gradeLevel || '10'
    );

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
};`
  },
  {
    path: "mrivan_backend/src/controllers/test.controller.js",
    language: "javascript",
    description: "CBT automated testing, score recording, and multi-choice question evaluator.",
    content: `const { supabaseAdmin } = require('../config/db');

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
};`
  },
  {
    path: "mrivan_backend/src/services/gemini.service.js",
    language: "javascript",
    description: "Empathetic system prompt, study plan generator via Google Gemini, legacy API wrapper.",
    content: `const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;
const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : null;

/**
 * Helper to get Gemini model instance.
 */
const getModel = (options = {}) => {
  if (!genAI) {
    throw new Error('Google Gemini API Key is not configured. Add GEMINI_API_KEY to your .env file.');
  }
  return genAI.getGenerativeModel({
    model: options.model || "gemini-1.5-flash",
    ...options
  });
};

/**
 * 1. AI subject-specific Tutor Chat
 */
const getTutorChatResponse = async (history, message, subject = 'General', grade = '10') => {
  if (!genAI) return "Tutor Mode (Demo): Gemini API key is missing. Add GEMINI_API_KEY to .env to enable the AI tutor.";

  const model = getModel();
  
  const systemInstruction = \`You are "Mr. Ivan AI", an empathetic, brilliant, and supportive AI school tutor.
  Your task is to teach the student who is in Grade \${grade} studying \${subject}.
  
  CRITICAL RULES:
  - DO NOT just give the student direct answers or do their homework for them.
  - Explain the underlying concepts step-by-step using interesting real-world analogies, thought-provoking questions, and breakdown steps.
  - Guide the student to find the answer themselves.
  - Adapt your language to be engaging, age-appropriate, and encouraging.
  - Format your math expressions clearly using standard text or simple markdown.\`;

  // Map history to Gemini's format: { role: 'user'|'model', parts: [{ text: '...' }] }
  const formattedHistory = history.map(h => ({
    role: h.sender === 'user' ? 'user' : 'model',
    parts: [{ text: h.content }]
  }));

  const chat = model.startChat({
    history: formattedHistory,
    systemInstruction: systemInstruction,
  });

  const result = await chat.sendMessage(message);
  return result.response.text();
};

/**
 * 2. Generate detailed structured study notes (Markdown format)
 */
const generateStudyNotes = async (topic, subject = 'General', grade = '10') => {
  if (!genAI) {
    return \`# \${topic} (Study Guide)

*Demo Mode: Add GEMINI_API_KEY to .env to generate AI study guides.*

- Concept Explanation: Standard textbook definition.
- Key Takeaways: Memorize facts.
- Common Pitfalls: Careless errors.\`;
  }

  const model = getModel();
  const prompt = \`Create a comprehensive, highly organized study guide for a Grade \${grade} student on the topic: "\${topic}" in \${subject}.
  
  Include the following sections in clean Markdown format:
  1. **Topic Title** (Heading 1)
  2. **Core Concepts & Definitions** (Explained simply with bullet points)
  3. **Visual or Practical Analogies** (To help the student build an intuitive understanding)
  4. **Step-by-Step Example Problems** (With explanations of each step)
  5. **Quick Quiz/Self-Review Questions** (At least 3 questions to test understanding, with answers hidden at the bottom or marked)
  6. **Revision Checklist / Cheat Sheet** (Summary of formulas or key facts)
  
  Format it professionally so it renders beautifully in a markdown viewer.\`;

  const result = await model.generateContent(prompt);
  return result.response.text();
};

/**
 * 3. Generate structured practice quiz (JSON Schema output)
 */
const generateQuizQuestions = async (subject, topic, count = 5) => {
  if (!genAI) {
    // Return mock questions if API key is missing
    return [
      {
        question: "What is the primary function of DNA? (Demo Question)",
        options: ["Store genetic information", "Synthesize lipids", "Provide cell rigidity", "Produce energy"],
        correctAnswer: "Store genetic information",
        explanation: "DNA acts as the storage repository of genetic instructions inside cells."
      }
    ];
  }

  const model = getModel();
  const prompt = \`Generate a practice quiz about "\${topic}" in the subject "\${subject}".
  Produce exactly \${count} multiple choice questions.
  You MUST return the output as a raw JSON array matching this exact schema structure:
  [
    {
      "question": "question text",
      "options": ["option A", "option B", "option C", "option D"],
      "correctAnswer": "exact matching text of the correct option",
      "explanation": "brief explanation of why it is correct"
    }
  ]
  Do NOT include any markdown code blocks, backticks, or prefix text. Return only valid JSON.\`;

  const result = await model.generateContent(prompt);
  const text = result.response.text().trim();
  
  try {
    // Strip markdown formatting if Gemini included it despite instructions
    let jsonString = text;
    if (jsonString.startsWith('\`\`\`json')) {
      jsonString = jsonString.substring(7, jsonString.length - 3);
    } else if (jsonString.startsWith('\`\`\`')) {
      jsonString = jsonString.substring(3, jsonString.length - 3);
    }
    return JSON.parse(jsonString.trim());
  } catch (error) {
    console.error('Failed to parse Gemini quiz JSON response. Raw text:', text);
    throw new Error('AI failed to generate quiz in structured JSON format. Please try again.');
  }
};

/**
 * 4. Generate speech-optimized concepts (Voice Tutor helper)
 */
const generateVoiceExplanation = async (concept, subject = 'General') => {
  if (!genAI) return "This is a voice demonstration response. Please configure your Gemini API key to activate voice mode.";

  const model = getModel();
  const prompt = \`Explain the concept "\${concept}" in \${subject} as if you are speaking directly to a student.
  
  RULES:
  - Write it to be read aloud (Speech-to-Text friendly).
  - Use short, clear sentences.
  - Avoid complex text notations, bullet points, brackets, or math symbols.
  - Keep it under 100 words.
  - Make it sound warm and conversational.\`;

  const result = await model.generateContent(prompt);
  return result.response.text();
};

module.exports = {
  getTutorChatResponse,
  generateStudyNotes,
  generateQuizQuestions,
  generateVoiceExplanation,
};`
  },
  {
    path: "mrivan_ai/pubspec.yaml",
    language: "yaml",
    description: "Flutter manifest showing package dependencies, static typography assets, and configurations.",
    content: `name: mrivan_ai
description: "School CRM and AI tutor"
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter
  flutter_web_plugins:
    sdk: flutter

  cupertino_icons: ^1.0.8
  supabase_flutter: ^2.8.0
  google_sign_in: ^6.2.1
  http: ^1.6.0
  flutter_svg: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/logo.jpeg`
  },
  {
    path: "mrivan_ai/lib/main.dart",
    language: "dart",
    description: "App initialization displaying critical security vulnerabilities (hardcoded database credentials).",
    content: `import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/screens/auth/landing_page.dart';
import 'presentation/screens/dashboard/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // SECURITY FLUSH WARNING: Credentials exposed natively in Dart Client Code
  await Supabase.initialize(
    url: 'https://hajwgwskgtwdmvivisysq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhham9nd3NrZ3R3ZG12aXZpeXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1NDc2MTIsImV4cCI6MjA5NzEyMzYxMn0.sxr1yCql0VWtBDk9qJvrjgpKLeEZx0PpQjh8svYCGFFE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mrivan AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF155DFC)),
        useMaterial3: true,
      ),
      home: const AuthStateRouter(),
    );
  }
}

class AuthStateRouter extends StatelessWidget {
  const AuthStateRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const AppRouter();
        } else {
          return const LandingPageScreen();
        }
      },
    );
  }
}`
  }
];
