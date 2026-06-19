const path = require('path');
// Load dotenv referencing the correct backend .env file path
require('dotenv').config({ path: path.join(__dirname, '.env') });
const { GoogleGenAI } = require('@google/genai');

async function testGemini(name, key) {
  if (!key) {
    console.log(`[${name}] NOT CONFIGURED`);
    return { name, status: 'NOT CONFIGURED' };
  }
  try {
    const ai = new GoogleGenAI({ apiKey: key });
    const res = await ai.models.generateContent({
      model: 'gemini-2.0-flash',
      contents: 'Hello',
    });
    console.log(`[${name}] WORKING. Response: ${res.text.trim().substring(0, 50)}...`);
    return { name, status: 'WORKING', details: 'Successful generation' };
  } catch (error) {
    const msg = error.message || String(error);
    if (msg.includes('Quota exceeded') || msg.includes('429') || msg.includes('RESOURCE_EXHAUSTED')) {
      console.log(`[${name}] VALID BUT EXHAUSTED (Rate Limit / Quota Exceeded)`);
      return { name, status: 'VALID BUT QUOTA EXHAUSTED', details: msg };
    } else {
      console.log(`[${name}] NOT WORKING. Error: ${msg}`);
      return { name, status: 'NOT WORKING', details: msg };
    }
  }
}

async function testOpenAICompatible(name, key, url, model, extraHeaders = {}) {
  if (!key) {
    console.log(`[${name}] NOT CONFIGURED`);
    return { name, status: 'NOT CONFIGURED' };
  }
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${key}`,
        ...extraHeaders
      },
      body: JSON.stringify({
        model: model,
        messages: [{ role: 'user', content: 'Hello' }],
        max_tokens: 10
      })
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`HTTP ${res.status}: ${text}`);
    }

    const data = await res.json();
    const reply = data.choices?.[0]?.message?.content || JSON.stringify(data);
    console.log(`[${name}] WORKING. Response: ${reply.trim().substring(0, 50)}...`);
    return { name, status: 'WORKING', details: 'Successful response' };
  } catch (error) {
    const msg = error.message || String(error);
    console.log(`[${name}] NOT WORKING. Error: ${msg}`);
    return { name, status: 'NOT WORKING', details: msg };
  }
}

async function testCloudflare(key) {
  if (!key) {
    console.log(`[Cloudflare] NOT CONFIGURED`);
    return { name: 'Cloudflare', status: 'NOT CONFIGURED' };
  }
  try {
    const res = await fetch('https://api.cloudflare.com/client/v4/user/tokens/verify', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${key}`,
        'Content-Type': 'application/json'
      }
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`HTTP ${res.status}: ${text}`);
    }

    const data = await res.json();
    if (data.success && data.result?.status === 'active') {
      console.log(`[Cloudflare] WORKING. Token Status: Active`);
      return { name: 'Cloudflare', status: 'WORKING', details: 'Token status is active' };
    } else {
      throw new Error(JSON.stringify(data));
    }
  } catch (error) {
    const msg = error.message || String(error);
    console.log(`[Cloudflare] NOT WORKING. Error: ${msg}`);
    return { name: 'Cloudflare', status: 'NOT WORKING', details: msg };
  }
}

async function runAll() {
  console.log('=== STARTING API VALIDATION ===\n');
  const results = [];

  results.push(await testGemini('Gemini 1', process.env.GEMINI_API_KEY));
  results.push(await testGemini('Gemini 2', process.env.GEMINI_API_KEY_2));
  
  results.push(await testOpenAICompatible(
    'Groq',
    process.env.GROQ_API_KEY,
    'https://api.groq.com/openai/v1/chat/completions',
    'llama-3.3-70b-versatile'
  ));

  results.push(await testOpenAICompatible(
    'OpenRouter',
    process.env.OPENROUTER_API_KEY,
    'https://openrouter.ai/api/v1/chat/completions',
    'meta-llama/llama-3-8b-instruct'
  ));

  results.push(await testOpenAICompatible(
    'Nvidia',
    process.env.NVIDIA_API_KEY,
    'https://integrate.api.nvidia.com/v1/chat/completions',
    'nvidia/nemotron-3-ultra-550b-a55b'
  ));

  results.push(await testOpenAICompatible(
    'AI Native',
    process.env.AI_NATIVE_API_KEY,
    'https://api.ainative.studio/v1/chat/completions',
    'gpt-3.5-turbo',
    { 'X-API-Key': process.env.AI_NATIVE_API_KEY }
  ));

  results.push(await testOpenAICompatible(
    'Hugging Face',
    process.env.HF_TOKEN,
    'https://router.huggingface.co/v1/chat/completions',
    'meta-llama/Meta-Llama-3-8B-Instruct'
  ));

  results.push(await testCloudflare(process.env.CLOUDFLARE_API_TOKEN));

  console.log('\n=== SUMMARY OF RESULTS ===');
  console.table(results);
}

runAll();
