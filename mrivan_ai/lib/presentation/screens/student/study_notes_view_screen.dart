import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyNotesViewScreen extends StatefulWidget {
  final String topic;
  final String subject;
  final bool isDarkMode;

  const StudyNotesViewScreen({
    super.key,
    required this.topic,
    required this.subject,
    required this.isDarkMode,
  });

  @override
  State<StudyNotesViewScreen> createState() => _StudyNotesViewScreenState();
}

class _StudyNotesViewScreenState extends State<StudyNotesViewScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  String _errorMessage = '';
  String _notesMarkdown = '';
  bool _isSavedToLibrary = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchStudyNotes();
  }

  Future<void> _fetchStudyNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.post(
        Uri.parse('$envBackendUrl/api/ai/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'topic': widget.topic,
          'subject': widget.subject,
          'gradeLevel': '10',
          'saveToLibrary': false,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data == null || data['notes'] == null) {
        throw Exception('Failed to parse generated notes.');
      }

      if (mounted) {
        setState(() {
          _notesMarkdown = data['notes'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching study notes: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotesToLibrary() async {
    if (_isSaving || _isSavedToLibrary) return;

    setState(() {
      _isSaving = true;
    });

    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.post(
        Uri.parse('$envBackendUrl/api/ai/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'topic': widget.topic,
          'subject': widget.subject,
          'gradeLevel': '10',
          'saveToLibrary': true,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      if (mounted) {
        setState(() {
          _isSavedToLibrary = true;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📚 Notes successfully saved to your study library!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error saving notes: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final currentBg = widget.isDarkMode ? bgDark : bgLight;
    final currentCard = widget.isDarkMode ? cardDark : cardLight;
    final currentText = widget.isDarkMode ? textDark : textLight;
    final currentBorder = widget.isDarkMode ? borderDark : borderLight;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          widget.topic,
          style: TextStyle(color: currentText, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (!_isLoading && _errorMessage.isEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Color(0xFF4F46E5)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _notesMarkdown));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notes copied to clipboard!'),
                    backgroundColor: Color(0xFF4F46E5),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              tooltip: 'Copy Notes',
            ),
            IconButton(
              icon: Icon(
                _isSavedToLibrary ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                color: _isSavedToLibrary ? Colors.green : Colors.grey,
              ),
              onPressed: _saveNotesToLibrary,
              tooltip: 'Save to Library',
            ),
          ]
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to generate study notes',
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchStudyNotes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Study Notes Header Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDarkMode
                              ? [const Color(0xFF1E1A3C), const Color(0xFF13131A)]
                              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: currentBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Generated conceptual study notes',
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : const Color(0xFF4F46E5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Subject: ${widget.subject} • Target: Class 10 Syllabus',
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Render parsed markdown notes
                    ..._parseAndRenderMarkdown(_notesMarkdown, currentText, currentCard, currentBorder),
                    
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }

  List<Widget> _parseAndRenderMarkdown(String rawText, Color textCol, Color cardCol, Color borderCol) {
    final List<Widget> widgets = [];
    final lines = rawText.split('\n');

    bool inCodeBlock = false;
    List<String> codeBlockLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Code blocks start or end
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          // End of code block: render gathered content
          inCodeBlock = false;
          widgets.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol),
              ),
              child: Text(
                codeBlockLines.join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
          );
          codeBlockLines.clear();
        } else {
          // Start of code block
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }

      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      // Parse headers
      if (trimmed.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
            child: Text(
              trimmed.substring(2),
              style: TextStyle(
                color: textCol,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
            child: Text(
              trimmed.substring(3),
              style: TextStyle(
                color: textCol,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              trimmed.substring(4),
              style: TextStyle(
                color: textCol,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } 
      // Parse bullet points
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final content = trimmed.substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: textCol.withOpacity(0.7), fontSize: 13)),
                Expanded(
                  child: _renderTextWithBoldSupport(content, textCol, 12),
                ),
              ],
            ),
          ),
        );
      } 
      // Standard paragraph
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _renderTextWithBoldSupport(trimmed, textCol, 12, height: 1.5),
          ),
        );
      }
    }

    return widgets;
  }

  // Helper to parse **bold text** inside paragraphs/bullets
  Widget _renderTextWithBoldSupport(String text, Color textCol, double fontSize, {double height = 1.3}) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: textCol.withOpacity(0.85), fontSize: fontSize, height: height),
        children: spans,
      ),
    );
  }
}
