import express from "express";
import path from "path";
import cors from "cors";
import dotenv from "dotenv";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI } from "@google/genai";
import { MRIVAN_FILES } from "./src/codebase_data.ts";

dotenv.config();

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// Lazy-initialized Gemini client
let aiClient: GoogleGenAI | null = null;

function getGeminiClient(): GoogleGenAI {
  if (!aiClient) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error("GEMINI_API_KEY is not defined in user secrets or environment.");
    }
    aiClient = new GoogleGenAI({
      apiKey,
      httpOptions: {
        headers: {
          "User-Agent": "aistudio-build",
        },
      },
    });
  }
  return aiClient;
}

// 1. Get Codebase Files
app.get("/api/codebase/files", (req, res) => {
  try {
    res.json({ success: true, files: MRIVAN_FILES });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// 2. Code Analysis / QA Chat via server-side Gemini
app.post("/api/codebase/analyze", async (req, res) => {
  try {
    const { filePath, userInstruction, chatHistory = [] } = req.body;
    const client = getGeminiClient();

    const selectedFile = MRIVAN_FILES.find((f) => f.path === filePath);
    const codeSnippet = selectedFile
      ? `\n\n--- File: ${selectedFile.path} (${selectedFile.language}) ---\n${selectedFile.content}\n`
      : "";

    // Build standard chat-styled prompt context
    const conversation = chatHistory.map((msg: any) => `${msg.role === "user" ? "User" : "Advisor"}: ${msg.content}`).join("\n");
    
    const prompt = `You are Mr. Ivan AI Strategic Advisor, reviewing the Mrivan-AI Repo codebase.
We have selected this focus file: ${filePath || "Entire Codebase Overview"}
${codeSnippet}

Client instruction or question:
${userInstruction}

Previous conversation history:
${conversation}

Please provide your analytical analysis. Format with Markdown. Keep it direct, highlighting actionable recommendations, code improvements, security vulnerabilities (like hardcoded keys), and design modernization principles.`;

    const response = await client.models.generateContent({
      model: "gemini-3.5-flash",
      contents: prompt,
      config: {
        systemInstruction: "You are Mr. Ivan AI Strategic Advisor, an expert full-stack developer and security auditor. Avoid praise; write high-value code reviews with constructive refactoring options.",
      },
    });

    res.json({ success: true, content: response.text });
  } catch (err: any) {
    console.error("Gemini server analaysis failed:", err);
    res.status(500).json({ success: false, error: err.message || "Failed to generate report" });
  }
});

// 3. Mount Vite middleware in development, or serve built bundle in production
async function startServer() {
  if (process.env.NODE_ENV !== "production") {
    console.log("Loading Vite dev server middleware...");
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    console.log("Production environment detected. Serving static production build...");
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server is running at http://localhost:${PORT}`);
  });
}

startServer();
