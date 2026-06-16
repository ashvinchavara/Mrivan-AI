import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';
import '../../../data/services/database_service.dart';

class HomeworkManagerScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? schoolId;
  const HomeworkManagerScreen({super.key, required this.isDarkMode, this.schoolId});

  @override
  State<HomeworkManagerScreen> createState() => _HomeworkManagerScreenState();
}

class _HomeworkManagerScreenState extends State<HomeworkManagerScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late bool _isDarkMode;

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  List<Map<String, dynamic>> _homeworkList = [];

  bool _isLoadingClasses = false;
  bool _isLoadingHomework = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final schoolId = widget.schoolId;
    if (schoolId == null) return;

    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final classes = await DatabaseService.instance.fetchClasses(schoolId);
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty) {
          _selectedClassId = classes[0]['id'];
          _loadHomework(_selectedClassId!);
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error loading classes: $e');
    } finally {
      setState(() {
        _isLoadingClasses = false;
      });
    }
  }

  Future<void> _loadHomework(String classId) async {
    setState(() {
      _isLoadingHomework = true;
      _homeworkList = [];
    });

    try {
      final homework = await DatabaseService.instance.fetchHomework(classId: classId);
      setState(() {
        _homeworkList = homework;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading homework: $e');
    } finally {
      setState(() {
        _isLoadingHomework = false;
      });
    }
  }

  void _showAssignHomeworkDialog() {
    if (_selectedClassId == null) return;
    
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateString = "${dueDate.day}/${dueDate.month}/${dueDate.year}";
            return AlertDialog(
              backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
              title: Text(
                'Assign New Homework',
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Due Date:',
                        style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(dateString),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              dueDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();
                    final teacherId = _client.auth.currentUser?.id;

                    if (title.isEmpty || teacherId == null) return;

                    final formattedDate = "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";

                    try {
                      await DatabaseService.instance.assignHomework(
                        title: title,
                        description: desc,
                        dueDate: formattedDate,
                        classId: _selectedClassId!,
                        teacherId: teacherId,
                      );
                      
                      Navigator.pop(context);
                      _loadHomework(_selectedClassId!);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Homework assigned successfully!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      if (kDebugMode) print('Error assigning homework: $e');
                    }
                  },
                  child: const Text('Publish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _viewSubmissions(Map<String, dynamic> homework) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeworkSubmissionsScreen(
          isDarkMode: _isDarkMode,
          homework: homework,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        isDarkMode: _isDarkMode,
        child: Stack(
          children: [
            // 1. Header
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
                              Icon(Icons.assignment_rounded, color: _isDarkMode ? Colors.orangeAccent : Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                'Homework Manager',
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

            // 2. Body
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 80,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Column(
                        children: [
                          // Class selector
                          _buildGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _isLoadingClasses
                                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                      : _classes.isEmpty
                                          ? Text(
                                              'No Classes Found',
                                              style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
                                            )
                                          : DropdownButtonFormField<String>(
                                              value: _selectedClassId,
                                              dropdownColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
                                              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                                              decoration: InputDecoration(
                                                labelText: 'Select Class',
                                                labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              items: _classes.map((cls) {
                                                return DropdownMenuItem<String>(
                                                  value: cls['id'] as String,
                                                  child: Text(cls['name'] ?? ''),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() {
                                                    _selectedClassId = val;
                                                  });
                                                  _loadHomework(val);
                                                }
                                              },
                                            ),
                                ),
                                const SizedBox(width: 16),
                                FloatingActionButton(
                                  onPressed: _showAssignHomeworkDialog,
                                  backgroundColor: _isDarkMode ? Colors.orangeAccent.shade400 : Colors.orange,
                                  foregroundColor: Colors.white,
                                  child: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Homework items list
                          Expanded(
                            child: _isLoadingHomework
                                ? const Center(child: CircularProgressIndicator())
                                : _homeworkList.isEmpty
                                    ? _buildGlassCard(
                                        padding: const EdgeInsets.all(24),
                                        child: Center(
                                          child: Text(
                                            'No homework assignments created.',
                                            style: TextStyle(
                                              color: _isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _homeworkList.length,
                                        itemBuilder: (context, index) {
                                          final hw = _homeworkList[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: _buildGlassCard(
                                              padding: const EdgeInsets.all(18),
                                              onTap: () => _viewSubmissions(hw),
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
                                                              Icons.alarm_rounded,
                                                              size: 14,
                                                              color: _isDarkMode ? Colors.orangeAccent : Colors.orange,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              "Due: ${hw['due_date'] ?? ''}",
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
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: _isDarkMode ? Colors.white30 : Colors.black38,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
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

// Submissions Screen
class HomeworkSubmissionsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> homework;
  const HomeworkSubmissionsScreen({super.key, required this.isDarkMode, required this.homework});

  @override
  State<HomeworkSubmissionsScreen> createState() => _HomeworkSubmissionsScreenState();
}

class _HomeworkSubmissionsScreenState extends State<HomeworkSubmissionsScreen> {
  late bool _isDarkMode;
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subs = await DatabaseService.instance.fetchHomeworkSubmissions(widget.homework['id']);
      setState(() {
        _submissions = subs;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading submissions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showGradeDialog(Map<String, dynamic> sub) {
    final gradeController = TextEditingController(text: sub['grade']);
    final feedbackController = TextEditingController(text: sub['feedback']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
          title: Text(
            'Grade Submission',
            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gradeController,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: const InputDecoration(labelText: 'Grade (e.g. A, B, 95, 100)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: const InputDecoration(labelText: 'Feedback'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final grade = gradeController.text.trim();
                final feedback = feedbackController.text.trim();

                try {
                  await DatabaseService.instance.gradeHomeworkSubmission(
                    submissionId: sub['id'],
                    grade: grade,
                    feedback: feedback,
                  );
                  Navigator.pop(context);
                  _loadSubmissions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Graded successfully!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  if (kDebugMode) print('Error grading submission: $e');
                }
              },
              child: const Text('Save Grade'),
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
                          child: Text(
                            "Submissions: ${widget.homework['title']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
                          : _submissions.isEmpty
                              ? _buildGlassCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No homework submissions received yet.',
                                      style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _submissions.length,
                                  itemBuilder: (context, index) {
                                    final sub = _submissions[index];
                                    final profile = sub['profiles'] as Map<String, dynamic>?;
                                    final studentName = profile?['full_name'] ?? 'Student';
                                    final roll = profile?['student_roll_number'] ?? 'N/A';
                                    final hasGrade = sub['grade'] != null && sub['grade'].toString().isNotEmpty;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: _buildGlassCard(
                                        padding: const EdgeInsets.all(18),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      studentName,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: _isDarkMode ? Colors.white : Colors.black87,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Roll: $roll",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _isDarkMode ? Colors.white54 : Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Grade Label
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: hasGrade
                                                        ? Colors.green.withValues(alpha: 0.15)
                                                        : Colors.orange.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    hasGrade ? "Grade: ${sub['grade']}" : "Ungraded",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      color: hasGrade ? Colors.green : Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 20),
                                            Text(
                                              "Submission text:",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _isDarkMode ? Colors.white54 : Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              sub['submission_text'] ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: _isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            if (sub['feedback'] != null && sub['feedback'].toString().isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Text(
                                                "Feedback: ${sub['feedback']}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.edit_note_rounded, size: 18),
                                              label: Text(hasGrade ? 'Change Grade' : 'Grade Submission'),
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: const Size(double.infinity, 38),
                                              ),
                                              onPressed: () => _showGradeDialog(sub),
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

  Widget _buildGlassCard({required Widget child, required EdgeInsets padding}) {
    return ClipRRect(
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
    );
  }
}
