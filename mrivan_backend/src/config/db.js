const { createClient } = require('@supabase/supabase-js');
const { AsyncLocalStorage } = require('async_hooks');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('CRITICAL ERROR: SUPABASE_URL or SUPABASE_ANON_KEY is missing from environment variables.');
  process.exit(1);
}

// 1. Standard public client (uses Anon Key, subject to Row Level Security)
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// 2. Administrative client (uses Service Role Key, bypasses Row Level Security)
const rawSupabaseAdmin = supabaseServiceRoleKey 
  ? createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })
  : null;

// AsyncLocalStorage to hold request-scoped supabase client
const storage = new AsyncLocalStorage();

// Proxy for supabaseAdmin
const supabaseAdmin = new Proxy({}, {
  get(target, prop) {
    const activeClient = storage.getStore() || rawSupabaseAdmin || supabase;
    const value = activeClient[prop];
    if (typeof value === 'function') {
      return value.bind(activeClient);
    }
    return value;
  }
});

// Middleware to populate AsyncLocalStorage per request
const supabaseSessionMiddleware = (req, res, next) => {
  let client = rawSupabaseAdmin;
  if (!client) {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      client = createClient(supabaseUrl, supabaseAnonKey, {
        global: {
          headers: {
            Authorization: `Bearer ${token}`
          }
        },
        auth: {
          persistSession: false,
          autoRefreshToken: false
        }
      });
    } else {
      client = supabase;
    }
  }
  storage.run(client, next);
};

module.exports = {
  supabase,
  supabaseAdmin,
  supabaseSessionMiddleware,
};
