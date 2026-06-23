const pdfParse = require('pdf-parse');
const geminiService = require('../services/gemini.service');

/**
 * Analyze uploaded PDF Resume against target career role using Gemini
 */
const analyzeResume = async (req, res, next) => {
  try {
    const { role } = req.body;
    if (!req.file) {
      return res.status(400).json({ error: 'Please upload a PDF resume file' });
    }

    // Extract text from the PDF file buffer
    let parsedPdf;
    try {
      parsedPdf = await pdfParse(req.file.buffer);
    } catch (pdfErr) {
      console.error('PDF parsing error:', pdfErr);
      return res.status(400).json({ error: 'Failed to parse PDF file. Ensure it is a valid PDF.' });
    }

    const resumeText = parsedPdf.text;
    if (!resumeText || resumeText.trim().length === 0) {
      return res.status(400).json({ error: 'The uploaded PDF appears to have no extractable text.' });
    }

    // Call Gemini Service to analyze resume text against the target job role
    const gradingResult = await geminiService.analyzeResume(resumeText, role || 'General Role');

    res.json(gradingResult);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  analyzeResume,
};
