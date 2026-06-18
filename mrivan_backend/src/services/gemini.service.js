const { GoogleGenAI } = require('@google/genai');
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;
const ai = apiKey ? new GoogleGenAI({ apiKey }) : null;

/**
 * 1. AI subject-specific Tutor Chat
 */
const getTutorChatResponse = async (history, message, subject = 'General', grade = '10') => {
  if (!ai) return "Tutor Mode (Demo): Gemini API key is missing. Add GEMINI_API_KEY to .env to enable the AI tutor.";

  const systemInstruction = `You are "Mr. Ivan AI", an empathetic, brilliant, and supportive AI school tutor.
  Your task is to teach the student who is in Grade ${grade} studying ${subject}.
  
  CRITICAL RULES:
  - DO NOT just give the student direct answers or do their homework for them.
  - Explain the underlying concepts step-by-step using interesting real-world analogies, thought-provoking questions, and breakdown steps.
  - Guide the student to find the answer themselves.
  - Adapt your language to be engaging, age-appropriate, and encouraging.
  - Format your math expressions clearly using standard text or simple markdown.`;

  // Map history to Gemini's format: { role: 'user'|'model', parts: [{ text: '...' }] }
  const formattedHistory = history.map(h => ({
    role: h.sender === 'user' ? 'user' : 'model',
    parts: [{ text: h.content }]
  }));

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [
        ...formattedHistory,
        { role: 'user', parts: [{ text: message }] }
      ],
      config: {
        systemInstruction: systemInstruction,
      }
    });
    return response.text;
  } catch (error) {
    console.error('Gemini Tutor chat failed:', error);
    throw error;
  }
};

/**
 * 2. Generate detailed structured study notes (Markdown format)
 */
const generateStudyNotes = async (topic, subject = 'General', grade = '10') => {
  if (!ai) {
    return `# ${topic} (Study Guide)\n\n*Demo Mode: Add GEMINI_API_KEY to .env to generate AI study guides.*\n\n- Concept Explanation: Standard textbook definition.\n- Key Takeaways: Memorize facts.\n- Common Pitfalls: Careless errors.`;
  }

  const prompt = `Create a comprehensive, highly organized study guide for a Grade ${grade} student on the topic: "${topic}" in ${subject}.
  
  Include the following sections in clean Markdown format:
  1. **Topic Title** (Heading 1)
  2. **Core Concepts & Definitions** (Explained simply with bullet points)
  3. **Visual or Practical Analogies** (To help the student build an intuitive understanding)
  4. **Step-by-Step Example Problems** (With explanations of each step)
  5. **Quick Quiz/Self-Review Questions** (At least 3 questions to test understanding, with answers hidden at the bottom or marked)
  6. **Revision Checklist / Cheat Sheet** (Summary of formulas or key facts)
  
  Format it professionally so it renders beautifully in a markdown viewer.`;

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
    });
    return response.text;
  } catch (error) {
    console.error('Gemini notes generation failed:', error);
    throw error;
  }
};

/**
 * 3. Generate structured practice quiz (JSON Schema output)
 */
const generateQuizQuestions = async (subject, topic, count = 5) => {
  if (!ai) {
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

  const prompt = `Generate a practice quiz about "${topic}" in the subject "${subject}".
  Produce exactly ${count} multiple choice questions.
  You MUST return the output as a raw JSON array matching this exact schema structure:
  [
    {
      "question": "question text",
      "options": ["option A", "option B", "option C", "option D"],
      "correctAnswer": "exact matching text of the correct option",
      "explanation": "brief explanation of why it is correct"
    }
  ]
  Do NOT include any markdown code blocks, backticks, or prefix text. Return only valid JSON.`;

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
    });
    const text = response.text.trim();
    
    try {
      // Strip markdown formatting if Gemini included it despite instructions
      let jsonString = text;
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.substring(7, jsonString.length - 3);
      } else if (jsonString.startsWith('```')) {
        jsonString = jsonString.substring(3, jsonString.length - 3);
      }
      return JSON.parse(jsonString.trim());
    } catch (error) {
      console.error('Failed to parse Gemini quiz JSON response. Raw text:', text);
      throw new Error('AI failed to generate quiz in structured JSON format. Please try again.');
    }
  } catch (error) {
    console.error('Gemini quiz generation failed:', error);
    throw error;
  }
};

/**
 * 4. Generate speech-optimized concepts (Voice Tutor helper)
 */
const generateVoiceExplanation = async (concept, subject = 'General') => {
  if (!ai) return "This is a voice demonstration response. Please configure your Gemini API key to activate voice mode.";

  const prompt = `Explain the concept "${concept}" in ${subject} as if you are speaking directly to a student.
  
  RULES:
  - Write it to be read aloud (Speech-to-Text friendly).
  - Use short, clear sentences.
  - Avoid complex text notations, bullet points, brackets, or math symbols.
  - Keep it under 100 words.
  - Make it sound warm and conversational.`;

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
    });
    return response.text;
  } catch (error) {
    console.error('Gemini voice explanation failed:', error);
    throw error;
  }
};

module.exports = {
  getTutorChatResponse,
  generateStudyNotes,
  generateQuizQuestions,
  generateVoiceExplanation,
};
