import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CombinedQuizScreen extends StatefulWidget {
  final String? testId;
  final String? testTitle;
  final String? topic;
  final String? subject;
  final bool isDarkMode;

  const CombinedQuizScreen({
    super.key,
    this.testId,
    this.testTitle,
    this.topic,
    this.subject,
    required this.isDarkMode,
  });

  @override
  State<CombinedQuizScreen> createState() => _CombinedQuizScreenState();
}

class _CombinedQuizScreenState extends State<CombinedQuizScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _questions = [];

  int _currentIndex = 0;
  final Map<String, String> _answers = {}; // Key: question index as string, Value: chosen answer string

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  Map<String, dynamic> _resultsData = {};
  String _activeView = 'quiz'; // 'quiz' or 'results'

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQuizData() async {
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

      if (widget.testId != null) {
        // Mode 1: Fetch Mock Test from School CRM database
        final response = await http.get(
          Uri.parse('$envBackendUrl/api/tests/${widget.testId}'),
          headers: {
            'Content-Type': 'application/json',
            'Bypass-Tunnel-Reminder': 'true',
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('Server returned status code ${response.statusCode}');
        }

        final data = jsonDecode(response.body);
        if (data == null || data['questions'] == null) {
          throw Exception('Could not parse mock test questions.');
        }

        _questions = data['questions'] is List ? data['questions'] : [];
        final durationMins = data['duration_minutes'] ?? 60;
        _secondsRemaining = durationMins * 60;
        _startTimer();
      } else if (widget.topic != null && widget.subject != null) {
        // Mode 2: Generate AI practice quiz on-the-fly for specified topic
        final response = await http.post(
          Uri.parse('$envBackendUrl/api/ai/quiz'),
          headers: {
            'Content-Type': 'application/json',
            'Bypass-Tunnel-Reminder': 'true',
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'subject': widget.subject,
            'topic': widget.topic,
            'count': 5,
          }),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode != 200) {
          throw Exception('Server returned status code ${response.statusCode}');
        }

        final data = jsonDecode(response.body);
        _questions = data is List ? data : [];
        
        // 2 minutes per question default timer
        _secondsRemaining = _questions.length * 2 * 60;
        if (_secondsRemaining > 0) {
          _startTimer();
        }
      } else {
        throw Exception('Invalid quiz configuration: missing test ID and topic parameters.');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading quiz data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _autoSubmitQuiz();
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _autoSubmitQuiz() async {
    if (_isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time\'s up! Submitting your answers automatically...'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _submitAnswers();
  }

  Future<void> _submitAnswers() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();

    try {
      if (widget.testId != null) {
        // Mode 1: Submit school mock test to backend for auto-grading
        const envBackendUrl = String.fromEnvironment(
          'BACKEND_API_URL',
          defaultValue: 'https://mrivan-ai.onrender.com',
        );
        final jwtToken = _client.auth.currentSession?.accessToken;

        final response = await http.post(
          Uri.parse('$envBackendUrl/api/tests/${widget.testId}/attempt'),
          headers: {
            'Content-Type': 'application/json',
            'Bypass-Tunnel-Reminder': 'true',
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'answers': _answers,
          }),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) {
          throw Exception('Server returned status code ${response.statusCode}');
        }

        final responseData = jsonDecode(response.body);
        setState(() {
          _resultsData = responseData;
          _isSubmitted = true;
          _isSubmitting = false;
          _activeView = 'results';
        });
      } else {
        // Mode 2: Grade AI-generated practice quiz offline (correctAnswer is already in question data)
        int correctCount = 0;
        final totalQuestions = _questions.length;
        final totalMarks = totalQuestions * 10;
        int score = 0;
        List<dynamic> gradingDetails = [];

        for (int i = 0; i < _questions.length; i++) {
          final q = _questions[i];
          final correctAns = q['correctAnswer'] ?? '';
          final studentAns = _answers[i.toString()] ?? '';
          final isCorrect = studentAns.trim().toLowerCase() == correctAns.toString().trim().toLowerCase();

          if (isCorrect) {
            score += 10;
            correctCount++;
          }

          gradingDetails.add({
            'questionIndex': i,
            'questionText': q['question'],
            'studentAnswer': studentAns,
            'correctAnswer': correctAns,
            'isCorrect': isCorrect,
            'explanation': q['explanation'] ?? '',
          });
        }

        setState(() {
          _resultsData = {
            'score': score,
            'totalMarks': totalMarks,
            'correctCount': correctCount,
            'totalQuestions': totalQuestions,
            'gradingDetails': gradingDetails,
          };
          _isSubmitted = true;
          _isSubmitting = false;
          _activeView = 'results';
        });
      }
    } catch (e) {
      if (kDebugMode) print('Submission error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit attempt: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startTimer(); // resume timer in case of transient network failure
      }
    }
  }

  void _confirmSubmitDialog() {
    final unansweredCount = _questions.length - _answers.length;
    showDialog(
      context: context,
      builder: (ctx) {
        final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final currentCard = widget.isDarkMode ? const Color(0xFF1E1E28) : Colors.white;

        return AlertDialog(
          backgroundColor: currentCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Submit Exam?', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            unansweredCount > 0
                ? 'You have $unansweredCount unanswered questions. Are you sure you want to finish and submit?'
                : 'Are you sure you want to complete and submit your answers now?',
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitAnswers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
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

    final quizTitle = widget.testTitle ?? (widget.topic != null ? 'AI Practice: ${widget.topic}' : 'Practice Quiz');

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          quizTitle,
          style: TextStyle(color: currentText, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Sleek Tab/View Switcher Toggle
          if (!_isLoading && _errorMessage.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeView = 'quiz';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _activeView == 'quiz' ? const Color(0xFF4F46E5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Quiz',
                          style: TextStyle(
                            color: _activeView == 'quiz' ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isSubmitted
                          ? () {
                              setState(() {
                                _activeView = 'results';
                              });
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please complete and submit the quiz to see results.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _activeView == 'results' ? const Color(0xFF4F46E5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Opacity(
                          opacity: _isSubmitted ? 1.0 : 0.5,
                          child: Text(
                            'Results',
                            style: TextStyle(
                              color: _activeView == 'results' ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                          'Failed to Load Quiz',
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchQuizData,
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
              : _isSubmitting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))),
                          const SizedBox(height: 16),
                          Text('Evaluating your test answers...', style: TextStyle(color: currentText, fontSize: 13)),
                        ],
                      ),
                    )
                  : _activeView == 'quiz'
                      ? _buildQuizView(currentBg, currentCard, currentText, currentBorder)
                      : _buildResultsView(currentBg, currentCard, currentText, currentBorder),
    );
  }

  Widget _buildQuizView(Color currentBg, Color currentCard, Color currentText, Color currentBorder) {
    if (_questions.isEmpty) {
      return Center(
        child: Text('No questions available.', style: TextStyle(color: currentText)),
      );
    }

    final question = _questions[_currentIndex];
    final options = question['options'] as List? ?? [];
    final selectedAns = _answers[_currentIndex.toString()];

    // Review mode configurations
    final correctAns = question['correctAnswer'] ?? '';
    final explanation = question['explanation'] ?? '';

    return Column(
      children: [
        // Progress and timer bar (only active if not submitted)
        if (!_isSubmitted) ...[
          LinearProgressIndicator(
            value: _questions.isEmpty ? 0.0 : (_currentIndex + 1) / _questions.length,
            backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            minHeight: 4,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: currentCard.withOpacity(0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: TextStyle(color: currentText.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600),
                ),
                if (_secondsRemaining > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_secondsRemaining),
                        style: TextStyle(
                          color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ] else ...[
          // Post-Submit progress bar (constant 100%)
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 4,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Mode: Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
              ],
            ),
          ),
        ],

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Question Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: currentCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentBorder),
                ),
                child: Text(
                  question['question'] ?? '',
                  style: TextStyle(
                    color: currentText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Question Options
              ...options.map((opt) {
                final optionText = opt.toString();
                final isSelected = selectedAns == optionText;

                Color tileBorderColor = currentBorder;
                Color tileBgColor = currentCard;
                Color checkColor = Colors.transparent;
                Color textStyleColor = currentText;

                if (_isSubmitted) {
                  // Review Mode styling
                  final isCorrectOption = optionText.trim().toLowerCase() == correctAns.toString().trim().toLowerCase();
                  final isStudentSelected = selectedAns == optionText;

                  if (isCorrectOption) {
                    // Correct answer: green outline
                    tileBorderColor = Colors.green;
                    tileBgColor = Colors.green.withOpacity(0.08);
                    checkColor = Colors.green;
                    textStyleColor = Colors.green;
                  } else if (isStudentSelected) {
                    // Incorrect selection: red outline
                    tileBorderColor = Colors.redAccent;
                    tileBgColor = Colors.redAccent.withOpacity(0.08);
                    checkColor = Colors.redAccent;
                    textStyleColor = Colors.redAccent;
                  }
                } else {
                  // Active test taking mode
                  if (isSelected) {
                    tileBorderColor = const Color(0xFF4F46E5);
                    tileBgColor = const Color(0xFF4F46E5).withOpacity(0.08);
                    checkColor = const Color(0xFF4F46E5);
                    textStyleColor = const Color(0xFF4F46E5);
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _isSubmitted
                        ? null // Read-only in review mode
                        : () {
                            setState(() {
                              _answers[_currentIndex.toString()] = optionText;
                            });
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: tileBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tileBorderColor,
                          width: isSelected || (_isSubmitted && (optionText == correctAns || isSelected)) ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: checkColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: checkColor == Colors.transparent ? Colors.grey : checkColor,
                                width: 1.5,
                              ),
                            ),
                            child: checkColor != Colors.transparent
                                ? Icon(
                                    checkColor == Colors.redAccent ? Icons.close : Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                color: textStyleColor,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Show explanation directly in review mode
              if (_isSubmitted && explanation.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: currentBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'AI Explanation',
                            style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        explanation,
                        style: TextStyle(color: currentText.withOpacity(0.85), fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Navigation Panel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: currentCard,
            border: Border(top: BorderSide(color: currentBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                color: _currentIndex > 0 ? currentText : Colors.grey[400],
                onPressed: _currentIndex > 0
                    ? () {
                        setState(() {
                          _currentIndex--;
                        });
                      }
                    : null,
              ),

              Text(
                '${_currentIndex + 1} / ${_questions.length}',
                style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold),
              ),

              // Next or Finish (if not submitted)
              if (!_isSubmitted) ...[
                _currentIndex < _questions.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Text('Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _confirmSubmitDialog,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                        label: const Text('Finish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ] else ...[
                // Next in Review Mode
                _currentIndex < _questions.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Text('Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _activeView = 'results';
                          });
                        },
                        icon: const Icon(Icons.analytics_rounded, size: 14),
                        label: const Text('View Results', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView(Color currentBg, Color currentCard, Color currentText, Color currentBorder) {
    final score = _resultsData['score'] ?? 0;
    final totalMarks = _resultsData['totalMarks'] ?? 100;
    final correctCount = _resultsData['correctCount'] ?? 0;
    final totalQuestions = _resultsData['totalQuestions'] ?? 0;
    final gradingDetails = _resultsData['gradingDetails'] as List? ?? [];

    final percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0.0;
    final isPassed = percentage >= 50.0;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Score Summary Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: currentCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: currentBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            children: [
              Text(
                isPassed ? '🎉 Great Job! Quiz Completed' : '📚 Keep Learning! Quiz Completed',
                style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: totalMarks > 0 ? score / totalMarks : 0,
                      strokeWidth: 10,
                      backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPassed ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isPassed ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        '$score / $totalMarks Marks',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Passed', isPassed ? 'Yes' : 'No', isPassed ? Colors.green : Colors.orange),
                  _buildStatItem('Correct', '$correctCount / $totalQuestions', currentText),
                  _buildStatItem('Accuracy', '${totalQuestions > 0 ? ((correctCount / totalQuestions) * 100).toStringAsFixed(0) : 0}%', currentText),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Row(
          children: [
            Icon(Icons.list_alt_rounded, color: const Color(0xFF4F46E5), size: 18),
            const SizedBox(width: 8),
            Text(
              'Performance Summary Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentText),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Quick list of questions indicating pass/fail status
        ...gradingDetails.map((detail) {
          final qIndex = (detail['questionIndex'] ?? 0) + 1;
          final qText = detail['questionText'] ?? '';
          final studentAns = detail['studentAnswer'] ?? '';
          final isCorrect = detail['isCorrect'] ?? false;
          final detailColor = isCorrect ? Colors.green : Colors.redAccent;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: currentCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: currentBorder),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: detailColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q$qIndex',
                  style: TextStyle(color: detailColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              title: Text(
                qText,
                style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                studentAns.isEmpty ? 'Unanswered' : 'Your Answer: $studentAns',
                style: TextStyle(color: studentAns.isEmpty ? Colors.grey : detailColor, fontSize: 10),
              ),
              trailing: Icon(
                isCorrect ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                color: detailColor,
                size: 18,
              ),
              onTap: () {
                setState(() {
                  _currentIndex = qIndex - 1;
                  _activeView = 'quiz';
                });
              },
            ),
          );
        }),
        const SizedBox(height: 24),

        // Primary actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _activeView = 'quiz';
                  });
                },
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('Review Questions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.home_outlined, size: 16),
                label: const Text('Back to Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: currentText,
                  side: BorderSide(color: currentBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
