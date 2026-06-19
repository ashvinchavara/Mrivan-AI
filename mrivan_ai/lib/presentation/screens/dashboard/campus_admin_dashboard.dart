import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
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
    'Placement Analytics',
    'Campus Reports',
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
            currentScreen = AdminPlacementTab(isDarkMode: isDarkMode);
            break;
          case 4:
            currentScreen = AdminReportsTab(isDarkMode: isDarkMode);
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
                  items: [
                    const BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_rounded), label: 'Dashboard'),
                    const BottomNavigationBarItem(icon: Icon(Icons.badge_rounded), label: 'Teachers'),
                    const BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Students'),
                    const BottomNavigationBarItem(icon: Icon(Icons.assessment_rounded), label: 'Placements'),
                    const BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
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
// Sub-tab 4: Campus Reports
// ----------------------------------------------------
class AdminReportsTab extends StatelessWidget {
  final bool isDarkMode;

  const AdminReportsTab({
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
            'Campus Reports & Logs 📊',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 6),
          const Text('Compile audit logs, download class progress reports, or analyze student usage stats.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),

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
                Text('Generate Automated Reports', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 16),
                _buildReportDownloadItem('Monthly Student Attendance Log', 'Comprehensive checkins summary', isDarkMode),
                const Divider(),
                _buildReportDownloadItem('Faculty Adoption Metrics', 'Stats on AI lessons and test creation', isDarkMode),
                const Divider(),
                _buildReportDownloadItem('Placement Readiness Scorecard', 'Consolidated CV ranking matrices', isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportDownloadItem(String title, String subtitle, bool isDark) {
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
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155DFC),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
