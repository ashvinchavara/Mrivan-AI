const { GoogleGenAI } = require('@google/genai');
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;
const ai = apiKey ? new GoogleGenAI({ apiKey }) : null;

const apiKey2 = process.env.GEMINI_API_KEY_2;
const ai2 = apiKey2 ? new GoogleGenAI({ apiKey: apiKey2 }) : null;

let currentProviderIndex = 0;

const PROVIDER_CONFIGS = {
  groq: {
    url: 'https://api.groq.com/openai/v1/chat/completions',
    model: 'llama-3.3-70b-versatile',
    getHeaders: () => ({ 'Authorization': `Bearer ${process.env.GROQ_API_KEY}` })
  },
  openrouter: {
    url: 'https://openrouter.ai/api/v1/chat/completions',
    model: 'meta-llama/llama-3-8b-instruct',
    getHeaders: () => ({ 'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}` })
  },
  nvidia: {
    url: 'https://integrate.api.nvidia.com/v1/chat/completions',
    model: 'nvidia/nemotron-3-ultra-550b-a55b',
    getHeaders: () => ({ 'Authorization': `Bearer ${process.env.NVIDIA_API_KEY}` })
  },
  ainative: {
    url: 'https://api.ainative.studio/v1/chat/completions',
    model: 'gpt-3.5-turbo',
    getHeaders: () => ({
      'Authorization': `Bearer ${process.env.AI_NATIVE_API_KEY}`,
      'X-API-Key': process.env.AI_NATIVE_API_KEY
    })
  },
  huggingface: {
    url: 'https://router.huggingface.co/v1/chat/completions',
    model: 'meta-llama/Meta-Llama-3-8B-Instruct',
    getHeaders: () => ({ 'Authorization': `Bearer ${process.env.HF_TOKEN}` })
  }
};

const makeOpenAICall = async (url, headers, body) => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000); // 30-second timeout

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...headers
      },
      body: JSON.stringify(body),
      signal: controller.signal
    });
    
    clearTimeout(timeoutId);

    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`HTTP ${res.status}: ${errorText || res.statusText}`);
    }

    const data = await res.json();
    if (data.choices && data.choices[0] && data.choices[0].message) {
      return data.choices[0].message.content;
    }
    throw new Error('Invalid OpenAI-compatible response format');
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
};

const runWithRotation = async (taskName, executeFn) => {
  const providers = [];
  
  if (process.env.GEMINI_API_KEY) {
    providers.push({
      name: 'Gemini',
      execute: async () => {
        if (!ai) throw new Error('Gemini client not initialized');
        return await executeFn('gemini');
      }
    });
  }

  if (process.env.GEMINI_API_KEY_2) {
    providers.push({
      name: 'Gemini 2',
      execute: async () => {
        if (!ai2) throw new Error('Gemini 2 client not initialized');
        return await executeFn('gemini2');
      }
    });
  }
  
  if (process.env.GROQ_API_KEY) {
    providers.push({
      name: 'Groq',
      execute: async () => await executeFn('groq')
    });
  }

  if (process.env.OPENROUTER_API_KEY) {
    providers.push({
      name: 'OpenRouter',
      execute: async () => await executeFn('openrouter')
    });
  }

  if (process.env.NVIDIA_API_KEY) {
    providers.push({
      name: 'Nvidia',
      execute: async () => await executeFn('nvidia')
    });
  }

  if (process.env.AI_NATIVE_API_KEY) {
    providers.push({
      name: 'AI Native',
      execute: async () => await executeFn('ainative')
    });
  }

  if (process.env.HF_TOKEN) {
    providers.push({
      name: 'Hugging Face',
      execute: async () => await executeFn('huggingface')
    });
  }

  if (providers.length === 0) {
    throw new Error('No AI provider API keys are configured in the environment variables.');
  }

  let lastError = null;
  const startIndex = currentProviderIndex % providers.length;
  
  for (let i = 0; i < providers.length; i++) {
    const idx = (startIndex + i) % providers.length;
    const provider = providers[idx];
    console.log(`[ORCHESTRATOR] [${taskName}] Attempting with provider: ${provider.name}`);
    try {
      const result = await provider.execute();
      if (result) {
        currentProviderIndex = (idx + 1) % providers.length;
        return result;
      }
      throw new Error('Empty response received');
    } catch (err) {
      console.warn(`[ORCHESTRATOR] [${taskName}] Provider ${provider.name} failed or timed out:`, err.message || err);
      lastError = err;
    }
  }

  throw new Error(`All configured AI providers failed to respond. Last error: ${lastError ? lastError.message : 'Unknown error'}`);
};

/**
 * 1. AI subject-specific Tutor Chat
 */
const getTutorChatResponse = async (history, message, subject = 'General', grade = '10', switchAi = false) => {
  if (!ai && !ai2) return "Tutor Mode (Demo): Gemini API key is missing. Add GEMINI_API_KEY to .env to enable the AI tutor.";

  if (switchAi) {
    currentProviderIndex++;
    console.log(`[ORCHESTRATOR] Frontend requested AI switch. New currentProviderIndex: ${currentProviderIndex}`);
  }

  // 1. Parse grade level and explanation style
  let gradeText = grade.toLowerCase();
  let explanationStyle = 'Simple Explanation';

  if (grade.includes(' - ')) {
    const parts = grade.split(' - ');
    gradeText = parts[0].toLowerCase();
    explanationStyle = parts[1];
  }

  // Extract numerical grade number
  let numericGrade = 10; // default to 10th Grade
  const gradeMatch = gradeText.match(/(\d+)/);
  if (gradeMatch) {
    numericGrade = parseInt(gradeMatch[1], 10);
  } else if (gradeText.includes('college')) {
    numericGrade = 16;
  }

  // 2. Build system instructions tailored to Cohort, Subject, and Style
  let roleText = `You are "Mr. Ivan AI", an empathetic, brilliant, and supportive expert AI ${subject} tutor.`;
  let cohortInstructions = '';
  
  if (numericGrade <= 5) {
    // Elementary (Grades 1-5)
    roleText = `You are "Mr. Ivan AI", an expert ${subject} tutor teaching a Grade ${numericGrade} student.`;
    cohortInstructions = `
CRITICAL RULES FOR TEACHING GRADE ${numericGrade} STUDENTS:
* Use simple, age-appropriate language suitable for a ${numericGrade === 5 ? '10-11' : (numericGrade + 5) + '-' + (numericGrade + 6)} year old student.
* Keep explanations short and easy to understand.
* Use everyday examples and simple analogies when possible.
* Avoid complex scientific or technical terms unless you explain them immediately.
* Be encouraging, warm, friendly, and supportive.
* ALWAYS structure your answers strictly in the following sequence:
  1. Simple definition: Explain the concept in one or two simple sentences using a catchy analogy (e.g. if explaining photosynthesis, say "Plants are like tiny food factories. They use sunlight, water, and carbon dioxide from the air to make their own food.").
  2. Easy explanation: Break it down step-by-step using extremely simple language.
  3. Real-life example: Provide an example they see in everyday life.
  4. One fun fact: Share a surprising, kid-friendly fun fact.
* End with a simple, encouraging question to check their understanding.`;
  } else if (numericGrade >= 6 && numericGrade <= 8) {
    // Middle School (Grades 6-8)
    roleText = `You are "Mr. Ivan AI", an expert ${subject} tutor teaching a Grade ${numericGrade} middle school student.`;
    cohortInstructions = `
CRITICAL RULES FOR TEACHING GRADE ${numericGrade} STUDENTS:
* Use simple but conceptually clear, age-appropriate language suitable for an early teenager (ages 11-14).
* Keep explanations concise, structured, and engaging.
* Connect the concepts to real-life applications and teenager interests (like sports, gaming, nature, popular culture).
* Avoid overly technical jargon unless defined simply.
* ALWAYS structure your answers in this sequence:
  1. Clear Definition: Explain the concept simply and clearly in a single paragraph.
  2. Step-by-Step Breakdown: Explain the mechanism, process, or steps in an easy-to-follow list.
  3. Real-World Connection: Share how this relates to their daily life or technology.
  4. Fun Fact/Trivia: Provide an interesting, cool fact.
* End with a light conceptual check question to encourage thinking.`;
  } else if (numericGrade >= 9 && numericGrade <= 12) {
    // High School (Grades 9-12)
    roleText = `You are "Mr. Ivan AI", an expert ${subject} tutor teaching a Grade ${numericGrade} high school student.`;
    cohortInstructions = `
CRITICAL RULES FOR TEACHING GRADE ${numericGrade} STUDENTS:
* Use clear, academically sound, and professional language suitable for a high schooler (ages 14-18) preparing for exams or college.
* Explain the underlying concepts comprehensively and logically.
* Structure your answers as:
  1. Formal Definition: Clear academic definition of the concept.
  2. Concept Breakdown: Detailed explanation, including basic equations, formulas, or logical steps.
  3. Worked Example or Case Study: Solve a sample problem or trace a clear example step-by-step.
  4. Practical/Professional Application: Explain how this concept is applied in professional industries or modern scientific research.
* End with an analytical thinking question to challenge their understanding.`;
  } else {
    // College / Advanced
    roleText = `You are "Mr. Ivan AI", a distinguished university professor and supportive research advisor tutoring a college student in ${subject}.`;
    cohortInstructions = `
CRITICAL RULES FOR TUTORING COLLEGE STUDENTS:
* Use scholarly, precise, and advanced academic language.
* Provide deep theoretical and conceptual depth, explaining mechanisms, derivations, proofs, or paradigms.
* Structure your answers as:
  1. Rigorous Definition: Formal definition using correct scientific/academic terminology.
  2. Theoretical Framework/Mechanism: Deep explanation of core dynamics, math, or theories.
  3. Case Implementation/Mathematical Proof: Provide detailed code, formal mathematical formulation, or advanced chemical/physical formulas.
  4. Current Research/Industry Paradigm: Connect to advanced current literature, open research questions, or complex industry systems.
* End with an open-ended conceptual or quantitative question suitable for university study.`;
  }

  // Subject-specific rules
  let subjectInstructions = '';
  const subjLower = subject.toLowerCase();
  
  if (subjLower.includes('biology')) {
    subjectInstructions = `
SUBJECT-SPECIFIC RULES FOR BIOLOGY:
- Focus on living organisms, systems, processes, anatomy, and ecology.
- Use organic, natural analogies (e.g. cell organelles as parts of a city/factory, DNA as a master blueprint, blood circulation as a delivery system).
- Explain biological processes (like photosynthesis, respiration, mitosis) step-by-step.`;
  } else if (subjLower.includes('chemistry')) {
    subjectInstructions = `
SUBJECT-SPECIFIC RULES FOR CHEMISTRY:
- Focus on matter, atoms, elements, compounds, states of matter, and chemical reactions.
- Use chemical/bonding analogies (e.g. atoms as Lego bricks, chemical bonds as sticky glue/magnets, chemical reactions as baking cookies).
- Write chemical formulas clearly (e.g., H_2O, CO_2).`;
  } else if (subjLower.includes('physics')) {
    subjectInstructions = `
SUBJECT-SPECIFIC RULES FOR PHYSICS:
- Focus on mechanics, forces, kinematics, energy, gravity, waves, and thermodynamics.
- Use mechanical, physical analogies (e.g., gravity as a heavy ball on a trampoline, friction as sticky tires on a road).
- Show how math translates to physical behavior (e.g., how force causes acceleration).`;
  } else if (subjLower.includes('math')) {
    subjectInstructions = `
SUBJECT-SPECIFIC RULES FOR MATHEMATICS:
- Focus on numerical, algebraic, geometric, or calculus operations.
- Detail every step of calculations clearly. Highlight intermediate calculations so students don't get lost.
- Warn students about common algebraic/arithmetic errors (e.g. dividing by zero, sign errors).
- Use word problems that apply the math to real scenarios (e.g., sharing a pizza, calculating savings, mapping areas).`;
  } else if (subjLower.includes('history')) {
    subjectInstructions = `
SUBJECT-SPECIFIC RULES FOR HISTORY:
- Focus on historical events, characters, timelines, causes, and consequences.
- Present history like a narrative or story, highlighting the human motivations, conflicts, and outcomes.
- Encourage students to consider different historical perspectives.
- Draw connections to modern-day events or societies.`;
  } else if (subjLower.includes('english')) {
    subjectInstructions = `
SUBJECT-SPECIFIC RULES FOR ENGLISH:
- Focus on vocabulary, grammar, literature analysis, writing style, and comprehension.
- Break down word origins, prefixes, and suffixes.
- Show examples of grammatical concepts or rhetorical devices in literature.
- Offer writing tips or simple edits.`;
  } else if (subjLower.includes('computer')) {
    subjectInstructions = `
SUBJECT-SPECIFIC RULES FOR COMPUTER SCIENCE:
- Focus on programming, logic, variables, algorithms, data structures, and system design.
- Use programmatic analogies (e.g. variables as named drawer boxes, loops as a repetitive chore, arrays as egg cartons).
- Provide clean, commented, and standard code snippets (Python, Javascript, Dart, etc.) where appropriate.
- Explain execution dry runs step-by-step.`;
  }

  // Explanation style rules override
  let styleInstructions = '';
  switch (explanationStyle) {
    case 'Simple Explanation':
      styleInstructions = `
EXPLANATION STYLE OVERRIDE: SIMPLE EXPLANATION
- Emphasize absolute simplicity, directness, and quick understanding.
- Keep explanations light, avoiding heavy structural lists unless requested.
- Prioritize high readability and clarity.`;
      break;
    case 'Detailed Scientific Code':
    case 'Detailed Scientific':
      styleInstructions = `
EXPLANATION STYLE OVERRIDE: DETAILED SCIENTIFIC
- Be highly rigorous, providing full mathematical formulas, scientific formulas, or code details.
- Provide comprehensive, detailed answers without trimming technicalities.
- Add code snippets or formal proofs where relevant.`;
      break;
    case 'Analogies & Flashcards':
      styleInstructions = `
EXPLANATION STYLE OVERRIDE: ANALOGIES & FLASHCARDS
- Provide at least 2 distinct analogies for every core concept.
- Summarize key vocabulary at the end in a "Flashcard Q&A" format (Question on one line, Answer hidden/expandable on the next).`;
      break;
    case 'Socratic Method Practice':
      styleInstructions = `
EXPLANATION STYLE OVERRIDE: SOCRATIC METHOD
- DO NOT explain the concept directly or give the answers.
- Ask a sequence of simple, guided questions that lead the student to discover the answer themselves.
- Acknowledge their answers, build on them, and ask the next question.`;
      break;
    default:
      break;
  }

  const systemInstruction = `${roleText}
  Your task is to teach the student who is studying ${subject} at the ${gradeText} level.
  
  CRITICAL GENERAL RULES:
  - DO NOT just give the student direct answers or do their homework for them.
  - Explain the underlying concepts step-by-step using thought-provoking questions, breakdown steps, and appropriate analogies.
  - Guide the student to find the answer themselves.
  - Format math expressions clearly using standard text, simple subscripts/superscripts (e.g. H_2O, x^2) or basic markdown.
  ${cohortInstructions}
  ${subjectInstructions}
  ${styleInstructions}`;

  return await runWithRotation('TutorChat', async (provider) => {
    if (provider === 'gemini' || provider === 'gemini2') {
      const client = provider === 'gemini' ? ai : ai2;
      const formattedHistory = history.map(h => ({
        role: h.sender === 'user' ? 'user' : 'model',
        parts: [{ text: h.content }]
      }));
      const response = await client.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: [
          ...formattedHistory,
          { role: 'user', parts: [{ text: message }] }
        ],
        config: {
          systemInstruction: systemInstruction,
        }
      });
      return response.text;
    }

    const config = PROVIDER_CONFIGS[provider];
    if (!config) throw new Error(`Unknown provider: ${provider}`);

    const messages = [];
    if (systemInstruction) {
      messages.push({ role: 'system', content: systemInstruction });
    }
    history.forEach(h => {
      messages.push({
        role: h.sender === 'user' ? 'user' : 'assistant',
        content: h.content
      });
    });
    messages.push({ role: 'user', content: message });

    return await makeOpenAICall(config.url, config.getHeaders(), { model: config.model, messages });
  });
};

/**
 * 2. Generate detailed structured study notes (Markdown format)
 */
const generateStudyNotes = async (topic, subject = 'General', grade = '10') => {
  if (!ai && !ai2) {
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

  return await runWithRotation('StudyNotes', async (provider) => {
    if (provider === 'gemini' || provider === 'gemini2') {
      const client = provider === 'gemini' ? ai : ai2;
      const response = await client.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: prompt,
      });
      return response.text;
    }

    const config = PROVIDER_CONFIGS[provider];
    if (!config) throw new Error(`Unknown provider: ${provider}`);

    const messages = [{ role: 'user', content: prompt }];
    return await makeOpenAICall(config.url, config.getHeaders(), { model: config.model, messages });
  });
};

/**
 * 3. Generate structured practice quiz (JSON Schema output)
 */
const generateQuizQuestions = async (subject, topic, count = 5) => {
  if (!ai && !ai2) {
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

  const text = await runWithRotation('QuizGeneration', async (provider) => {
    if (provider === 'gemini' || provider === 'gemini2') {
      const client = provider === 'gemini' ? ai : ai2;
      const response = await client.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: prompt,
      });
      return response.text;
    }

    const config = PROVIDER_CONFIGS[provider];
    if (!config) throw new Error(`Unknown provider: ${provider}`);

    const messages = [{ role: 'user', content: prompt }];
    return await makeOpenAICall(config.url, config.getHeaders(), { model: config.model, messages });
  });

  try {
    let jsonString = text.trim();
    if (jsonString.startsWith('```json')) {
      jsonString = jsonString.substring(7, jsonString.length - 3);
    } else if (jsonString.startsWith('```')) {
      jsonString = jsonString.substring(3, jsonString.length - 3);
    }
    return JSON.parse(jsonString.trim());
  } catch (error) {
    console.error('Failed to parse quiz JSON response. Raw text:', text);
    throw new Error('AI failed to generate quiz in structured JSON format. Please try again.');
  }
};

/**
 * 4. Generate speech-optimized concepts (Voice Tutor helper)
 */
const generateVoiceExplanation = async (concept, subject = 'General') => {
  const prompt = `Explain the concept "${concept}" in ${subject} as if you are speaking directly to a student.
  
  RULES:
  - Write it to be read aloud (Speech-to-Text friendly).
  - Use short, clear sentences.
  - Avoid complex text notations, bullet points, brackets, or math symbols.
  - Keep it under 100 words.
  - Make it sound warm and conversational.`;

  return await runWithRotation('VoiceExplanation', async (provider) => {
    if (provider === 'gemini' || provider === 'gemini2') {
      const client = provider === 'gemini' ? ai : ai2;
      const response = await client.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: prompt,
      });
      return response.text;
    }

    const config = PROVIDER_CONFIGS[provider];
    if (!config) throw new Error(`Unknown provider: ${provider}`);

    const messages = [{ role: 'user', content: prompt }];
    return await makeOpenAICall(config.url, config.getHeaders(), { model: config.model, messages });
  });
};

module.exports = {
  getTutorChatResponse,
  generateStudyNotes,
  generateQuizQuestions,
  generateVoiceExplanation,
  gradeMockInterview,
  analyzeResume,
  parseSyllabus,
  parseTimetable,
};

/**
 * 5. Grade Mock Interview transcript using Gemini (returns JSON evaluation)
 */
async function gradeMockInterview(transcript, role) {
  if (!ai && !ai2) {
    return {
      score: 75,
      feedback: "Mock Interview completed (Demo Mode). Add GEMINI_API_KEY to .env to enable live AI grading.",
      strengths: ["Completed the mock interview structure successfully"],
      improvements: ["Provide more details in answers"]
    };
  }

  const prompt = `You are an expert HR and Technical Recruiter. Grade the following mock interview transcript for the target role of "${role}".
  
  TRANSCRIPT:
  ${transcript}
  
  Evaluate the candidate's responses comprehensively. You MUST return your evaluation strictly in the following JSON structure:
  {
    "score": 82, // integer between 0 and 100 representing overall suitability
    "feedback": "General summary feedback and overall impressions...",
    "strengths": ["Strength 1 text", "Strength 2 text"],
    "improvements": ["Improvement 1 text", "Improvement 2 text"]
  }
  Do NOT include any markdown code blocks, backticks, or prefix text. Return only valid JSON.`;

  const text = await runWithRotation('InterviewGrading', async (provider) => {
    if (provider === 'gemini' || provider === 'gemini2') {
      const client = provider === 'gemini' ? ai : ai2;
      const response = await client.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: prompt,
      });
      return response.text;
    }
    const config = PROVIDER_CONFIGS[provider];
    const messages = [{ role: 'user', content: prompt }];
    return await makeOpenAICall(config.url, config.getHeaders(), { model: config.model, messages });
  });

  try {
    let jsonString = text.trim();
    if (jsonString.startsWith('```json')) {
      jsonString = jsonString.substring(7, jsonString.length - 3);
    } else if (jsonString.startsWith('```')) {
      jsonString = jsonString.substring(3, jsonString.length - 3);
    }
    return JSON.parse(jsonString.trim());
  } catch (error) {
    console.error('Failed to parse interview grading JSON. Raw:', text);
    return {
      score: 70,
      feedback: "Interview completed. Grading could not be parsed into JSON format.",
      strengths: ["Completed the mock interview successfully"],
      improvements: ["Review transcript answers for precision"]
    };
  }
}

/**
 * 6. Analyze Resume against a target job role using Gemini (returns JSON evaluation)
 */
async function analyzeResume(resumeText, role) {
  if (!ai && !ai2) {
    return {
      score: 75,
      matchedKeywords: ["Project Management", "Communication"],
      missingKeywords: ["Technical Architecture"],
      suggestions: "Add more details about technical implementations and frameworks used."
    };
  }

  const prompt = `You are an expert HR Specialist and ATS (Applicant Tracking System) reviewer. Analyze the following candidate's resume text against the target job role: "${role}".
  
  RESUME TEXT:
  ${resumeText}
  
  Evaluate the resume, compute an ATS score, identify matching keywords, missing keywords, and suggest improvements. You MUST return your evaluation strictly in the following JSON structure:
  {
    "score": 85, // integer between 0 and 100 representing suitability/match rate
    "matchedKeywords": ["Keyword 1", "Keyword 2"],
    "missingKeywords": ["Keyword 3", "Keyword 4"],
    "suggestions": "Detailed suggestions and recommendations to improve the resume for this role."
  }
  Do NOT include any markdown code blocks, backticks, or prefix text. Return only valid JSON.`;

  const text = await runWithRotation('ResumeAnalysis', async (provider) => {
    if (provider === 'gemini' || provider === 'gemini2') {
      const client = provider === 'gemini' ? ai : ai2;
      const response = await client.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: prompt,
      });
      return response.text;
    }
    const config = PROVIDER_CONFIGS[provider];
    const messages = [{ role: 'user', content: prompt }];
    return await makeOpenAICall(config.url, config.getHeaders(), { model: config.model, messages });
  });

  try {
    let jsonString = text.trim();
    if (jsonString.startsWith('```json')) {
      jsonString = jsonString.substring(7, jsonString.length - 3);
    } else if (jsonString.startsWith('```')) {
      jsonString = jsonString.substring(3, jsonString.length - 3);
    }
    return JSON.parse(jsonString.trim());
  } catch (error) {
    console.error('Failed to parse resume analysis JSON. Raw:', text);
    return {
      score: 70,
      matchedKeywords: [],
      missingKeywords: [],
      suggestions: "Resume analyzed. Evaluation could not be parsed into JSON format."
    };
  }
}

/**
 * 7. Parse raw syllabus text into structured JSON chapters using Gemini
 */
async function parseSyllabus(syllabusText) {
  if (!ai && !ai2) {
    return [
      {
        "chapter_name": "Unit 1: Introduction",
        "topics": ["Overview of syllabus", "Basic Core Concepts"]
      }
    ];
  }

  const prompt = `You are an expert curriculum designer and educator. Convert the following raw syllabus text into a highly structured JSON array of chapters/lessons, where each chapter has a chapter name and list of topics.

RAW SYLLABUS TEXT:
${syllabusText}

You MUST return your evaluation strictly in the following JSON structure:
[
  {
    "chapter_name": "Chapter 1: Title or Lesson Name",
    "topics": [
      "Topic Name 1",
      "Topic Name 2",
      "Topic Name 3"
    ]
  },
  {
    "chapter_name": "Chapter 2: Title or Lesson Name",
    "topics": [
      "Topic Name A",
      "Topic Name B"
    ]
  }
]

Do NOT include any markdown code blocks, backticks, or prefix text. Return only valid JSON.`;

  const text = await runWithRotation('SyllabusParsing', async (provider) => {
    if (provider === 'gemini' || provider === 'gemini2') {
      const client = provider === 'gemini' ? ai : ai2;
      const response = await client.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: prompt,
      });
      return response.text;
    }
    const config = PROVIDER_CONFIGS[provider];
    const messages = [{ role: 'user', content: prompt }];
    return await makeOpenAICall(config.url, config.getHeaders(), { model: config.model, messages });
  });

  try {
    let jsonString = text.trim();
    if (jsonString.startsWith('```json')) {
      jsonString = jsonString.substring(7, jsonString.length - 3);
    } else if (jsonString.startsWith('```')) {
      jsonString = jsonString.substring(3, jsonString.length - 3);
    }
    return JSON.parse(jsonString.trim());
  } catch (error) {
    console.error('Failed to parse syllabus parsing JSON. Raw:', text);
    return [
      {
        "chapter_name": "Imported Syllabus",
        "topics": ["General overview of lessons"]
      }
    ];
  }
}

/**
 * Parse a timetable PDF/TXT document into structured JSON schedule entries.
 * Returns an array of { day_of_week, subject, time_slot, teacher_name } objects.
 */
async function parseTimetable(timetableText) {
  if (!ai && !ai2) {
    return [
      { day_of_week: 'Monday', subject: 'Mathematics', time_slot: '09:00 AM - 10:00 AM', teacher_name: '' },
    ];
  }

  const prompt = `You are an expert school timetable analyst. Convert the following raw timetable text into a structured JSON array of schedule entries.

RAW TIMETABLE TEXT:
${timetableText}

You MUST return your evaluation strictly in the following JSON structure (an array of objects):
[
  {
    "day_of_week": "Monday",
    "subject": "Mathematics",
    "time_slot": "09:00 AM - 10:00 AM",
    "teacher_name": "Mr. Smith"
  },
  {
    "day_of_week": "Monday",
    "subject": "Physics",
    "time_slot": "10:00 AM - 11:00 AM",
    "teacher_name": ""
  }
]

Rules:
- day_of_week must be one of: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
- time_slot should be in "HH:MM AM/PM - HH:MM AM/PM" format or as written in the document
- teacher_name can be empty string "" if not mentioned
- subject should be the subject/course name
- If the same subject appears multiple days, create a separate entry for each day
- Do NOT include any markdown code blocks, backticks, or extra text. Return only valid JSON array.`;

  const text = await runWithRotation('TimetableParsing', async (provider) => {
    if (provider === 'gemini' || provider === 'gemini2') {
      const client = provider === 'gemini' ? ai : ai2;
      const response = await client.models.generateContent({
        model: 'gemini-2.0-flash',
        contents: prompt,
      });
      return response.text;
    }
    const config = PROVIDER_CONFIGS[provider];
    const messages = [{ role: 'user', content: prompt }];
    return await makeOpenAICall(config.url, config.getHeaders(), { model: config.model, messages });
  });

  try {
    let jsonString = text.trim();
    if (jsonString.startsWith('```json')) {
      jsonString = jsonString.substring(7, jsonString.length - 3);
    } else if (jsonString.startsWith('```')) {
      jsonString = jsonString.substring(3, jsonString.length - 3);
    }
    return JSON.parse(jsonString.trim());
  } catch (error) {
    console.error('Failed to parse timetable JSON. Raw:', text);
    return [
      { day_of_week: 'Monday', subject: 'General Timetable', time_slot: 'See attached schedule', teacher_name: '' },
    ];
  }
}

