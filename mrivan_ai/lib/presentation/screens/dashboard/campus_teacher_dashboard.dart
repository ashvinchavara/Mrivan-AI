import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../data/services/database_service.dart';
import '../../theme/theme_config.dart';
import '../../widgets/animated_background.dart';

class CampusTeacherDashboard extends StatefulWidget {
  final String userName;
  final String schoolId;
  final String email;

  const CampusTeacherDashboard({
    super.key,
    required this.userName,
    required this.schoolId,
    required this.email,
  });

  @override
  State<CampusTeacherDashboard> createState() => _CampusTeacherDashboardState();
}

class _CampusTeacherDashboardState extends State<CampusTeacherDashboard> {
  int _currentIndex = 0;
  final SupabaseClient _client = Supabase.instance.client;

  List<String> get _tabs => [
    'Teacher Cockpit',
    'Attendance Manager',
    'Homework & Grading',
    'AI Lesson & Notes',
    'Syllabus Manager',
  ];

  Future<void> _handleSignOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      if (kDebugMode) print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 950;
    
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final initialText = widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'T';

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        final currentBg = isDarkMode ? bgDark : bgLight;
        final currentCard = isDarkMode ? cardDark : cardLight;
        final currentText = isDarkMode ? textDark : textLight;
        final currentBorder = isDarkMode ? borderDark : borderLight;

        Widget currentScreen;
        switch (_currentIndex) {
          case 0:
            currentScreen = TeacherCockpitTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 1:
            currentScreen = TeacherAttendanceTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 2:
            currentScreen = TeacherHomeworkTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 3:
            currentScreen = TeacherLessonPlannerTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 4:
            currentScreen = TeacherSyllabusTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          default:
            currentScreen = Center(child: Text('Coming Soon', style: TextStyle(color: currentText)));
        }

        return Scaffold(
          backgroundColor: currentBg,
          appBar: !isDesktop
              ? AppBar(
                  iconTheme: IconThemeData(color: currentText),
                  title: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.jpeg',
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF4F46E5),
                            width: 30,
                            height: 30,
                            child: const Icon(Icons.school, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Teacher Cockpit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: currentText,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: currentBg,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: currentText),
                      onPressed: () => isDarkModeNotifier.value = !isDarkModeNotifier.value,
                    ),
                  ],
                )
              : null,
          drawer: !isDesktop
              ? Drawer(
                  backgroundColor: currentCard,
                  child: Column(
                    children: [
                      DrawerHeader(
                        decoration: BoxDecoration(color: currentBg),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: const Color(0xFF4F46E5),
                                child: Text(initialText, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 8),
                              Text(widget.userName, style: TextStyle(color: currentText, fontWeight: FontWeight.bold)),
                              Text(widget.email, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _tabs.length,
                          itemBuilder: (context, idx) {
                            return ListTile(
                              title: Text(_tabs[idx], style: TextStyle(color: _currentIndex == idx ? const Color(0xFF4F46E5) : currentText)),
                              selected: _currentIndex == idx,
                              onTap: () {
                                setState(() => _currentIndex = idx);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
                        title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                        onTap: () {
                          Navigator.pop(context);
                          _handleSignOut();
                        },
                      ),
                    ],
                  ),
                )
              : null,
          body: Row(
            children: [
              if (isDesktop) ...[
                // Sidebar
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: currentCard,
                    border: Border(right: BorderSide(color: currentBorder)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/logo.jpeg',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF4F46E5),
                                  width: 36,
                                  height: 36,
                                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'MRIVAN AI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: currentText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tabs.length,
                          itemBuilder: (context, idx) {
                            final isSelected = _currentIndex == idx;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  idx == 0
                                      ? Icons.dashboard_rounded
                                      : idx == 1
                                          ? Icons.fact_check_rounded
                                          : idx == 2
                                              ? Icons.assignment_rounded
                                              : idx == 3
                                                  ? Icons.menu_book_rounded
                                                  : Icons.format_list_bulleted_rounded,
                                  color: isSelected ? const Color(0xFF4F46E5) : Colors.grey,
                                ),
                                title: Text(
                                  _tabs[idx],
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF4F46E5) : currentText,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                onTap: () => setState(() => _currentIndex = idx),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      // Light/Dark Toggle and User Info in Desktop Sidebar
                      ListTile(
                        leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.grey),
                        title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode', style: TextStyle(color: currentText, fontSize: 13)),
                        onTap: () => isDarkModeNotifier.value = !isDarkModeNotifier.value,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF4F46E5),
                              child: Text(initialText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userName,
                                    style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text('Faculty Member', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                              onPressed: _handleSignOut,
                              tooltip: 'Sign Out',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: SafeArea(
                  child: AnimatedBackground(
                    isDarkMode: isDarkMode,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32.0 : 16.0,
                        vertical: 24.0,
                      ),
                      child: currentScreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isDesktop
              ? BottomNavigationBar(
                  backgroundColor: currentCard,
                  selectedItemColor: const Color(0xFF4F46E5),
                  unselectedItemColor: Colors.grey,
                  currentIndex: _currentIndex,
                  onTap: (idx) => setState(() => _currentIndex = idx),
                  type: BottomNavigationBarType.fixed,
                  items: [
                    const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                    const BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Attendance'),
                    const BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Homework'),
                    const BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'AI Notes'),
                    const BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted_rounded), label: 'Syllabus'),
                  ],
                )
              : null,
        );
      },
    );
  }
}

// ----------------------------------------------------
// Sub-tab 0: Teacher Cockpit Overview
// ----------------------------------------------------
class TeacherCockpitTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const TeacherCockpitTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<TeacherCockpitTab> createState() => _TeacherCockpitTabState();
}

class _TeacherCockpitTabState extends State<TeacherCockpitTab> {
  bool _loading = true;
  int _studentCount = 0;
  int _classesCount = 0;
  int _homeworkCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final classes = await DatabaseService.instance.fetchClasses(widget.schoolId);
      int totalStudents = 0;
      for (var c in classes) {
        final st = await DatabaseService.instance.fetchStudentsInClass(c['id']);
        totalStudents += st.length;
      }
      
      setState(() {
        _classesCount = classes.length;
        _studentCount = totalStudents;
        _homeworkCount = classes.isNotEmpty ? 4 : 0; // Simulated active assignments
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Faculty Dashboard 🏫',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: currentText, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          const Text('Track attendance, organize lesson outlines, and review assignments.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _buildStatCard('Active Classes', '$_classesCount', 'Sections under your supervision', const Color(0xFF6C63FF), Icons.layers_rounded, cardBg, currentText),
              _buildStatCard('Total Students', '$_studentCount', 'Registered and active learners', const Color(0xFF00F2FE), Icons.people_alt_rounded, cardBg, currentText),
              _buildStatCard('Active Tasks', '$_homeworkCount', 'Assignments awaiting grading', const Color(0xFFFF2A6D), Icons.task_alt_rounded, cardBg, currentText),
            ],
          ),
          const SizedBox(height: 24),

          // Quick guide banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isDarkMode
                    ? [const Color(0xFF1E1E38), const Color(0xFF14142B)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF4F46E5), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI-Supported Curriculum Planning Active', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      const Text(
                        'Navigate to the AI Lesson & Notes tab to draft lesson plans, auto-generate study notes, and deploy them directly to your classes.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String desc, Color highlightColor, IconData icon, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
              Icon(icon, color: highlightColor, size: 20),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -1)),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Sub-tab 1: Attendance Manager
// ----------------------------------------------------
class TeacherAttendanceTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const TeacherAttendanceTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<TeacherAttendanceTab> {
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendanceMap = {}; // studentId -> status ('Present', 'Absent', 'Late')
  bool _loadingClasses = true;
  bool _loadingStudents = false;
  bool _submitting = false;

  List<Map<String, dynamic>> _timetableSlots = [];
  String? _selectedSlotId; // timetable slot ID
  bool _loadingTimetable = true;
  final SupabaseClient _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loadingClasses = true;
      _loadingTimetable = true;
    });
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final slots = await DatabaseService.instance.fetchTeacherTimetable(user.id);
        setState(() {
          _timetableSlots = slots;
        });
      }
      final data = await DatabaseService.instance.fetchClasses(widget.schoolId);
      setState(() {
        _classes = data;
        if (_classes.isNotEmpty) {
          if (_timetableSlots.isNotEmpty) {
            _selectedSlotId = _timetableSlots.first['id'];
            _selectedClassId = _timetableSlots.first['class_id'];
          } else {
            _selectedClassId = _classes.first['id'];
          }
          if (_selectedClassId != null) {
            _loadStudents(_selectedClassId!);
          }
        }
        _loadingClasses = false;
        _loadingTimetable = false;
      });
    } catch (e) {
      setState(() {
        _loadingClasses = false;
        _loadingTimetable = false;
      });
    }
  }

  void _onSlotChanged(String? slotId) {
    if (slotId == null) {
      setState(() {
        _selectedSlotId = null;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
          _loadStudents(_selectedClassId!);
        }
      });
    } else {
      final slot = _timetableSlots.firstWhere((s) => s['id'] == slotId);
      setState(() {
        _selectedSlotId = slotId;
        _selectedClassId = slot['class_id'];
        _loadStudents(_selectedClassId!);
      });
    }
  }

  Future<void> _loadStudents(String classId) async {
    setState(() {
      _loadingStudents = true;
      _students = [];
      _attendanceMap = {};
    });
    try {
      final list = await DatabaseService.instance.fetchStudentsInClass(classId);
      setState(() {
        _students = list;
        for (var s in _students) {
          _attendanceMap[s['id']] = 'Present'; // Default status
        }
        _loadingStudents = false;
      });
    } catch (e) {
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _submitAttendance() async {
    if (_selectedClassId == null || _students.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      final List<Map<String, dynamic>> records = _students.map((s) => {
        'student_id': s['id'],
        'status': _attendanceMap[s['id']] ?? 'Present',
      }).toList();

      await DatabaseService.instance.recordAttendanceBulk(
        schoolId: widget.schoolId,
        classId: _selectedClassId!,
        date: dateStr,
        records: records,
        timetableId: _selectedSlotId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance recorded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    if (_loadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Manager 📝',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Timetable Period: ', style: TextStyle(color: currentText, fontSize: 13)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      dropdownColor: cardBg,
                      value: _selectedSlotId,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('General / No Timetable Slot', style: TextStyle(color: currentText, fontSize: 13)),
                        ),
                        ..._timetableSlots.map((s) {
                          final day = s['day_of_week'] ?? '';
                          final subj = s['subject'] ?? '';
                          final time = s['time_slot'] ?? '';
                          final cls = s['classes']?['name'] ?? 'N/A';
                          return DropdownMenuItem<String?>(
                            value: s['id'],
                            child: Text('$day • $subj ($time) [$cls]', style: TextStyle(color: currentText, fontSize: 13)),
                          );
                        }).toList(),
                      ],
                      onChanged: _onSlotChanged,
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedSlotId == null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select Class: ', style: TextStyle(color: currentText, fontSize: 13)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: cardBg,
                        value: _selectedClassId,
                        items: _classes.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(c['name'] ?? '', style: TextStyle(color: currentText, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedClassId = val);
                            _loadStudents(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              Chip(
                backgroundColor: const Color(0xFF155DFC).withOpacity(0.1),
                label: Text(
                  'Class: ${_timetableSlots.firstWhere((s) => s['id'] == _selectedSlotId)['classes']?['name'] ?? 'N/A'}',
                  style: const TextStyle(color: Color(0xFF155DFC), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _loadingStudents
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? Center(child: Text('No students found in this class.', style: TextStyle(color: currentText)))
                  : Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _students.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final s = _students[index];
                                final currentStatus = _attendanceMap[s['id']] ?? 'Present';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                                        child: Text(
                                          s['full_name'] != null && s['full_name'].isNotEmpty
                                              ? s['full_name'][0].toUpperCase()
                                              : 'S',
                                          style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s['full_name'] ?? '', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text('Roll No: ${s['student_roll_number'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      // Status toggles
                                      Row(
                                        children: ['Present', 'Absent', 'Late'].map((status) {
                                          final isSelected = currentStatus == status;
                                          Color col = Colors.grey;
                                          if (isSelected) {
                                            col = status == 'Present'
                                                ? Colors.green
                                                : status == 'Absent'
                                                    ? Colors.redAccent
                                                    : Colors.orange;
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(left: 4.0),
                                            child: ChoiceChip(
                                              label: Text(status, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : currentText)),
                                              selected: isSelected,
                                              selectedColor: col,
                                              backgroundColor: cardBg,
                                              onSelected: (_) {
                                                setState(() {
                                                  _attendanceMap[s['id']] = status;
                                                });
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                            ),
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submitAttendance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Save Daily Attendance logs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// Sub-tab 2: Homework Manager & Submission Grader
// ----------------------------------------------------
class TeacherHomeworkTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const TeacherHomeworkTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<TeacherHomeworkTab> createState() => _TeacherHomeworkTabState();
}

class _TeacherHomeworkTabState extends State<TeacherHomeworkTab> {
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  List<Map<String, dynamic>> _homeworkList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final list = await DatabaseService.instance.fetchClasses(widget.schoolId);
      setState(() {
        _classes = list;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
          _loadHomework(_selectedClassId!);
        } else {
          _loading = false;
        }
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadHomework(String classId) async {
    setState(() => _loading = true);
    try {
      final list = await DatabaseService.instance.fetchHomework(classId: classId);
      setState(() {
        _homeworkList = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showAssignDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (context) {
        final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

        return AlertDialog(
          backgroundColor: cardBg,
          title: Text('Assign New Homework', style: TextStyle(color: currentText, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Homework Title', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Instructions / Description', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setPickerState) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Due Date: ${selectedDate.toLocal().toString().split(' ')[0]}', style: TextStyle(color: currentText, fontSize: 13)),
                      trailing: const Icon(Icons.calendar_today, color: Color(0xFF4F46E5)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (date != null) {
                          setPickerState(() => selectedDate = date);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final t = titleController.text.trim();
                final d = descController.text.trim();
                if (t.isEmpty || _selectedClassId == null) return;
                
                Navigator.pop(context);
                setState(() => _loading = true);
                
                try {
                  final teacherId = Supabase.instance.client.auth.currentUser?.id ?? '';
                  await DatabaseService.instance.assignHomework(
                    title: t,
                    description: d,
                    dueDate: selectedDate.toIso8601String().split('T')[0],
                    classId: _selectedClassId!,
                    teacherId: teacherId,
                  );
                  _loadHomework(_selectedClassId!);
                } catch (e) {
                  setState(() => _loading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: const Text('Assign', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _viewSubmissions(String homeworkId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeworkGraderScreen(
          homeworkId: homeworkId,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Homework Manager 📁',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
            ),
            ElevatedButton.icon(
              onPressed: _classes.isEmpty ? null : _showAssignDialog,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('New Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Class Selection: ', style: TextStyle(color: currentText, fontSize: 13)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: cardBg,
                  value: _selectedClassId,
                  items: _classes.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(c['name'] ?? '', style: TextStyle(color: currentText, fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedClassId = val);
                      _loadHomework(val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _homeworkList.isEmpty
                  ? Center(child: Text('No homework assigned to this class yet.', style: TextStyle(color: currentText)))
                  : ListView.builder(
                      itemCount: _homeworkList.length,
                      itemBuilder: (context, idx) {
                        final h = _homeworkList[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h['title'] ?? '',
                                      style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      h['description'] ?? 'No description',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Due Date: ${h['due_date'] ?? 'N/A'}',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () => _viewSubmissions(h['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                                  foregroundColor: const Color(0xFF4F46E5),
                                  elevation: 0,
                                ),
                                child: const Text('Submissions', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Sub-screen: Homework submissions and grader list
class HomeworkGraderScreen extends StatefulWidget {
  final String homeworkId;
  final bool isDarkMode;

  const HomeworkGraderScreen({
    super.key,
    required this.homeworkId,
    required this.isDarkMode,
  });

  @override
  State<HomeworkGraderScreen> createState() => _HomeworkGraderScreenState();
}

class _HomeworkGraderScreenState extends State<HomeworkGraderScreen> {
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final list = await DatabaseService.instance.fetchHomeworkSubmissions(widget.homeworkId);
      setState(() {
        _submissions = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _gradeSubmission(Map<String, dynamic> sub) {
    final gradeController = TextEditingController(text: sub['grade'] ?? '');
    final feedbackController = TextEditingController(text: sub['feedback'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

        return AlertDialog(
          backgroundColor: cardBg,
          title: Text('Grade Submission', style: TextStyle(color: currentText, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Student: ${sub['profiles']?['full_name'] ?? 'Unknown'}', style: TextStyle(color: currentText, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: gradeController,
                style: TextStyle(color: currentText, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Grade / Score (e.g. A, 90/100)', labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                style: TextStyle(color: currentText, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Review Feedback', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final g = gradeController.text.trim();
                final f = feedbackController.text.trim();
                Navigator.pop(context);
                setState(() => _loading = true);
                try {
                  await DatabaseService.instance.gradeHomeworkSubmission(
                    submissionId: sub['id'],
                    grade: g,
                    feedback: f,
                  );
                  _loadSubmissions();
                } catch (e) {
                  setState(() => _loading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: const Text('Grade', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF111116) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: widget.isDarkMode ? const Color(0xFF111116) : const Color(0xFFF8FAFC),
        title: Text('Student Submissions', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _submissions.isEmpty
              ? Center(child: Text('No submissions received yet.', style: TextStyle(color: currentText)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _submissions.length,
                  itemBuilder: (context, idx) {
                    final sub = _submissions[idx];
                    final hasGrade = sub['grade'] != null && sub['grade'].isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(sub['profiles']?['full_name'] ?? 'Unknown Student', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasGrade ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hasGrade ? 'Graded: ${sub['grade']}' : 'Awaiting Grading',
                                  style: TextStyle(color: hasGrade ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Submitted Content:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              sub['submission_text'] ?? 'No text provided',
                              style: TextStyle(color: currentText, fontSize: 12, height: 1.4),
                            ),
                          ),
                          if (sub['feedback'] != null && sub['feedback'].isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Feedback: ${sub['feedback']}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _gradeSubmission(sub),
                              icon: const Icon(Icons.grade_rounded, size: 14, color: Colors.white),
                              label: Text(hasGrade ? 'Edit Grade' : 'Grade Submission', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ----------------------------------------------------
// Sub-tab 3: AI Lesson Planner & Note Sharer
// ----------------------------------------------------
class TeacherLessonPlannerTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const TeacherLessonPlannerTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<TeacherLessonPlannerTab> createState() => _TeacherLessonPlannerTabState();
}

class _TeacherLessonPlannerTabState extends State<TeacherLessonPlannerTab> {
  final _plannerController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteContentController = TextEditingController();
  final _subjectController = TextEditingController();

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  bool _loadingClasses = true;
  bool _generatingPlan = false;
  bool _savingNote = false;

  String _generatedPlanText = '';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final list = await DatabaseService.instance.fetchClasses(widget.schoolId);
      setState(() {
        _classes = list;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
        }
        _loadingClasses = false;
      });
    } catch (e) {
      setState(() => _loadingClasses = false);
    }
  }

  Future<void> _generateLessonPlan() async {
    final prompt = _plannerController.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _generatingPlan = true;
      _generatedPlanText = '';
    });

    try {
      // Access backend endpoint for AI Content Creation / Lesson Planning
      final jwtToken = Supabase.instance.client.auth.currentSession?.accessToken;
      const envBackendUrl = String.fromEnvironment('BACKEND_API_URL', defaultValue: 'https://mrivan-ai.onrender.com');

      final res = await http.post(
        Uri.parse('$envBackendUrl/api/ai/tutor/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'message': 'Create a detailed lesson plan with curriculum mapping and learning outcomes for: $prompt. Break down the timing (e.g. 5m intro, 25m core concept, 15m activity, 5m recap).',
          'subject': 'Lesson Planning',
          'gradeLevel': 'Faculty Assistant',
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _generatedPlanText = data['response'] ?? '';
          _noteContentController.text = _generatedPlanText; // preload content editor
        });
      } else {
        throw Exception('API returned status code ${res.statusCode}');
      }
    } catch (e) {
      setState(() {
        _generatedPlanText = 'Error generating lesson plan: $e\n\nFallback structure:\n\n1. **Topic**: $prompt\n2. **Learning Outcomes**: Student will master basic parameters.\n3. **Curriculum Mapping**: Align with Chapter 3 state boards.\n4. **Class Outline**:\n   - 0-10 mins: Hook & Warmup\n   - 10-30 mins: Core Direct Teaching\n   - 30-45 mins: Check for Understanding & Practical examples.';
        _noteContentController.text = _generatedPlanText;
      });
    } finally {
      setState(() => _generatingPlan = false);
    }
  }

  Future<void> _shareNote() async {
    final title = _titleController.text.trim();
    final content = _noteContentController.text.trim();
    final subject = _subjectController.text.trim();
    if (title.isEmpty || content.isEmpty || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Title, Content, and select a target Class.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _savingNote = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No logged in user found');

      final targetClass = _classes.firstWhere((c) => c['id'] == _selectedClassId);
      final className = targetClass['name'] ?? 'Class';

      await DatabaseService.instance.saveClassNote(
        userId: user.id,
        title: title,
        content: content,
        subject: subject.isNotEmpty ? subject : 'General Notes',
        classLevel: className,
        classId: _selectedClassId,
        isAiGenerated: _generatedPlanText.isNotEmpty,
      );

      _titleController.clear();
      _noteContentController.clear();
      _subjectController.clear();
      _plannerController.clear();
      setState(() => _generatedPlanText = '');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study Notes shared successfully with the class!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _savingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    if (_loadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Lesson Planning & Notes Sharer 🤖',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 12),

          // Planner input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Generate detailed Lesson Plan with AI', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _plannerController,
                        style: TextStyle(color: currentText, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Newton\'s 3 Laws of Motion for Grade 9...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _generatingPlan ? null : _generateLessonPlan,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                      child: _generatingPlan
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Generate Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_generatedPlanText.isNotEmpty) ...[
            Text('Generated Plan Preview', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _generatedPlanText,
                style: TextStyle(color: currentText, fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Note sharer editor form
          Text('Edit & Share Notes with Class', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Note Title', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Subject / Area', labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Target Class: ', style: TextStyle(color: currentText, fontSize: 13)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: cardBg,
                          value: _selectedClassId,
                          items: _classes.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['id'],
                              child: Text(c['name'] ?? '', style: TextStyle(color: currentText, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedClassId = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteContentController,
                  maxLines: 8,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Notes Content (Markdown/Text)',
                    labelStyle: TextStyle(color: Colors.grey),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingNote ? null : _shareNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _savingNote
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Share Notes with target class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

// ----------------------------------------------------
// Sub-tab 4: Syllabus Manager
// ----------------------------------------------------
class TeacherSyllabusTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const TeacherSyllabusTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<TeacherSyllabusTab> createState() => _TeacherSyllabusTabState();
}

class _TeacherSyllabusTabState extends State<TeacherSyllabusTab> {
  final _subjectController = TextEditingController();
  final _chapterNameController = TextEditingController();
  final _topicController = TextEditingController();

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  List<Map<String, dynamic>> _syllabusList = [];
  bool _loadingClasses = true;
  bool _loadingSyllabus = false;
  bool _saving = false;

  // Structured syllabus data
  List<Map<String, dynamic>> _chapters = [];
  List<String> _tempTopics = [];
  int? _editingChapterIndex;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _chapterNameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final list = await DatabaseService.instance.fetchClasses(widget.schoolId);
      setState(() {
        _classes = list;
        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
          _loadSyllabus();
        } else {
          _loadingClasses = false;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  Future<void> _loadSyllabus() async {
    if (_selectedClassId == null) return;
    setState(() {
      _loadingSyllabus = true;
    });
    try {
      final list = await DatabaseService.instance.fetchSyllabus(classId: _selectedClassId!);
      setState(() {
        _syllabusList = list;
        _loadingClasses = false;
        _loadingSyllabus = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingClasses = false;
          _loadingSyllabus = false;
        });
      }
    }
  }

  void _addTopic() {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    setState(() {
      if (!_tempTopics.contains(topic)) {
        _tempTopics.add(topic);
      }
      _topicController.clear();
    });
  }

  void _commitChapter() {
    final chName = _chapterNameController.text.trim();
    if (chName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Chapter/Lesson Name.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_tempTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one topic to this chapter.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      final newChapter = {
        'chapter_name': chName,
        'topics': List<String>.from(_tempTopics),
      };

      if (_editingChapterIndex != null) {
        _chapters[_editingChapterIndex!] = newChapter;
        _editingChapterIndex = null;
      } else {
        _chapters.add(newChapter);
      }

      _chapterNameController.clear();
      _topicController.clear();
      _tempTopics.clear();
    });
  }

  Future<void> _saveSyllabus() async {
    final subject = _subjectController.text.trim();
    if (subject.isEmpty || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class and enter a Subject Name.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one chapter/lesson to the syllabus before saving.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final serializedContent = jsonEncode(_chapters);

      await DatabaseService.instance.saveSyllabus(
        schoolId: widget.schoolId,
        classId: _selectedClassId!,
        subject: subject,
        content: serializedContent,
      );

      _subjectController.clear();
      _chapterNameController.clear();
      _topicController.clear();
      setState(() {
        _chapters = [];
        _tempTopics = [];
        _editingChapterIndex = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syllabus saved and published successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadSyllabus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving syllabus: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _editExistingSyllabus(Map<String, dynamic> entry) {
    setState(() {
      _subjectController.text = entry['subject'] ?? '';
      _chapterNameController.clear();
      _topicController.clear();
      _tempTopics.clear();
      _editingChapterIndex = null;

      final rawContent = entry['content'] ?? '';
      try {
        final decoded = jsonDecode(rawContent);
        if (decoded is List) {
          _chapters = List<Map<String, dynamic>>.from(
            decoded.map((x) => Map<String, dynamic>.from(x))
          );
        } else {
          // Fallback for legacy plain text content
          _chapters = [
            {
              'chapter_name': 'General Syllabus Outline',
              'topics': [rawContent],
            }
          ];
        }
      } catch (e) {
        // Fallback for plain text
        _chapters = [
          {
            'chapter_name': 'General Syllabus Outline',
            'topics': [rawContent],
          }
        ];
      }
    });
  }

  Widget _buildSyllabusPreview(String rawContent, Color currentText) {
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is List) {
        final chapters = List<Map<String, dynamic>>.from(
          decoded.map((x) => Map<String, dynamic>.from(x))
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chapters.map((ch) {
            final chName = ch['chapter_name'] ?? '';
            final List topics = ch['topics'] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chName, style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  ...topics.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: currentText, fontSize: 11)),
                        Expanded(child: Text(t.toString(), style: const TextStyle(color: Colors.grey, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            );
          }).toList(),
        );
      }
    } catch (_) {}

    // Fallback plain text layout
    return Text(
      rawContent,
      style: TextStyle(color: currentText, fontSize: 12, height: 1.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    if (_loadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Syllabus Manager 📚',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add or edit class-wise and subject-wise curriculum guidelines.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Editor Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add / Edit Syllabus Entry',
                  style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Target Class: ', style: TextStyle(color: currentText, fontSize: 13)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderCol),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: cardBg,
                          value: _selectedClassId,
                          items: _classes.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['id'],
                              child: Text(c['name'] ?? '', style: TextStyle(color: currentText, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedClassId = val;
                              });
                              _loadSyllabus();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Subject Name (e.g. Mathematics, Science)',
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Structured Chapter/Lesson form section
                Text(
                  _editingChapterIndex != null ? 'Edit Chapter / Lesson' : 'Add Chapter / Lesson',
                  style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _chapterNameController,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Chapter / Lesson Name (e.g. Chapter 1: Fractions)',
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _topicController,
                        style: TextStyle(color: currentText, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Add Topic (e.g. Division of Fractions)',
                          labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addTopic(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTopic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),

                if (_tempTopics.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tempTopics.map((top) {
                      return InputChip(
                        backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.04),
                        label: Text(top, style: TextStyle(color: currentText, fontSize: 11)),
                        onDeleted: () {
                          setState(() {
                            _tempTopics.remove(top);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_editingChapterIndex != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _chapterNameController.clear();
                            _topicController.clear();
                            _tempTopics.clear();
                            _editingChapterIndex = null;
                          });
                        },
                        child: const Text('Cancel Edit', style: TextStyle(color: Colors.grey)),
                      ),
                    ElevatedButton.icon(
                      onPressed: _commitChapter,
                      icon: const Icon(Icons.playlist_add_rounded, size: 18, color: Colors.white),
                      label: Text(_editingChapterIndex != null ? 'Update Chapter' : 'Add Chapter to Syllabus', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Committed chapters preview list
                if (_chapters.isNotEmpty) ...[
                  Text('Syllabus Chapters Added So Far:', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _chapters.length,
                    itemBuilder: (context, index) {
                      final ch = _chapters[index];
                      final List topics = ch['topics'] ?? [];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.01),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ch['chapter_name'] ?? '', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: topics.map((t) => Chip(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(color: borderCol),
                                      label: Text(t.toString(), style: const TextStyle(fontSize: 10)),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                  onPressed: () {
                                    setState(() {
                                      _chapterNameController.text = ch['chapter_name'] ?? '';
                                      _tempTopics = List<String>.from(ch['topics'] ?? []);
                                      _editingChapterIndex = index;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _chapters.removeAt(index);
                                      if (_editingChapterIndex == index) {
                                        _editingChapterIndex = null;
                                        _chapterNameController.clear();
                                        _tempTopics.clear();
                                      } else if (_editingChapterIndex != null && _editingChapterIndex! > index) {
                                        _editingChapterIndex = _editingChapterIndex! - 1;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveSyllabus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save & Publish Syllabus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Syllabus List Section
          Text(
            'Existing Syllabus Guidelines',
            style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _loadingSyllabus
              ? const Center(child: CircularProgressIndicator())
              : _syllabusList.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.05)),
                      ),
                      child: Center(
                        child: Text(
                          'No syllabus entries found for this class.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _syllabusList.length,
                      itemBuilder: (context, idx) {
                        final entry = _syllabusList[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderCol),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry['subject'] ?? '',
                                    style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF4F46E5)),
                                    label: const Text('Edit', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12)),
                                    onPressed: () => _editExistingSyllabus(entry),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _buildSyllabusPreview(entry['content'] ?? '', currentText),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

