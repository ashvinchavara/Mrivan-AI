const express = require('express');
const cors = require('cors');
const { errorHandler } = require('./middleware/error.middleware');

// Route imports
const authRoutes = require('./routes/auth.routes');
const crmRoutes = require('./routes/crm.routes');
const aiRoutes = require('./routes/ai.routes');
const testRoutes = require('./routes/test.routes');

const { supabaseSessionMiddleware } = require('./config/db');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(supabaseSessionMiddleware);

app.use((req, res, next) => {
  console.log(`[REQUEST] ${req.method} ${req.url}`);
  next();
});

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

module.exports = app;
