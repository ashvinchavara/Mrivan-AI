import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';
import '../../../data/services/database_service.dart';

class StudentHomeworkScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? classId;
  const StudentHomeworkScreen({super.key, required this.isDarkMode, this.classId});

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late bool _isDarkMode;

  List<Map<String, dynamic>> _homeworkList = [];
  Map<String, Map<String, dynamic>> _submissionsMap = {}; // Maps homeworkId -> submission object

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadHomeworkAndSubmissions();
  }

  Future<void> _loadHomeworkAndSubmissions() async {
    final classId = widget.classId;
    final user = _client.auth.currentUser;
    if (classId == null || user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch class homework
      final hwList = await DatabaseService.instance.fetchHomework(classId: classId);
      
      // 2. Fetch student's submissions for each homework
      final Map<String, Map<String, dynamic>> tempSubmissions = {};
      for (var hw in hwList) {
        final homeworkId = hw['id'];
        final response = await _client
            .from('homework_submissions')
            .select('id, homework_id, submission_text, grade, feedback')
            .eq('homework_id', homeworkId)
            .eq('student_id', user.id)
            .maybeSingle();
        
        if (response != null) {
          tempSubmissions[homeworkId] = response;
        }
      }

      setState(() {
        _homeworkList = hwList;
        _submissionsMap = tempSubmissions;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading student homework: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSubmitDialog(Map<String, dynamic> hw) {
    final homeworkId = hw['id'];
    final existingSubmission = _submissionsMap[homeworkId];
    final textController = TextEditingController(text: existingSubmission?['submission_text']);
    final isGraded = existingSubmission?['grade'] != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
          title: Text(
            isGraded ? 'View Submission (Graded)' : 'Submit Homework Answer',
            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hw['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                hw['description'] ?? '',
                style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54, fontSize: 13),
              ),
              const Divider(height: 20),
              if (isGraded) ...[
                Text(
                  "Grade: ${existingSubmission?['grade']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                if (existingSubmission?['feedback'] != null) ...[
                  const SizedBox(height: 4),
                  Text("Feedback: ${existingSubmission?['feedback']}", style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 12),
              ],
              Text(
                'Your Answer Text:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: textController,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type your solution here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabled: !isGraded, // Disable editing if already graded
                ),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (!isGraded)
              ElevatedButton(
                onPressed: () async {
                  final text = textController.text.trim();
                  final user = _client.auth.currentUser;
                  if (text.isEmpty || user == null) return;

                  try {
                    await DatabaseService.instance.submitHomework(
                      homeworkId: homeworkId,
                      studentId: user.id,
                      submissionText: text,
                    );
                    Navigator.pop(context);
                    _loadHomeworkAndSubmissions();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Homework submitted successfully!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    if (kDebugMode) print('Error submitting homework: $e');
                  }
                },
                child: const Text('Submit Answer'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        isDarkMode: _isDarkMode,
        child: Stack(
          children: [
            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: _isDarkMode ? Colors.black26 : Colors.white24,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: _isDarkMode ? Colors.white : Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: _isDarkMode ? Colors.black26 : Colors.white24,
                          child: Row(
                            children: [
                              Icon(Icons.assignment_turned_in_rounded, color: _isDarkMode ? Colors.orangeAccent : Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'My Homework Tasks',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 80,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _homeworkList.isEmpty
                              ? _buildGlassCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No homework assigned to your class yet!',
                                      style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _homeworkList.length,
                                  itemBuilder: (context, index) {
                                    final hw = _homeworkList[index];
                                    final submission = _submissionsMap[hw['id']];
                                    final isSubmitted = submission != null;
                                    final isGraded = submission?['grade'] != null;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: _buildGlassCard(
                                        padding: const EdgeInsets.all(18),
                                        onTap: () => _showSubmitDialog(hw),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    hw['title'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: _isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    hw['description'] ?? '',
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.alarm,
                                                        size: 14,
                                                        color: _isDarkMode ? Colors.orangeAccent : Colors.orange,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Due: ${hw['due_date']}",
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: _isDarkMode ? Colors.orangeAccent : Colors.orange,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Submission status badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isGraded
                                                    ? Colors.green.withValues(alpha: 0.15)
                                                    : isSubmitted
                                                        ? Colors.blue.withValues(alpha: 0.15)
                                                        : Colors.red.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isGraded
                                                    ? "Graded"
                                                    : isSubmitted
                                                        ? "Submitted"
                                                        : "Pending",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: isGraded
                                                      ? Colors.green
                                                      : isSubmitted
                                                          ? Colors.blue
                                                          : Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required EdgeInsets padding, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
