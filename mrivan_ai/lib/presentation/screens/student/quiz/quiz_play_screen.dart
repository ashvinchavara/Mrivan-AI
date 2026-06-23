import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quiz_results_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final bool isDarkMode;

  const QuizPlayScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    required this.isDarkMode,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _testData = {};
  List<dynamic> _questions = [];

  int _currentIndex = 0;
  final Map<String, String> _answers = {}; // Key: question index as string, Value: chosen answer string

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchTestDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTestDetails() async {
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

      _testData = data;
      _questions = data['questions'] is List ? data['questions'] : [];

      final durationMins = data['duration_minutes'] ?? 60;
      _secondsRemaining = durationMins * 60;

      _startTimer();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching test questions: $e');
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultsScreen(
              resultsData: responseData,
              testTitle: widget.testTitle,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
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

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          widget.testTitle,
          style: TextStyle(color: currentText, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading && _errorMessage.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _secondsRemaining < 60 ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
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
                          'Failed to Load Exam',
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTestDetails,
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
                          Text('Evaluating your test attempts...', style: TextStyle(color: currentText, fontSize: 13)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Progress Indicator
                        LinearProgressIndicator(
                          value: _questions.isEmpty ? 0.0 : (_currentIndex + 1) / _questions.length,
                          backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                          minHeight: 4,
                        ),

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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Question ${_currentIndex + 1} of ${_questions.length}',
                                      style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _questions[_currentIndex]['question'] ?? '',
                                      style: TextStyle(
                                        color: currentText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Question Options
                              ...(() {
                                final options = _questions[_currentIndex]['options'] as List? ?? [];
                                return options.map((opt) {
                                  final optionText = opt.toString();
                                  final isSelected = _answers[_currentIndex.toString()] == optionText;
                                  final activeColor = const Color(0xFF4F46E5);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _answers[_currentIndex.toString()] = optionText;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Ink(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected ? activeColor.withOpacity(0.08) : currentCard,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? activeColor : currentBorder,
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: isSelected ? activeColor : Colors.transparent,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected ? activeColor : Colors.grey,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                                                  : null,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                optionText,
                                                style: TextStyle(
                                                  color: isSelected ? activeColor : currentText,
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
                                }).toList();
                              }()),
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

                              // Quick Jump indicator dots or numbers
                              Text(
                                '${_currentIndex + 1} / ${_questions.length}',
                                style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold),
                              ),

                              // Next or Submit
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
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
