import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';
import '../../../data/services/database_service.dart';

class AttendanceGridScreen extends StatefulWidget {
  final bool isDarkMode;
  final String? schoolId;
  const AttendanceGridScreen({super.key, required this.isDarkMode, this.schoolId});

  @override
  State<AttendanceGridScreen> createState() => _AttendanceGridScreenState();
}

class _AttendanceGridScreenState extends State<AttendanceGridScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late bool _isDarkMode;

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendanceMap = {}; // Maps studentId -> status ('present', 'absent', etc.)

  DateTime _selectedDate = DateTime.now();
  bool _isLoadingClasses = false;
  bool _isLoadingStudents = false;
  bool _isSaving = false;

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
          _loadStudents(_selectedClassId!);
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

  Future<void> _loadStudents(String classId) async {
    setState(() {
      _isLoadingStudents = true;
      _students = [];
      _attendanceMap = {};
    });

    try {
      final students = await DatabaseService.instance.fetchStudentsInClass(classId);
      setState(() {
        _students = students;
        for (var student in students) {
          _attendanceMap[student['id']] = 'present'; // Default to present
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error loading students: $e');
    } finally {
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_selectedClassId == null || widget.schoolId == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final records = _attendanceMap.entries.map((entry) => {
        'student_id': entry.key,
        'status': entry.value,
      }).toList();

      await DatabaseService.instance.recordAttendanceBulk(
        schoolId: widget.schoolId!,
        classId: _selectedClassId!,
        date: formattedDate,
        records: records,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (kDebugMode) print('Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

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
                              Icon(Icons.checklist_rtl_rounded, color: _isDarkMode ? Colors.tealAccent : Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                'Record Attendance',
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

            // 2. Main content container
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
                          // Selectors bar
                          _buildGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Class dropdown
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
                                                labelText: 'Class',
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
                                                  _loadStudents(val);
                                                }
                                              },
                                            ),
                                ),
                                const SizedBox(width: 16),

                                // Date Picker Button
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _isDarkMode ? Colors.white30 : Colors.black26),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_month_rounded, color: _isDarkMode ? Colors.white70 : Colors.black54),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateString,
                                          style: TextStyle(
                                            color: _isDarkMode ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Students list
                          Expanded(
                            child: _isLoadingStudents
                                ? const Center(child: CircularProgressIndicator())
                                : _students.isEmpty
                                    ? _buildGlassCard(
                                        padding: const EdgeInsets.all(24),
                                        child: Center(
                                          child: Text(
                                            'No students registered in this class.',
                                            style: TextStyle(
                                              color: _isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _buildGlassCard(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          itemCount: _students.length,
                                          itemBuilder: (context, index) {
                                            final student = _students[index];
                                            final studentId = student['id'];
                                            final currentStatus = _attendanceMap[studentId] ?? 'present';

                                            return Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      // Name and Roll No.
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              student['full_name'] ?? 'Unknown Student',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 15,
                                                                color: _isDarkMode ? Colors.white : Colors.black87,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              "Roll No: ${student['student_roll_number'] ?? 'N/A'}",
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: _isDarkMode ? Colors.white54 : Colors.black54,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Attendance capsules
                                                      Row(
                                                        children: [
                                                          _buildStatusCapsule('present', 'Present', Colors.green, currentStatus == 'present', studentId),
                                                          const SizedBox(width: 6),
                                                          _buildStatusCapsule('absent', 'Absent', Colors.redAccent, currentStatus == 'absent', studentId),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (index < _students.length - 1)
                                                  Divider(color: _isDarkMode ? Colors.white12 : Colors.black12),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                          ),
                          const SizedBox(height: 16),

                          // Submit Button
                          if (_students.isNotEmpty)
                            _isSaving
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _submitAttendance,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 50),
                                      backgroundColor: _isDarkMode ? Colors.tealAccent.shade700 : Colors.teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text(
                                      'Save & Submit Attendance',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildStatusCapsule(String status, String label, Color activeColor, bool isActive, String studentId) {
    return InkWell(
      onTap: () {
        setState(() {
          _attendanceMap[studentId] = status;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? activeColor.withValues(alpha: 0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : (_isDarkMode ? Colors.white24 : Colors.black26),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : (_isDarkMode ? Colors.white70 : Colors.black54),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
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
