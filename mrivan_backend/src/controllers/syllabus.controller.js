const pdfParse = require('pdf-parse');
const geminiService = require('../services/gemini.service');

/**
 * Parse uploaded PDF or TXT syllabus file into structured JSON chapters/topics
 */
const parseSyllabus = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Please upload a syllabus file (PDF or TXT)' });
    }

    let syllabusText = '';
    const mimeType = req.file.mimetype;
    const fileName = req.file.originalname.toLowerCase();

    if (mimeType === 'application/pdf' || fileName.endsWith('.pdf')) {
      try {
        const parsedPdf = await pdfParse(req.file.buffer);
        syllabusText = parsedPdf.text;
      } catch (pdfErr) {
        console.error('Syllabus PDF parsing error:', pdfErr);
        return res.status(400).json({ error: 'Failed to parse PDF file. Ensure it is a valid PDF.' });
      }
    } else if (mimeType.startsWith('text/') || fileName.endsWith('.txt')) {
      syllabusText = req.file.buffer.toString('utf-8');
    } else {
      return res.status(400).json({ error: 'Unsupported file format. Please upload a PDF or TXT file.' });
    }

    if (!syllabusText || syllabusText.trim().length === 0) {
      return res.status(400).json({ error: 'The uploaded file appears to have no extractable text.' });
    }

    const structuredSyllabus = await geminiService.parseSyllabus(syllabusText);

    res.json(structuredSyllabus);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  parseSyllabus,
};
