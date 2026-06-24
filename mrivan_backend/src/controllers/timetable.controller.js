const pdfParse = require('pdf-parse');
const geminiService = require('../services/gemini.service');

/**
 * Parse an uploaded PDF or TXT timetable file into structured JSON schedule entries.
 * Returns an array of { day_of_week, subject, time_slot, teacher_name } objects.
 */
const parseTimetable = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Please upload a timetable file (PDF or TXT)' });
    }

    let timetableText = '';
    const mimeType = req.file.mimetype;
    const fileName = req.file.originalname.toLowerCase();

    if (mimeType === 'application/pdf' || fileName.endsWith('.pdf')) {
      try {
        const parsedPdf = await pdfParse(req.file.buffer);
        timetableText = parsedPdf.text;
      } catch (pdfErr) {
        console.error('Timetable PDF parsing error:', pdfErr);
        return res.status(400).json({ error: 'Failed to parse PDF file. Ensure it is a valid, text-based PDF.' });
      }
    } else if (mimeType.startsWith('text/') || fileName.endsWith('.txt')) {
      timetableText = req.file.buffer.toString('utf-8');
    } else {
      return res.status(400).json({ error: 'Unsupported file format. Please upload a PDF or TXT file.' });
    }

    if (!timetableText || timetableText.trim().length === 0) {
      return res.status(400).json({ error: 'The uploaded file appears to have no extractable text.' });
    }

    const structuredTimetable = await geminiService.parseTimetable(timetableText);

    res.json(structuredTimetable);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  parseTimetable,
};
