# Mrivan AI - Backend API Server

This is the Node.js + Express backend server for **Mrivan AI (School CRM & AI Tutor Platform)**. It connects to your PostgreSQL database hosted on Supabase and integrates Google Gemini API for pedagogical tutoring.

---

## 🚀 Quick Start (Local Setup)

### 1. Database Setup (Supabase)
1. Go to your **Supabase Dashboard** and open the **SQL Editor**.
2. Copy the contents of [supabase_schema.sql](./supabase_schema.sql).
3. Paste the script and click **Run** to generate the required CRM & AI tables, relationships, and scale-optimized indexes.

### 2. Environment Configuration
1. Create a `.env` file in the root of the `mrivan_backend` folder:
   ```bash
   cp .env.example .env
   ```
2. Populate the variables inside `.env`:
   - **`SUPABASE_URL`**: Your Supabase project API URL (e.g. `https://xxx.supabase.co`).
   - **`SUPABASE_ANON_KEY`**: Your project API anon key.
   - **`SUPABASE_SERVICE_ROLE_KEY`**: Bypasses Row Level Security (RLS) on server-side queries.
   - **`GEMINI_API_KEY`**: Get a key from [Google AI Studio](https://aistudio.google.com/).
   - **`AI_NATIVE_API_KEY`**: Get a key from AINative Studio (for advanced agent memory, zeroDB, or tools).
   - **`GROQ_API_KEY`**: Get a key from the Groq Console (for high-speed inference/LPU support).
   - **`OPENROUTER_API_KEY`**: Get a key from the OpenRouter Dashboard (for access to 100+ open-source and proprietary LLMs).

### 3. Install Dependencies & Run
```bash
# Install NPM packages
npm install

# Start the server in Development mode (with auto-reload)
npm run dev

# Start the server in Production mode
npm start
```
The server will boot up at **`http://localhost:3000`**.

---

## 🛠️ API Reference Documentation

All endpoints (except the home verification route) require authentication. Pass the Supabase JWT token in the request headers:
`Authorization: Bearer <your_supabase_jwt_token>`

### 1. Authentication
*   **`POST /api/auth/sync`**: Synchronizes a logged-in Supabase user with our custom public `profiles` table. Handles names and user roles.

### 2. CRM Operations
*   **`POST /api/crm/schools`**: (Admin only) Creates a school tenant.
*   **`POST /api/crm/classes`**: (Admin only) Creates a classroom section.
*   **`GET /api/crm/classes`**: (Admin/Teacher) Lists all classrooms.
*   **`GET /api/crm/students`**: (Admin/Teacher) Lists students (filter by `classId` query parameters).
*   **`POST /api/crm/attendance`**: (Teacher only) Records daily attendance for students in bulk.
*   **`GET /api/crm/attendance`**: (All Roles) Retrieves attendance logs. Automatically applies tenant checks (students only see theirs, parents see their children's logs, teachers see class logs).
*   **`POST /api/crm/homework`**: (Teacher only) Assigns homework to a classroom.
*   **`POST /api/crm/homework/submit`**: (Student only) Submits text/file links for homework assignments.

### 3. AI Learning Tools (Gemini SDK)
*   **`POST /api/ai/tutor/chat`**: Handles conversation with **Mr. Ivan AI** (empathetic step-by-step tutoring prompt). Persists chat history dynamically in the database so chat history is synchronized across devices.
*   **`POST /api/ai/notes`**: Generates and saves clean markdown study guides on a specific topic.
*   **`POST /api/ai/quiz`**: Generates structured multiple-choice questions (JSON format).
*   **`POST /api/ai/voice`**: Short, conversational concepts for text-to-speech reading.

### 4. CBT Mock Tests
*   **`POST /api/tests`**: (Admin/Teacher) Creates a multiple choice mock test.
*   **`GET /api/tests`**: Lists available tests.
*   **`GET /api/tests/:id`**: Gets test questions.
*   **`POST /api/tests/:id/attempt`**: Submits a student's answer sheet, auto-grades the answers, and logs their score history.

---

## ☁️ Render Deployment Guide

1. Create a free account on [Render](https://render.com/).
2. Click **New > Web Service**.
3. Connect your GitHub repository (`ashvinchavara/Mrivan-AI`).
4. Set the following settings:
   - **Root Directory**: `mrivan_backend`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
5. Go to the **Environment** tab on Render and add your variables:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `GEMINI_API_KEY`
   - `AI_NATIVE_API_KEY`
   - `GROQ_API_KEY`
   - `OPENROUTER_API_KEY`
6. Click **Deploy Web Service**. Render will build and host your API securely!
