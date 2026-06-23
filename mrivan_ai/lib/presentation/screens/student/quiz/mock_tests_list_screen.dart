import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'combined_quiz_screen.dart';

class MockTestsListScreen extends StatefulWidget {
  final bool isDarkMode;
  const MockTestsListScreen({super.key, required this.isDarkMode});

  @override
  State<MockTestsListScreen> createState() => _MockTestsListScreenState();
}

class _MockTestsListScreenState extends State<MockTestsListScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<dynamic> _tests = [];
  List<dynamic> _attempts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPortalData();
  }

  Future<void> _loadPortalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User session not found.');
      }

      // 1. Fetch available mock tests from backend API
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.get(
        Uri.parse('$envBackendUrl/api/tests'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final testData = jsonDecode(response.body);

      // 2. Fetch student attempts history from Supabase mock_tests/test_attempts join
      final attemptData = await _client
          .from('test_attempts')
          .select('id, score, completed_at, mock_tests(title, total_marks, subject)')
          .eq('student_id', user.id)
          .order('completed_at', ascending: false);

      if (mounted) {
        setState(() {
          _tests = testData is List ? testData : [];
          _attempts = attemptData is List ? attemptData : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Mock Exam Portal Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
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
          'CBT Mock Exam Space 📝',
          style: TextStyle(color: currentText, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: const Color(0xFF4F46E5)),
            onPressed: _loadPortalData,
            tooltip: 'Refresh',
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
                          'Connection Error',
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadPortalData,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPortalData,
                  color: const Color(0xFF4F46E5),
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isDarkMode
                                ? [const Color(0xFF2E1A47), const Color(0xFF1A1F3C)]
                                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: currentBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Computer-Based Testing (CBT) Center 💻',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Test your knowledge with real-time graded exams. Attempts will be saved to your dashboard analytics automatically.',
                              style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 1: Available Exams
                      Row(
                        children: [
                          Icon(Icons.quiz_rounded, color: const Color(0xFF4F46E5), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Available Mock Exams',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _tests.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              alignment: Alignment.center,
                              child: Text(
                                'No exams published yet by your teachers.',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tests.length,
                              itemBuilder: (context, index) {
                                final test = _tests[index];
                                final title = test['title'] ?? 'Mock Test';
                                final subject = test['subject'] ?? 'General';
                                final duration = test['duration_minutes'] ?? 60;
                                final marks = test['total_marks'] ?? 100;
                                final desc = test['description'] ?? '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: currentCard,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: currentBorder),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4F46E5).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                subject,
                                                style: const TextStyle(
                                                  color: Color(0xFF4F46E5),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.timer_outlined, color: Colors.grey, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$duration mins',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          title,
                                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            desc,
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total: $marks Marks',
                                              style: TextStyle(color: currentText, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => CombinedQuizScreen(
                                                      testId: test['id'],
                                                      testTitle: title,
                                                      isDarkMode: widget.isDarkMode,
                                                    ),
                                                  ),
                                                ).then((_) => _loadPortalData());
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4F46E5),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('Start Exam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),

                      // Section 2: Attempt History
                      Row(
                        children: [
                          Icon(Icons.history_rounded, color: Colors.teal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Past Attempts History',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _attempts.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              alignment: Alignment.center,
                              child: Text(
                                'You haven\'t attempted any mock exams yet.',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _attempts.length,
                              itemBuilder: (context, index) {
                                final attempt = _attempts[index];
                                final testObj = attempt['mock_tests'] ?? {};
                                final title = testObj['title'] ?? 'Mock Test';
                                final subject = testObj['subject'] ?? 'General';
                                final totalMarks = testObj['total_marks'] ?? 100;
                                final score = attempt['score'] ?? 0;
                                final completedAt = attempt['completed_at'] != null
                                    ? DateTime.parse(attempt['completed_at']).toLocal()
                                    : DateTime.now();

                                final formattedDate = '${completedAt.day}/${completedAt.month}/${completedAt.year}';
                                final isPassed = score >= (totalMarks * 0.5);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: currentCard,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: currentBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (isPassed ? Colors.green : Colors.orange).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPassed ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                                          color: isPassed ? Colors.green : Colors.orange,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$subject • Completed on $formattedDate',
                                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$score/$totalMarks',
                                            style: TextStyle(
                                              color: isPassed ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${((score / totalMarks) * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}
