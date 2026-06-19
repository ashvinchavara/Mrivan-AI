const { GoogleGenAI } = require('@google/genai');
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;
const ai = apiKey ? new GoogleGenAI({ apiKey }) : null;

/**
 * 1. AI subject-specific Tutor Chat
 */
const getTutorChatResponse = async (history, message, subject = 'General', grade = '10') => {
  if (!ai) return "Tutor Mode (Demo): Gemini API key is missing. Add GEMINI_API_KEY to .env to enable the AI tutor.";

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

  // Map history to Gemini's format: { role: 'user'|'model', parts: [{ text: '...' }] }
  const formattedHistory = history.map(h => ({
    role: h.sender === 'user' ? 'user' : 'model',
    parts: [{ text: h.content }]
  }));

  try {
    const response = await ai.models.generateContent({
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
      model: 'gemini-2.0-flash',
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
      model: 'gemini-2.0-flash',
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
      model: 'gemini-2.0-flash',
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
