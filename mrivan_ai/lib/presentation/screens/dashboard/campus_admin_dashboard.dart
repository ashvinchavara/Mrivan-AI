import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../data/services/database_service.dart';
import '../../theme/theme_config.dart';
import '../../widgets/animated_background.dart';

class CampusAdminDashboard extends StatefulWidget {
  final String userName;
  final String schoolId;
  final String email;

  const CampusAdminDashboard({
    super.key,
    required this.userName,
    required this.schoolId,
    required this.email,
  });

  @override
  State<CampusAdminDashboard> createState() => _CampusAdminDashboardState();
}

class _CampusAdminDashboardState extends State<CampusAdminDashboard> {
  int _currentIndex = 0;
  final SupabaseClient _client = Supabase.instance.client;

  List<String> get _tabs => [
    'Admin Cockpit',
    'Manage Teachers',
    'Manage Students',
    'Manage Classes',
    'Manage Timetable',
    'Placement Analytics',
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

    final initialText = widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'A';

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
            currentScreen = AdminCockpitTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 1:
            currentScreen = AdminManageTeachersTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 2:
            currentScreen = AdminManageStudentsTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 3:
            currentScreen = AdminManageClassesTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 4:
            currentScreen = AdminManageTimetableTab(
              schoolId: widget.schoolId,
              isDarkMode: isDarkMode,
            );
            break;
          case 5:
            currentScreen = AdminPlacementTab(isDarkMode: isDarkMode);
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
                        child: Container(
                          color: const Color(0xFF155DFC),
                          width: 30,
                          height: 30,
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Admin Dashboard',
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
                                backgroundColor: const Color(0xFF155DFC),
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
                              title: Text(_tabs[idx], style: TextStyle(color: _currentIndex == idx ? const Color(0xFF155DFC) : currentText)),
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
                              child: Container(
                                color: const Color(0xFF155DFC),
                                width: 36,
                                height: 36,
                                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'CAMPUS ADMIN',
                              style: TextStyle(
                                fontSize: 16,
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
                                color: isSelected ? const Color(0xFF155DFC).withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                  leading: Icon(
                                    idx == 0
                                        ? Icons.space_dashboard_rounded
                                        : idx == 1
                                            ? Icons.badge_rounded
                                            : idx == 2
                                                ? Icons.groups_rounded
                                                : idx == 3
                                                    ? Icons.school_rounded
                                                    : idx == 4
                                                        ? Icons.calendar_month_rounded
                                                        : idx == 5
                                                            ? Icons.assessment_rounded
                                                            : Icons.analytics_rounded,
                                    color: isSelected ? const Color(0xFF155DFC) : Colors.grey,
                                  ),
                                title: Text(
                                  _tabs[idx],
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF155DFC) : currentText,
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
                              backgroundColor: const Color(0xFF155DFC),
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
                                  const Text('Administrator', style: TextStyle(color: Colors.grey, fontSize: 10)),
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
                  selectedItemColor: const Color(0xFF155DFC),
                  unselectedItemColor: Colors.grey,
                  currentIndex: _currentIndex,
                  onTap: (idx) => setState(() => _currentIndex = idx),
                  type: BottomNavigationBarType.fixed,
                  items: [
                    const BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_rounded), label: 'Dashboard'),
                    const BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Teachers'),
                    const BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Students'),
                    const BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Classes'),
                    const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Timetable'),
                    const BottomNavigationBarItem(icon: Icon(Icons.assessment_rounded), label: 'Placements'),
                  ],
                )
              : null,
        );
      },
    );
  }
}

// ----------------------------------------------------
// Sub-tab 0: Admin Cockpit Overview & Invite Code
// ----------------------------------------------------
class AdminCockpitTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const AdminCockpitTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<AdminCockpitTab> createState() => _AdminCockpitTabState();
}

class _AdminCockpitTabState extends State<AdminCockpitTab> {
  bool _loading = true;
  String _schoolName = 'Loading school...';
  String _inviteCode = '------';
  int _totalSeats = 0;
  int _teachersCount = 0;
  int _studentsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final school = await DatabaseService.instance.fetchSchoolData(widget.schoolId);
      final teachers = await DatabaseService.instance.fetchSchoolTeachers(widget.schoolId);
      final students = await DatabaseService.instance.fetchSchoolStudents(widget.schoolId);

      setState(() {
        if (school != null) {
          _schoolName = school['name'] ?? 'Mrivan Campus';
          _inviteCode = school['invite_code'] ?? 'N/A';
          _totalSeats = school['total_seats'] ?? 0;
        }
        _teachersCount = teachers.length;
        _studentsCount = students.length;
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

    final occupiedSeats = _studentsCount + _teachersCount;
    final seatPercentage = _totalSeats > 0 ? (occupiedSeats / _totalSeats) : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _schoolName,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: currentText, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          const Text('Campus cockpit command center. Manage students, configure faculty quotas, and monitor placement pipelines.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),

          // Invite Code & Seats utilization row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                children: [
                  // Invite Code Card
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: EdgeInsets.only(bottom: isWide ? 0 : 16, right: isWide ? 16 : 0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF155DFC), Color(0xFF1A1AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('CAMPUS REGISTRATION CODE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              Icon(Icons.vpn_key_rounded, color: Colors.white70, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            _inviteCode,
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Share this code with your students and teachers to grant campus portal access.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Seats utilization Card
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('SEATS & LICENSE UTILIZATION', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              Icon(Icons.pie_chart_rounded, color: const Color(0xFF155DFC), size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$occupiedSeats / $_totalSeats Licenses Used', style: TextStyle(color: currentText, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('${(seatPercentage * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF155DFC), fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: seatPercentage,
                              minHeight: 10,
                              backgroundColor: Colors.grey.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF155DFC)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Teachers and students consume 1 seat license respectively.', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Metric Bento Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _buildStatCard('Enrolled Students', '$_studentsCount', 'Fully onboarded campus learners', const Color(0xFF00F2FE), Icons.groups_rounded, cardBg, currentText),
              _buildStatCard('Registered Teachers', '$_teachersCount', 'Faculty advisors inside workspace', const Color(0xFF6C63FF), Icons.badge_rounded, cardBg, currentText),
              _buildStatCard('Engagement Index', '91.8%', 'Active student query resolution rate', const Color(0xFFFF2A6D), Icons.analytics_rounded, cardBg, currentText),
            ],
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
// Sub-tab 1: Manage Teachers
// ----------------------------------------------------
class AdminManageTeachersTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const AdminManageTeachersTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<AdminManageTeachersTab> createState() => _AdminManageTeachersTabState();
}

class _AdminManageTeachersTabState extends State<AdminManageTeachersTab> {
  List<Map<String, dynamic>> _teachers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      final list = await DatabaseService.instance.fetchSchoolTeachers(widget.schoolId);
      setState(() {
        _teachers = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showAddTeacherDialog() {
    // Add mock educator data or explain the Invite Code flow
    showDialog(
      context: context,
      builder: (context) {
        final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

        return AlertDialog(
          backgroundColor: cardBg,
          title: Text('Invite Faculty Member', style: TextStyle(color: currentText, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mrivan Campus uses registration codes to onboard new users dynamically. New teachers should sign up using the Campus Code on the landing page.',
                style: TextStyle(color: currentText, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'On the onboarding card, select the "Join with Code" option, toggle "Teacher", enter the 6-digit campus code, specify the teacher\'s subject specialization, and complete onboarding.',
                style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF155DFC)),
              child: const Text('Got It', style: TextStyle(color: Colors.white)),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Manage Teachers 🎓',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
            ),
            ElevatedButton.icon(
              onPressed: _showAddTeacherDialog,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Add Faculty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF155DFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _teachers.isEmpty
                  ? Center(child: Text('No teachers registered yet.', style: TextStyle(color: currentText)))
                  : ListView.builder(
                      itemCount: _teachers.length,
                      itemBuilder: (context, idx) {
                        final t = _teachers[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF155DFC).withOpacity(0.1),
                                child: Text(
                                  t['full_name'] != null && t['full_name'].isNotEmpty
                                      ? t['full_name'][0].toUpperCase()
                                      : 'T',
                                  style: const TextStyle(color: Color(0xFF155DFC), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t['full_name'] ?? 'Faculty Member', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('Specialization: ${t['teacher_specialization'] ?? 'General Instruction'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('Email: ${t['email'] ?? 'N/A'} | Phone: ${t['phone_number'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
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

// ----------------------------------------------------
// Sub-tab 2: Manage Students
// ----------------------------------------------------
class AdminManageStudentsTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const AdminManageStudentsTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<AdminManageStudentsTab> createState() => _AdminManageStudentsTabState();
}

class _AdminManageStudentsTabState extends State<AdminManageStudentsTab> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final list = await DatabaseService.instance.fetchSchoolStudents(widget.schoolId);
      setState(() {
        _students = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Students 👥',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? Center(child: Text('No students registered yet.', style: TextStyle(color: currentText)))
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, idx) {
                        final s = _students[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF155DFC).withOpacity(0.1),
                                child: Text(
                                  s['full_name'] != null && s['full_name'].isNotEmpty
                                      ? s['full_name'][0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(color: Color(0xFF155DFC), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(s['full_name'] ?? 'Student', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: const Color(0xFF155DFC).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text('Class: ${s['class'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF155DFC), fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Roll Number: ${s['student_roll_number'] ?? 'N/A'} | Age: ${s['age'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text('Email: ${s['email'] ?? 'N/A'} | Phone: ${s['phone_number'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
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

// ----------------------------------------------------
// Sub-tab 3: Placement Analytics
// ----------------------------------------------------
class AdminPlacementTab extends StatelessWidget {
  final bool isDarkMode;

  const AdminPlacementTab({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final currentText = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDarkMode ? const Color(0xFF181824) : Colors.white;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Placement Analytics 💼',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 6),
          const Text('Track recruitment success, resume scores, and placement stats.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),

          // Placements bento stats
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _buildStatsCard('Ready for Jobs', '84%', 'Students with readiness index >= 75%', const Color(0xFF6C63FF), Icons.work_outline_rounded, cardBg, currentText),
              _buildStatsCard('Average ATS Score', '74.5', 'Out of 100 overall resume score', const Color(0xFF00F2FE), Icons.assignment_turned_in_rounded, cardBg, currentText),
              _buildStatsCard('Offers Generated', '12', 'Offers registered in job matching logs', const Color(0xFFFF2A6D), Icons.stars_rounded, cardBg, currentText),
            ],
          ),
          const SizedBox(height: 24),

          // Pipeline
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Technical Mock HR Interview Pipelines', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 16),
                _buildJobItem('Full Stack Developer', '4 student matching logs found', 'High Readiness Sync', Colors.green, isDarkMode),
                const Divider(),
                _buildJobItem('Data Science Intern', '2 student matching logs found', 'Medium Readiness Sync', Colors.blue, isDarkMode),
                const Divider(),
                _buildJobItem('Product Manager', '1 student matching log found', 'High Readiness Sync', Colors.green, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, String desc, Color color, IconData icon, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildJobItem(String title, String subText, String badge, Color badgeCol, bool isDark) {
    final currentText = isDark ? Colors.white : const Color(0xFF0F172A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subText, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeCol.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(badge, style: TextStyle(color: badgeCol, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


// ----------------------------------------------------
// Sub-tab 3: Manage Classes
// ----------------------------------------------------
class AdminManageClassesTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const AdminManageClassesTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<AdminManageClassesTab> createState() => _AdminManageClassesTabState();
}

class _AdminManageClassesTabState extends State<AdminManageClassesTab> {
  final _classNameController = TextEditingController();
  final _roomNumberController = TextEditingController();

  List<Map<String, dynamic>> _classes = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _loading = true);
    try {
      final list = await DatabaseService.instance.fetchClasses(widget.schoolId);
      setState(() {
        _classes = list;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading classes: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createClass() async {
    final name = _classNameController.text.trim();
    final room = _roomNumberController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Class Name.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await DatabaseService.instance.createClass(
        schoolId: widget.schoolId,
        name: name,
        roomNumber: room.isNotEmpty ? room : null,
      );

      _classNameController.clear();
      _roomNumberController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _loadClasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating class: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteClass(String classId) async {
    try {
      await DatabaseService.instance.deleteClass(classId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class deleted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadClasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting class: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage School Classes 🏫',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
                ),
                const SizedBox(height: 4),
                const Text('Create and manage classrooms/sections for student enrollment.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF155DFC)),
              onPressed: _loadClasses,
              tooltip: 'Refresh Classes',
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Add Class Form Card
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
              Text('Create New Class / Section', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _classNameController,
                      style: TextStyle(color: currentText, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Class Name (e.g. 10A, 11B)',
                        labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _roomNumberController,
                      style: TextStyle(color: currentText, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Room Number (Optional)',
                        labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF155DFC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Classes list header
        Text('Active Classes & Classrooms', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _classes.isEmpty
                  ? Center(child: Text('No classes registered yet. Create one above to get started.', style: TextStyle(color: currentText, fontSize: 13)))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.8,
                      ),
                      itemCount: _classes.length,
                      itemBuilder: (context, idx) {
                        final cls = _classes[idx];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderCol),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF155DFC).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.class_rounded, color: Color(0xFF155DFC), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(cls['name'] ?? '', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (cls['room_number'] != null && (cls['room_number'] as String).isNotEmpty)
                                      Text('Room: ${cls['room_number']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: cardBg,
                                      title: Text('Delete Class', style: TextStyle(color: currentText, fontWeight: FontWeight.bold)),
                                      content: Text('Are you sure you want to delete class ${cls['name']}? This will unenroll all students in this class.', style: TextStyle(color: currentText, fontSize: 13)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteClass(cls['id']);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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

class AdminManageTimetableTab extends StatefulWidget {
  final String schoolId;
  final bool isDarkMode;

  const AdminManageTimetableTab({
    super.key,
    required this.schoolId,
    required this.isDarkMode,
  });

  @override
  State<AdminManageTimetableTab> createState() => _AdminManageTimetableTabState();
}

class _AdminManageTimetableTabState extends State<AdminManageTimetableTab> {
  final _subjectController = TextEditingController();
  final _timeSlotController = TextEditingController();

  List<Map<String, dynamic>> _timetable = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _teachers = [];

  String? _selectedClassId;
  String? _selectedTeacherId;
  String _selectedDay = 'Monday';

  bool _loading = true;
  bool _saving = false;
  bool _isUploadingTimetable = false;
  bool _useAiParser = true;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _timeSlotController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    try {
      final classesList = await DatabaseService.instance.fetchClasses(widget.schoolId);
      final teachersList = await DatabaseService.instance.fetchSchoolTeachers(widget.schoolId);
      final timetableList = await DatabaseService.instance.fetchTimetable(widget.schoolId);

      setState(() {
        _classes = classesList;
        _teachers = teachersList;
        _timetable = timetableList;

        if (_classes.isNotEmpty) {
          _selectedClassId = _classes.first['id'];
        }
        if (_teachers.isNotEmpty) {
          _selectedTeacherId = _teachers.first['id'];
        }
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading timetable data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveTimetableEntry() async {
    final subject = _subjectController.text.trim();
    final timeSlot = _timeSlotController.text.trim();

    if (_selectedClassId == null || _selectedTeacherId == null || subject.isEmpty || timeSlot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class, select a teacher, and fill in subject & time slot.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await DatabaseService.instance.saveTimetableEntry(
        schoolId: widget.schoolId,
        classId: _selectedClassId!,
        teacherId: _selectedTeacherId!,
        subject: subject,
        dayOfWeek: _selectedDay,
        timeSlot: timeSlot,
      );

      _subjectController.clear();
      _timeSlotController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timetable entry saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reload
      final timetableList = await DatabaseService.instance.fetchTimetable(widget.schoolId);
      setState(() {
        _timetable = timetableList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTimetableEntry(String id) async {
    try {
      await DatabaseService.instance.deleteTimetableEntry(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timetable entry deleted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Reload
      final timetableList = await DatabaseService.instance.fetchTimetable(widget.schoolId);
      setState(() {
        _timetable = timetableList;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Pick a PDF or TXT timetable file, send to backend, bulk-save parsed entries.
  Future<void> _pickAndParseTimetableFile() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class before uploading a timetable.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileBytes = file.bytes;
      if (fileBytes == null) throw Exception('Failed to read file content');

      setState(() => _isUploadingTimetable = true);

      final jwtToken = Supabase.instance.client.auth.currentSession?.accessToken;
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );

      final request = http.MultipartRequest('POST', Uri.parse('$envBackendUrl/api/ai/timetable/parse'));
      if (jwtToken != null) request.headers['Authorization'] = 'Bearer $jwtToken';
      request.headers['Bypass-Tunnel-Reminder'] = 'true';
      request.files.add(http.MultipartFile.fromBytes('timetable', fileBytes, filename: file.name));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        String errMsg = 'Server returned status ${response.statusCode}';
        try {
          final errBody = jsonDecode(response.body);
          errMsg = errBody['error'] ?? errMsg;
        } catch (_) {}
        throw Exception(errMsg);
      }

      final List parsedEntries = jsonDecode(response.body);

      final classId = _selectedClassId!;

      int saved = 0;
      for (final entry in parsedEntries) {
        if (entry is! Map) continue;
        final day = entry['day_of_week']?.toString() ?? '';
        final subject = entry['subject']?.toString() ?? '';
        final timeSlot = entry['time_slot']?.toString() ?? '';
        final teacherName = entry['teacher_name']?.toString() ?? '';

        if (day.isEmpty || subject.isEmpty) continue;

        // Try to match teacher by name
        String teacherId;
        if (teacherName.isNotEmpty) {
          final matchedTeacher = _teachers.firstWhere(
            (t) => (t['full_name'] ?? '').toString().toLowerCase().contains(teacherName.toLowerCase()),
            orElse: () => _teachers.isNotEmpty ? _teachers.first : {},
          );
          teacherId = matchedTeacher['id'] as String? ?? '';
        } else {
          teacherId = _teachers.isNotEmpty ? (_teachers.first['id'] as String? ?? '') : '';
        }
        if (teacherId.isEmpty) continue;

        try {
          await DatabaseService.instance.saveTimetableEntry(
            schoolId: widget.schoolId,
            classId: classId,
            teacherId: teacherId,
            subject: subject,
            dayOfWeek: day,
            timeSlot: timeSlot.isNotEmpty ? timeSlot : 'TBD',
          );
          saved++;
        } catch (_) {}
      }

      // Reload
      final updated = await DatabaseService.instance.fetchTimetable(widget.schoolId);
      setState(() => _timetable = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $saved timetable entries imported successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Timetable parse error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import timetable: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingTimetable = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Group timetable by day
    final Map<String, List<Map<String, dynamic>>> groupedTimetable = {};
    for (final day in _daysOfWeek) {
      groupedTimetable[day] = _timetable.where((t) => t['day_of_week'] == day).toList();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timetable Management 📅',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload and configure class schedules, teacher assignments, and period timings.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── Timetable Configuration Card (AI & Manual Combined) ──────────────────────────
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
                  'Configure Timetable',
                  style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 14),

                // Class Dropdown Selector
                Text('Target Class', style: TextStyle(color: currentText, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: cardBg,
                      value: _selectedClassId,
                      isExpanded: true,
                      hint: Text('Choose Class', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      items: _classes.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id'],
                          child: Text(c['name'] ?? 'N/A', style: TextStyle(color: currentText, fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedClassId = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle between AI Importer and Manual Entry
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _useAiParser = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _useAiParser
                                ? const Color(0xFF155DFC)
                                : (widget.isDarkMode ? Colors.white24 : Colors.black12),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            border: Border.all(color: borderCol),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: _useAiParser ? Colors.white : currentText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'AI Parser Import',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _useAiParser ? Colors.white : currentText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _useAiParser = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_useAiParser
                                ? const Color(0xFF155DFC)
                                : (widget.isDarkMode ? Colors.white24 : Colors.black12),
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            border: Border.all(color: borderCol),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 14,
                                  color: !_useAiParser ? Colors.white : currentText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Manual Entry',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !_useAiParser ? Colors.white : currentText,
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
                const SizedBox(height: 16),

                // Conditionally display selected flow
                if (_useAiParser) ...[
                  const Text(
                    'Upload a PDF or TXT timetable file. AI will extract all periods, subjects and time slots automatically.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  if (_isUploadingTimetable)
                    const Row(
                      children: [
                        SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF155DFC))),
                        ),
                        SizedBox(width: 10),
                        Text('Uploading and parsing timetable...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _pickAndParseTimetableFile,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white),
                      label: const Text('Upload PDF / TXT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF155DFC),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                ] else ...[
                  // Day of Week
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day of Week', style: TextStyle(color: currentText, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderCol),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: cardBg,
                            value: _selectedDay,
                            isExpanded: true,
                            items: _daysOfWeek.map((day) {
                              return DropdownMenuItem<String>(
                                value: day,
                                child: Text(day, style: TextStyle(color: currentText, fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDay = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Teacher Dropdown
                  Text('Teacher', style: TextStyle(color: currentText, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderCol),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: cardBg,
                        value: _selectedTeacherId,
                        isExpanded: true,
                        items: _teachers.map((t) {
                          final name = t['full_name'] ?? 'N/A';
                          final spec = t['teacher_specialization'] ?? '';
                          return DropdownMenuItem<String>(
                            value: t['id'],
                            child: Text(
                              spec.isNotEmpty ? '$name ($spec)' : name,
                              style: TextStyle(color: currentText, fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedTeacherId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subject and Time Slot Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subjectController,
                          style: TextStyle(color: currentText, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Subject (e.g. Mathematics)',
                            labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _timeSlotController,
                          style: TextStyle(color: currentText, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Time Slot (e.g. 09:00 AM - 10:00 AM)',
                            labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveTimetableEntry,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Add to Timetable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155DFC),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Timetable List grouping
          Text(
            'Weekly Schedule Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 12),

          ..._daysOfWeek.map((day) {
            final daySlots = groupedTimetable[day] ?? [];
            if (daySlots.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  day,
                  style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                children: daySlots.map((slot) {
                  final cls = slot['classes']?['name'] ?? 'N/A';
                  final teacher = slot['profiles']?['full_name'] ?? 'N/A';
                  final subj = slot['subject'] ?? '';
                  final time = slot['time_slot'] ?? '';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.access_time_rounded, color: Color(0xFF155DFC)),
                    title: Text(
                      '$subj (Class: $cls)',
                      style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      'Timing: $time • Instructor: $teacher',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: cardBg,
                            title: Text('Delete Timetable Slot', style: TextStyle(color: currentText, fontWeight: FontWeight.bold)),
                            content: Text('Are you sure you want to delete this class schedule?', style: TextStyle(color: currentText, fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteTimetableEntry(slot['id']);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),

          if (_timetable.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'No timetable slots configured yet. Add one using the form above!',
                      style: TextStyle(color: currentText, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

