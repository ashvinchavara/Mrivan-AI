import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';
import '../../../data/services/database_service.dart';

// Sub-feature screens
import '../student/ai_tutor_screen.dart';
import '../student/student_homework_screen.dart';
import '../teacher/attendance_grid_screen.dart';
import '../teacher/homework_manager_screen.dart';
import '../common/ai_notes_screen.dart';

class DashboardRouter extends StatefulWidget {
  const DashboardRouter({super.key});

  @override
  State<DashboardRouter> createState() => _DashboardRouterState();
}

class _DashboardRouterState extends State<DashboardRouter> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isDarkMode = false;
  bool _isLoadingProfile = true;
  String? _userRole;
  String? _userName;
  String? schoolId;
  String? classId;

  // Student Attendance list state
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoadingAttendance = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Fetch the logged-in user profile from Supabase
  Future<void> _loadUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingProfile = true;
    });

    try {
      // 1. Get role and profiles details
      final response = await _client
          .from('profiles')
          .select('role, full_name, school_id, class_id')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _userRole = response['role'] as String?;
          _userName = response['full_name'] as String?;
          schoolId = response['school_id'] as String?;
          classId = response['class_id'] as String?;
        });
        
        // 2. Proactively load data based on user role (e.g. attendance for students)
        if (_userRole == 'student') {
          _loadStudentAttendance(user.id);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  // Load student attendance logs
  Future<void> _loadStudentAttendance(String studentId) async {
    setState(() {
      _isLoadingAttendance = true;
    });
    try {
      final data = await DatabaseService.instance.fetchAttendance(studentId: studentId);
      setState(() {
        _attendanceRecords = data;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading attendance: $e');
      }
    } finally {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  // Sign out handler
  Future<void> _handleSignOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        isDarkMode: _isDarkMode,
        child: Stack(
          children: [
            // 1. Dashboard Top Header Panel
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: _isDarkMode ? Colors.black26 : Colors.white24,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App Brand Logo
                        Row(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              color: const Color(0xFF155DFC),
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mrivan AI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),

                        // Actions: Theme Switcher & Logout
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                                color: _isDarkMode ? Colors.amber : Colors.indigo,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isDarkMode = !_isDarkMode;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                              onPressed: _handleSignOut,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Main Dashboard Panel View
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 80,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _isLoadingProfile
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF155DFC)),
                          ),
                        )
                      : _buildRoleDashboard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Renders the specific dashboard layout based on the loaded user role
  Widget _buildRoleDashboard() {
    if (_userRole == 'student') {
      return _buildStudentDashboard();
    } else if (_userRole == 'teacher') {
      return _buildTeacherDashboard();
    } else if (_userRole == 'admin') {
      return _buildAdminDashboard();
    } else if (_userRole == 'parent') {
      return _buildParentDashboard();
    } else {
      return _buildPendingDashboard();
    }
  }

  // A. Student Dashboard View
  Widget _buildStudentDashboard() {
    final presentCount = _attendanceRecords.where((r) => r['status'] == 'present').length;
    final totalCount = _attendanceRecords.length;
    final attendanceRate = totalCount > 0 ? (presentCount / totalCount * 100).toStringAsFixed(1) : '100.0';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Student Welcome frosted card
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $_userName 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access your subjects, attendance history, and AI tutor helper.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats & AI Tutor Widget Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  // Attendance stats card
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Registry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$attendanceRate%',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode ? Colors.greenAccent : Colors.green,
                              ),
                            ),
                            Text(
                              '$presentCount / $totalCount Days',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: _isDarkMode ? Colors.white54 : Colors.black45),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _isLoadingAttendance
                            ? const LinearProgressIndicator()
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),

                  // Open AI Tutor Launcher card
                  _buildGlassCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AITutorScreen(isDarkMode: _isDarkMode),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 36,
                          color: const Color(0xFF155DFC),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start AI Tutor Chat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Let Mr. Ivan AI guide your homework concepts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Homework list card
                  _buildGlassCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentHomeworkScreen(
                            isDarkMode: _isDarkMode,
                            classId: classId,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 36,
                          color: _isDarkMode ? Colors.orangeAccent : Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'My Homework Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View class assignments and submit solutions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // AI Notes card
                  _buildGlassCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AINotesScreen(isDarkMode: _isDarkMode),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories_outlined,
                          size: 36,
                          color: _isDarkMode ? Colors.lightBlueAccent : Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'AI Study Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate customized syllabus study outlines.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // B. Teacher Dashboard View
  Widget _buildTeacherDashboard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Console - Welcome, $_userName',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your classes, log student attendance, and assign homework.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: ListView(
                children: [
                  _buildListCard(
                    title: 'Record Attendance Grid',
                    subtitle: 'Roll call students for active classrooms',
                    icon: Icons.checklist_rtl_rounded,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceGridScreen(
                            isDarkMode: _isDarkMode,
                            schoolId: schoolId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildListCard(
                    title: 'Homework & Assignments',
                    subtitle: 'Publish tasks and grade submissions',
                    icon: Icons.assignment_rounded,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeworkManagerScreen(
                            isDarkMode: _isDarkMode,
                            schoolId: schoolId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildListCard(
                    title: 'AI Helper Tools',
                    subtitle: 'Generate notes outlines and quizzes',
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFF155DFC),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AINotesScreen(
                            isDarkMode: _isDarkMode,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // C. Admin Dashboard View
  Widget _buildAdminDashboard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure school tenants, assign user roles, and check analytics.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard('Total Users', '140', Icons.people_alt_rounded),
                  _buildStatCard('Classrooms', '12', Icons.meeting_room_rounded),
                  _buildStatCard('Attendance Rate', '94.2%', Icons.trending_up_rounded),
                  _buildStatCard('AI Queries Today', '1,420', Icons.bolt_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // D. Parent Dashboard View
  Widget _buildParentDashboard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parent Portal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monitor your child\'s school attendance records and performance metrics.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.child_care_rounded, color: _isDarkMode ? Colors.white : Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        'Student Child Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('No child accounts are currently linked. Please contact your school administrator to link your profile.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // E. Pending Approval Dashboard View
  Widget _buildPendingDashboard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: _buildGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 60,
                color: _isDarkMode ? Colors.amberAccent : Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                'Approval Pending',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your account registration was successful. Please wait for a School Administrator to assign your profile role (Student, Teacher, or Parent) and school association.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 40),
                ),
                child: const Text('Refresh Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Frosted Card Builder Helper
  Widget _buildGlassCard({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.3),
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

  // List Item Card Helper
  Widget _buildListCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return _buildGlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDarkMode ? Colors.white54 : Colors.black54,
                  ),
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
    );
  }

  // Stat Card Builder Helper
  Widget _buildStatCard(String title, String val, IconData icon) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF155DFC), size: 24),
          const Spacer(),
          Text(
            val,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
