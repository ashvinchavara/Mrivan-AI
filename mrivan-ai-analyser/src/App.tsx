import React, { useState, useEffect } from "react";
import {
  FileText,
  ShieldAlert,
  Zap,
  Layers,
  ArrowRight,
  ExternalLink,
  MessageSquare,
  Sparkles,
  RefreshCw,
  FolderOpen,
  Eye,
  CheckCircle,
  HelpCircle,
  Lock,
  Flame,
  Lightbulb,
  Code2,
  Terminal,
  RotateCcw
} from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { MRIVAN_FILES, CodeFile } from "./codebase_data.ts";

export default function App() {
  const [files, setFiles] = useState<CodeFile[]>(MRIVAN_FILES);
  const [selectedFile, setSelectedFile] = useState<CodeFile>(MRIVAN_FILES[0]);
  const [customPrompt, setCustomPrompt] = useState("");
  const [chatHistory, setChatHistory] = useState<Array<{ role: "user" | "advisor"; content: string }>>([
    {
      role: "advisor",
      content: "Welcome! I have compiled an active audit of **Mrivan-AI**. I detected several critical action items, including **exposed Supabase database JWT credentials** in your client-side Flutter code and a **deprecated SDK layer** in your Express backend.\n\nSelect any file on the left to review its source code directly, or click one of the **Strategic Action Card prompts** to start refactoring immediately."
    }
  ]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [scannedIssues, setScannedIssues] = useState<number>(0);
  const [isScanning, setIsScanning] = useState(false);
  const [hasScanned, setHasScanned] = useState(true);
  const [activeTab, setActiveTab] = useState<"code" | "overview">("code");

  // Project health and security gauges
  const [healthScore, setHealthScore] = useState(72);
  const [securityScore, setSecurityScore] = useState(45);
  const [apiCoverage, setApiCoverage] = useState(88);

  // Strategic presets
  const recommendations = [
    {
      id: "sec-01",
      title: "Supabase Key Leak Remediation",
      badge: "CRITICAL SECURITY",
      badgeColor: "bg-rose-500/10 text-rose-400 border-rose-500/20",
      file: "mrivan_ai/lib/main.dart",
      description: "Replace the hardcoded Anon Database credentials inside Lib Dart client with runtime dotenv loaders or secure proxy handshakes.",
      prompt: "Can you provide a secure refactored version of the Supabase.initialize code in Flutter main.dart, and explain how to use secrets variables or secure reverse proxy layers so the Anon JWT token is not hardcoded?"
    },
    {
      id: "sdk-02",
      title: "Gemini SDK Modernization",
      badge: "DEPRECATION CHECK",
      badgeColor: "bg-amber-500/10 text-amber-400 border-amber-500/20",
      file: "mrivan_backend/src/services/gemini.service.js",
      description: "Upgrade from the legacy `@google/generative-ai` architecture to the modern server-optimized `@google/genai` TypeScript SDK.",
      prompt: "Show me how to refactor gemini.service.js inside the express backend to use the brand new @google/genai SDK, implementing a secure client instanced via new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY }) as recommended by Google AI Studio."
    },
    {
      id: "mem-03",
      title: "CRM Session & Cache Layer",
      badge: "PERFORMANCE",
      badgeColor: "bg-indigo-500/10 text-indigo-400 border-indigo-500/20",
      file: "mrivan_backend/src/controllers/ai.controller.js",
      description: "Introduce a lightweight Redis or standard middleware memory cache for session historical items to reduce database read overhead.",
      prompt: "How can I implement a small memory caching mechanism (like node-cache or quick redis lookup) for getTutorChat inside ai.controller.js so that we don't query Supabase databases on every single keystroke conversation stream?"
    }
  ];

  // Load codebase files with any dynamic updates
  useEffect(() => {
    fetch("/api/codebase/files")
      .then((res) => res.json())
      .then((data) => {
        if (data.success && data.files) {
          setFiles(data.files);
        }
      })
      .catch((err) => console.error("Error loaded files from backend api:", err));
  }, []);

  const handleApplyPreset = (rec: typeof recommendations[0]) => {
    // Switch active view state
    setActiveTab("code");
    const targetFile = files.find((f) => f.path === rec.file);
    if (targetFile) {
      setSelectedFile(targetFile);
    }
    
    // Auto populate message & trigger simulation
    triggerAiAnalysis(rec.prompt, rec.file);
  };

  const triggerAiAnalysis = async (instruction: string, filePath?: string) => {
    if (!instruction.trim()) return;
    setIsGenerating(true);

    const newUserMessage = { role: "user" as const, content: instruction };
    setChatHistory((prev) => [...prev, newUserMessage]);
    setCustomPrompt("");

    try {
      const response = await fetch("/api/codebase/analyze", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          filePath: filePath || selectedFile.path,
          userInstruction: instruction,
          chatHistory: chatHistory.slice(-6) // Send short context for token efficiency
        })
      });

      const data = await response.json();
      if (data.success && data.content) {
        setChatHistory((prev) => [
          ...prev,
          { role: "advisor", content: data.content }
        ]);
        // Positively increase scores as the user interacts and explores refactors
        setHealthScore(Math.min(94, healthScore + 4));
        setSecurityScore(Math.min(92, securityScore + 8));
      } else {
        setChatHistory((prev) => [
          ...prev,
          { role: "advisor", content: `**Error:** Unable to complete simulation scan: ${data.error || "Unknown server response error."}` }
        ]);
      }
    } catch (err: any) {
      setChatHistory((prev) => [
        ...prev,
        { role: "advisor", content: `**Audit Connection Failed:** This applet's Express backend could not establish a connection to GenAI. Ensure process.env.GEMINI_API_KEY is configured correctly. \n\nError: ${err.message}` }
      ]);
    } finally {
      setIsGenerating(false);
    }
  };

  const resetSimulation = () => {
    setChatHistory([
      {
        role: "advisor",
        content: "Resetting code analyzer session. Explore different file segments on the left, check the Flutter credentials security audit, or prompt me for targeted refactor tasks!"
      }
    ]);
    setHealthScore(72);
    setSecurityScore(45);
  };

  return (
    <div className="min-h-screen bg-[#090d16] text-slate-100 font-sans flex flex-col antialiased">
      
      {/* Top Header Section */}
      <nav className="h-20 bg-[#111827]/90 backdrop-blur-md border-b border-white/5 flex items-center justify-between px-6 md:px-8 shrink-0 z-10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-tr from-indigo-500 via-purple-500 to-rose-500 rounded-xl flex items-center justify-center shadow-lg shadow-indigo-600/30">
            <span className="text-white font-bold text-lg font-display">M</span>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl md:text-2xl font-bold tracking-tight bg-clip-text text-transparent bg-gradient-to-r from-white via-slate-200 to-slate-400 font-display">
                MRIVAN AI
              </h1>
              <span className="text-[9px] font-mono text-indigo-400 bg-indigo-500/10 border border-indigo-500/20 px-2 py-0.5 rounded-md uppercase tracking-wider font-bold">
                Strategic Auditor
              </span>
            </div>
            <p className="text-[10px] text-slate-400">High-Fidelity Codebase Exploration & Mitigation Engine</p>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="hidden lg:flex items-center gap-3 pr-4 border-r border-white/5">
            <div className="flex items-center gap-1.5 bg-rose-500/10 border border-rose-500/20 px-2.5 py-1 rounded-full text-xs text-rose-400 font-mono">
              <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse"></span>
              LEAK DETECTED (main.dart)
            </div>
          </div>
          
          <button
            onClick={resetSimulation}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-slate-300 hover:text-white bg-white/5 hover:bg-white/10 border border-white/10 rounded-lg transition-all"
            id="btn-reset"
          >
            <RotateCcw className="w-3 h-3" />
            Reset Audit
          </button>
        </div>
      </nav>

      {/* Main Grid Division Layout */}
      <div className="flex-1 flex flex-col lg:flex-row overflow-hidden">
        
        {/* Left Side: Directory Structure / File List */}
        <aside className="w-full lg:w-80 bg-[#0c1220] border-b lg:border-b-0 lg:border-r border-white/5 p-4 md:p-5 flex flex-col gap-6 shrink-0 overflow-y-auto">
          <div>
            <div className="flex items-center justify-between mb-3">
              <p className="text-[10px] uppercase tracking-[0.25em] text-slate-400 font-bold">REPOS STRUCTURE</p>
              <span className="text-[10px] font-mono text-emerald-400 font-semibold flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping"></span>
                8 Files Synced
              </span>
            </div>
            
            <div className="space-y-1">
              <div className="text-[11px] font-mono text-slate-500 px-2 py-1 select-none flex items-center gap-1.5">
                <FolderOpen className="w-3.5 h-3.5 text-indigo-400" />
                ashvinchavara/Mrivan-AI
              </div>
              
              {files.map((file) => {
                const isSelected = selectedFile.path === file.path;
                return (
                  <button
                    key={file.path}
                    onClick={() => {
                      setSelectedFile(file);
                      setActiveTab("code");
                    }}
                    className={`w-full text-left px-3 py-2 rounded-xl text-xs transition-all flex items-center justify-between border ${
                      isSelected
                        ? "bg-indigo-600/10 border-indigo-500/30 text-indigo-300 font-medium"
                        : "bg-transparent border-transparent text-slate-400 hover:bg-white/5 hover:text-white"
                    }`}
                  >
                    <div className="flex items-center gap-2.5 truncate">
                      <div className={`p-1 rounded-md ${isSelected ? "text-indigo-400" : "text-slate-500"}`}>
                        <FileText className="w-3.5 h-3.5" />
                      </div>
                      <span className="truncate font-mono text-[11px]">{file.path}</span>
                    </div>
                    {file.path.endsWith("main.dart") && (
                      <span className="w-2 h-2 rounded-full bg-rose-500 shadow-[0_0_8px_rgba(239,68,68,0.8)] animate-pulse" title="Security Risk Detected" />
                    )}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Project Health Radar */}
          <div className="mt-auto pt-4 border-t border-white/5">
            <div className="bg-[#111827] rounded-2xl border border-white/5 p-4 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-indigo-500/10 to-transparent blur-2xl" />
              <p className="text-[10px] font-bold text-indigo-400 uppercase tracking-widest font-mono mb-3">Project Health Score</p>
              
              <div className="space-y-3">
                {/* Health Rating progress item */}
                <div>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-slate-400">Security Index</span>
                    <span className={`font-mono font-bold ${securityScore < 50 ? "text-rose-400" : "text-emerald-400"}`}>
                      {securityScore}%
                    </span>
                  </div>
                  <div className="w-full bg-white/5 h-1.5 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all duration-1000 ${
                        securityScore < 50 ? "bg-rose-500" : "bg-emerald-500"
                      }`}
                      style={{ width: `${securityScore}%` }}
                    />
                  </div>
                </div>

                {/* API and SDK Coverage progress item */}
                <div>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-slate-400">V2.0 Core Standards</span>
                    <span className="font-mono font-bold text-indigo-300">{healthScore}%</span>
                  </div>
                  <div className="w-full bg-white/5 h-1.5 rounded-full overflow-hidden">
                    <div
                      className="bg-gradient-to-r from-indigo-500 to-rose-400 h-full rounded-full transition-all duration-1000"
                      style={{ width: `${healthScore}%` }}
                    />
                  </div>
                </div>
              </div>

              <div className="mt-4 flex items-center gap-2 text-[10px] text-slate-500 font-mono">
                <CheckCircle className="w-3 h-3 text-emerald-400 shrink-0" />
                Updated with latest analysis algorithms
              </div>
            </div>
          </div>
        </aside>

        {/* Center Canvas Area: Active Code Reviewer & Presets */}
        <main className="flex-1 bg-[#020617] p-4 md:p-6 flex flex-col gap-6 overflow-y-auto">
          
          {/* Tabs header controller */}
          <div className="flex items-center justify-between border-b border-white/5 pb-3">
            <div className="flex gap-2">
              <button
                onClick={() => setActiveTab("code")}
                className={`px-4 py-1.5 rounded-full text-xs font-medium transition-all ${
                  activeTab === "code"
                    ? "bg-white/10 text-white shadow-md"
                    : "text-slate-400 hover:text-white"
                }`}
              >
                Code Viewport
              </button>
              <button
                onClick={() => setActiveTab("overview")}
                className={`px-4 py-1.5 rounded-full text-xs font-medium transition-all ${
                  activeTab === "overview"
                    ? "bg-white/10 text-white shadow-md"
                    : "text-slate-400 hover:text-white"
                }`}
              >
                Executive Summary
              </button>
            </div>

            <div className="text-[11px] text-slate-400 font-mono">
              Focussed: <span className="text-indigo-400 font-bold">{selectedFile.path}</span>
            </div>
          </div>

          <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-stretch flex-1">
            
            {/* Viewport/Description Canvas column (8/12) */}
            <div className="xl:col-span-7 flex flex-col gap-6">
              
              {activeTab === "code" ? (
                /* Dynamic IDE-styled Terminal screen */
                <div className="bg-[#0b0f19] rounded-2xl border border-white/5 flex-1 flex flex-col overflow-hidden shadow-2xl min-h-[480px]">
                  {/* File terminal layout header */}
                  <div className="bg-[#111827] px-4 py-3 border-b border-white/5 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="w-3 h-3 rounded-full bg-rose-500/80"></span>
                      <span className="w-3 h-3 rounded-full bg-amber-500/80"></span>
                      <span className="w-3 h-3 rounded-full bg-emerald-500/80"></span>
                      <p className="text-[11px] font-mono text-slate-400 ml-2 select-none uppercase tracking-wide">
                        {selectedFile.language} viewer
                      </p>
                    </div>
                    <span className="text-[10px] font-mono text-slate-500">PROPOSED_SANDBOX.IDE</span>
                  </div>

                  {/* Specific Code Alerts (e.g. key credentials warning) */}
                  {selectedFile.path.endsWith("main.dart") && (
                    <div className="bg-rose-950/20 border-b border-rose-500/20 px-4 py-3 flex items-start gap-3">
                      <ShieldAlert className="w-5 h-5 text-rose-400 shrink-0 mt-0.5" />
                      <div>
                        <p className="text-xs font-bold text-rose-400">Vulnerabilities Detected: Exposed Anon Database Key</p>
                        <p className="text-[11px] text-rose-300/80 leading-relaxed max-w-xl">
                          Line 12 exposes the raw Supabase public API anonymous token and URL endpoint. Any malicious agent decompiling this Flutter binary can fetch, view, or write to CRM schema records.
                        </p>
                        <button
                          onClick={() => triggerAiAnalysis("Show me the best security-mitigation scheme to remove the raw Supabase API token in Dart main.dart using client abstractions.", "mrivan_ai/lib/main.dart")}
                          className="mt-2 text-[10px] font-bold text-rose-300 hover:text-white underline flex items-center gap-1"
                        >
                          Synthesize secure patch with Gemini <Sparkles className="w-3 h-3 animate-pulse" />
                        </button>
                      </div>
                    </div>
                  )}

                  {selectedFile.path.includes("gemini.service.js") && (
                    <div className="bg-amber-950/20 border-b border-amber-500/20 px-4 py-3 flex items-start gap-3">
                      <ShieldAlert className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
                      <div>
                        <p className="text-xs font-bold text-amber-400">Optimization Opportunity: Outdated GenAI library</p>
                        <p className="text-[11px] text-amber-300/80 leading-relaxed max-w-xl">
                          The module leverages legacy <code className="bg-slate-900 px-1 py-0.5 rounded text-amber-300">@google/generative-ai</code> imports, which are slow and do not conform to the modern <code className="bg-slate-900 px-1 py-0.5 rounded text-indigo-300">@google/genai</code> standards designed for stream pipelines and high-velocity reasoning.
                        </p>
                        <button
                          onClick={() => triggerAiAnalysis("Explain why migrating to @google/genai SDK is important, and render the complete replacement code for gemini.service.js using new GoogleGenAI class.", "mrivan_backend/src/services/gemini.service.js")}
                          className="mt-2 text-[10px] font-bold text-amber-300 hover:text-white underline flex items-center gap-1"
                        >
                          Generate modernized SDK upgrade guide <Sparkles className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  )}

                  {/* Main source viewport */}
                  <div className="flex-1 overflow-auto p-4 bg-[#020617]">
                    <pre className="text-[11px] font-mono leading-relaxed text-slate-300 overflow-x-auto select-text whitespace-pre">
                      <code>{selectedFile.content}</code>
                    </pre>
                  </div>
                </div>
              ) : (
                /* Executive summary & system characteristics */
                <div className="space-y-6">
                  {/* General overview card */}
                  <div className="bg-gradient-to-br from-[#111827] to-[#0c1220] rounded-3xl p-6 border border-white/5 relative overflow-hidden">
                    <div className="absolute -right-12 -bottom-12 w-48 h-48 bg-indigo-500/10 rounded-full blur-3xl" />
                    <div className="flex items-center gap-3 mb-3">
                      <Layers className="w-5 h-5 text-indigo-400" />
                      <h2 className="text-xl font-bold">Mrivan-AI Architecture Blueprint</h2>
                    </div>
                    <p className="text-slate-400 text-sm leading-relaxed mb-4">
                      The current system serves a complete, dual-engine suite combining a robust Flutter client-side screen wrapper with an Express MVC background connector.
                    </p>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
                      <div className="bg-white/5 p-4 rounded-2xl border border-white/5">
                        <h4 className="text-xs font-semibold text-slate-300 mb-1">Database Layer</h4>
                        <p className="text-[11px] text-slate-400 font-mono leading-normal">
                          Public tables hosted on Supabase (PostgreSQL). Dynamic auth-synced profile hooks mapping distinct customer user levels.
                        </p>
                      </div>
                      <div className="bg-white/5 p-4 rounded-2xl border border-white/5">
                        <h4 className="text-xs font-semibold text-slate-300 mb-1">AI Generative Engine</h4>
                        <p className="text-[11px] text-slate-400 font-mono leading-normal">
                          Uses the legacy Gemini generative-ai router. Provides tutoring dialog with conversational systems, markdown note generators, and structural quiz evaluators.
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Vulnerability metrics row */}
                  <div className="bg-rose-500/5 rounded-3xl p-6 border border-rose-500/10">
                    <div className="flex items-center gap-3 mb-4">
                      <ShieldAlert className="w-5 h-5 text-rose-400" />
                      <h3 className="text-base font-bold text-rose-300">Targeted Core Deficiencies Found</h3>
                    </div>

                    <div className="space-y-3">
                      <div className="flex items-start gap-2.5 text-xs">
                        <span className="text-rose-400 font-mono font-bold shrink-0 mt-0.5">[01]</span>
                        <div>
                          <strong className="text-slate-200">Exposed Supabase Session Token:</strong> Hardcoded JWT strings in Flutter dart can bypass traditional credentials controls if reverse-engineered or published to stores.
                        </div>
                      </div>
                      <div className="flex items-start gap-2.5 text-xs">
                        <span className="text-rose-400 font-mono font-bold shrink-0 mt-0.5">[02]</span>
                        <div>
                          <strong className="text-slate-200">Deprecated SDK Module:</strong> Using genai with deprecated models (<code className="bg-slate-900 px-1 py-0.5 rounded text-[10px] text-amber-300">gemini-1.5-flash</code>) instead of latest recommended models has performance caveats.
                        </div>
                      </div>
                      <div className="flex items-start gap-2.5 text-xs">
                        <span className="text-rose-400 font-mono font-bold shrink-0 mt-0.5">[03]</span>
                        <div>
                          <strong className="text-slate-200">No Caching Interlayer:</strong> Express tutor router issues backend database select hooks during streaming, risking scaling timeouts under elevated client density.
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Suggestions prescriptive module */}
              <div>
                <p className="text-[10px] uppercase tracking-[0.2em] text-slate-500 mb-4 font-bold">PROPOSED VIBRANT ACTION ITEMS</p>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {recommendations.map((rec) => (
                    <div
                      key={rec.id}
                      onClick={() => handleApplyPreset(rec)}
                      className="group bg-gradient-to-br from-[#111827] to-[#0c1220] rounded-2xl p-4 border border-white/5 hover:border-indigo-500/20 cursor-pointer transition-all hover:shadow-xl relative overflow-hidden flex flex-col justify-between"
                    >
                      <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-bl from-indigo-500/5 to-transparent blur-xl group-hover:scale-150 transition-transform" />
                      <div>
                        <span className={`inline-block text-[8px] font-mono px-2 py-0.5 rounded-md border font-extrabold tracking-wider uppercase mb-3 ${rec.badgeColor}`}>
                          {rec.badge}
                        </span>
                        <h4 className="text-xs font-bold text-slate-200 group-hover:text-indigo-300 transition-colors mb-1.5 flex items-center gap-1">
                          {rec.title}
                          <ArrowRight className="w-3 h-3 opacity-0 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
                        </h4>
                        <p className="text-[10px] text-slate-400 leading-relaxed mb-3">
                          {rec.description}
                        </p>
                      </div>
                      <span className="text-[9px] font-mono text-slate-500 block truncate mt-auto">
                        File: {rec.file.split("/").pop()}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

            </div>

            {/* Strategic Advisor Panel: Gemini Q&A and Chat history column (5/12) */}
            <div className="xl:col-span-5 flex flex-col gap-6">
              
              <div className="bg-[#0b0f19] rounded-3xl border border-white/10 flex-grow flex flex-col overflow-hidden shadow-2xl relative">
                {/* Panel head visual identifier */}
                <div className="p-4 bg-gradient-to-r from-indigo-900/40 via-purple-900/20 to-transparent border-b border-white/5 flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className="p-2 bg-indigo-500/10 rounded-xl border border-indigo-500/20 text-indigo-400">
                      <Sparkles className="w-4 h-4 animate-pulse" />
                    </div>
                    <div>
                      <h3 className="text-sm font-bold text-white tracking-tight">AI Strategic Advisor</h3>
                      <p className="text-[9px] text-slate-400 font-mono">MODEL: GEMINI-3.5-FLASH</p>
                    </div>
                  </div>

                  {isGenerating && (
                    <div className="flex items-center gap-1.5 text-[9px] text-indigo-400 bg-indigo-500/10 px-2.5 py-1 rounded-full border border-indigo-500/20 font-mono font-bold animate-pulse">
                      <span className="w-1 h-1 rounded-full bg-indigo-400"></span>
                      GENERATING ANSWER
                    </div>
                  )}
                </div>

                {/* Chat Message Stream */}
                <div className="flex-1 p-4 overflow-y-auto space-y-4 text-xs leading-relaxed max-h-[500px]">
                  {chatHistory.map((msg, i) => {
                    const isAdvisor = msg.role === "advisor";
                    return (
                      <div
                        key={i}
                        className={`flex gap-3 ${isAdvisor ? "justify-start" : "justify-end flex-row-reverse"}`}
                      >
                        {/* Round profile markers */}
                        <div
                          className={`w-7 h-7 rounded-full shrink-0 flex items-center justify-center text-[10px] font-mono font-extrabold ${
                            isAdvisor
                              ? "bg-indigo-600/10 border border-indigo-500/20 text-indigo-300"
                              : "bg-gradient-to-tr from-indigo-500 to-rose-500 text-white"
                          }`}
                        >
                          {isAdvisor ? "Ad" : "Us"}
                        </div>

                        <div
                          className={`p-3.5 rounded-2xl max-w-[85%] border ${
                            isAdvisor
                              ? "bg-[#111827] border-white/5 text-slate-300 rounded-tl-none whitespace-pre-line"
                              : "bg-[#1e1b4b] border-indigo-500/30 text-white rounded-tr-none"
                          }`}
                        >
                          {/* Formatting helper to render simple bold formatting and code tags easily */}
                          {msg.content.split("\n").map((paragraph, pIdx) => {
                            // Basic markdown inline parser substitute for robust visualization compatibility
                            let line = paragraph;
                            
                            // Check if line contains double asterisks for bolding
                            const boldRegex = /\*\*(.*?)\*\*/g;
                            const matches = [...line.matchAll(boldRegex)];
                            
                            if (matches.length > 0) {
                              const segments = [];
                              let lastIdx = 0;
                              matches.forEach((m) => {
                                const start = m.index!;
                                if (start > lastIdx) {
                                  segments.push(line.substring(lastIdx, start));
                                }
                                segments.push(
                                  <strong key={start} className="text-white font-bold">
                                    {m[1]}
                                  </strong>
                                );
                                lastIdx = start + m[0].length;
                              });
                              if (lastIdx < line.length) {
                                segments.push(line.substring(lastIdx));
                              }
                              return (
                                <p key={pIdx} className="mb-2 last:mb-0 leading-relaxed text-slate-300 text-[11px] font-sans">
                                  {segments}
                                </p>
                              );
                            }

                            // Render code markers formatting
                            if (line.startsWith("```")) {
                              return null; // Skip code fence borders to prevent terminal clutter
                            }

                            return (
                              <p key={pIdx} className="mb-2 last:mb-0 leading-relaxed text-slate-300 text-[11px] font-sans">
                                {line}
                              </p>
                            );
                          })}
                        </div>
                      </div>
                    );
                  })}
                  {isGenerating && (
                    <div className="flex gap-3 justify-start">
                      <div className="w-7 h-7 rounded-full shrink-0 flex items-center justify-center text-[10px] bg-indigo-600/10 border border-indigo-500/20 text-indigo-300 animate-pulse">
                        Ad
                      </div>
                      <div className="bg-[#111827] border border-white/5 p-4 rounded-2xl rounded-tl-none text-slate-400 italic">
                        Formulating codebase upgrade instructions, reviewing repository architecture...
                      </div>
                    </div>
                  )}
                </div>

                {/* Chat Control input pane - Form control */}
                <div className="p-3 bg-slate-950 border-t border-white/5 flex items-center gap-2 gap-y-0 relative">
                  <input
                    type="text"
                    value={customPrompt}
                    onChange={(e) => setCustomPrompt(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" && !isGenerating) triggerAiAnalysis(customPrompt);
                    }}
                    placeholder={`Ask advisor about ${selectedFile.path.split("/").pop()}...`}
                    className="flex-grow bg-[#0c1220] border border-white/5 rounded-xl px-3.5 py-2.5 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500/50 focus:ring-1 focus:ring-indigo-500/20 transition-all font-mono"
                    disabled={isGenerating}
                  />
                  <button
                    onClick={() => triggerAiAnalysis(customPrompt)}
                    disabled={isGenerating || !customPrompt.trim()}
                    className="p-2.5 bg-indigo-600 hover:bg-indigo-500 disabled:bg-slate-800 disabled:text-slate-500 text-white rounded-xl transition-all shadow-lg"
                  >
                    <Sparkles className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Bottom Strategic Summary check */}
              <div className="px-4 py-3 bg-[#111827] rounded-24 shadow-sm border border-white/5 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-2.5 h-2.5 rounded-full bg-indigo-500 animate-pulse"></div>
                  <span className="text-xs font-semibold text-slate-300">Target Frameworks: Dart, Node, Supabase</span>
                </div>
                <span className="text-[10px] font-mono text-slate-500">ID: 808-STRATEGIC-MRV</span>
              </div>

            </div>

          </div>
        </main>
      </div>
    </div>
  );
}
