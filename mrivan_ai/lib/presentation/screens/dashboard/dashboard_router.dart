import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';
import '../../../data/services/database_service.dart';
import '../auth/payment_screen.dart';
import '../../theme/theme_config.dart';

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
  bool get _isDarkMode => isDarkModeNotifier.value;
  bool _isLoadingProfile = true;
  String? _userRole;
  String? _userName;
  String? schoolId;
  String? classId;
  String? _paymentPlan;
  String? _className;
  String? _age;
  String? _phoneNumber;
  String? _email;
  bool _isSavingProfile = false;
  bool _profileSavedThisSession = false; // persists across reloads within session
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Cockpit State variables
  String _activeMode = 'AI Voice Tutor';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatInputController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'sender': 'ai',
      'content': 'Hello! I am Mrivan AI, your dedicated 24/7 personal tutor. I can explain any subject, solve math equations, analyze source images, or guide you through exam preps. Adjust your academic profile to the left, and let me know what we are learning today!',
      'time': '1:24:28 PM'
    }
  ];
  String _selectedGrade = 'High School';
  String _selectedSubject = 'Physics & Quantum Mechanics';
  String _selectedExamPrep = 'None / General Study';
  String _selectedAvenue = 'Coaching';
  String _selectedLanguage = 'English';
  bool _autoInteractiveVoice = true;

  // Student Attendance list state
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoadingAttendance = false;

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingPlanRedirect();
    });
  }

  void _checkPendingPlanRedirect() {
    final uri = Uri.base;
    final planTitle = uri.queryParameters['plan_title'];
    final planPrice = uri.queryParameters['plan_price'];
    final planSubtitle = uri.queryParameters['plan_subtitle'];

    if (planTitle != null && planPrice != null) {
      // Clear query parameters in URL to prevent redirect loop on reload
      SystemNavigator.routeInformationUpdated(uri: Uri.parse('/'));
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            planTitle: planTitle,
            planPrice: planPrice,
            planSubtitle: planSubtitle ?? '',
          ),
        ),
      );
    }
  }

  // Fetch the logged-in user profile from Supabase
  Future<void> _loadUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingProfile = true;
      _email = user.email;
    });

    try {
      // 1. Get role and profiles details
      final response = await _client
          .from('profiles')
          .select('role, full_name, school_id, class_id, payment_plan, class, age, phone_number')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _userRole = 'student'; // Force student role for everyone
        if (response != null) {
          _userName = response['full_name'] as String?;
          schoolId = response['school_id'] as String?;
          classId = response['class_id'] as String?;
          _paymentPlan = (response['payment_plan'] as String?) ?? 'Free Plan';
          _className = response['class'] as String?;
          _age = response['age'] as String?;
          _phoneNumber = response['phone_number'] as String?;
        } else {
          _paymentPlan = 'Free Plan';
        }
      });
      
      // 2. Proactively load data based on user role (e.g. attendance for students)
      if (_userRole == 'student') {
        _loadStudentAttendance(user.id);
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

  bool _isProfileIncomplete() {
    // Campus Plan users have their own CRM dashboards — skip this onboarding
    if (_paymentPlan == 'Campus Plan') return false;
    // If profile was successfully saved this session, never re-ask
    if (_profileSavedThisSession) return false;
    if (_userName == null || _userName!.trim().isEmpty) return true;
    if (_userName!.contains('@')) return true; // email fallback means name wasn't set
    if (_className == null || _className!.trim().isEmpty) return true;
    if (_age == null || _age!.trim().isEmpty) return true;
    if (_phoneNumber == null || _phoneNumber!.trim().isEmpty) return true;
    return false;
  }

  Future<void> _saveProfileDetails({
    required String name,
    required String className,
    required String age,
    required String phoneNumber,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    setState(() {
      _isSavingProfile = true;
    });
    try {
      await DatabaseService.instance.updateUserProfile(
        userId: user.id,
        fullName: name,
        className: className,
        age: age,
        phoneNumber: phoneNumber,
        paymentPlan: _paymentPlan,
      );
      // Mark saved so we never show setup again this session
      setState(() {
        _userName = name;
        _className = className;
        _age = age;
        _phoneNumber = phoneNumber;
        _profileSavedThisSession = true;
      });
      // Background reload to sync any server-side changes
      _loadUserProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Failed to save profile: $e')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Widget _buildProfileCompletionView() {
    // Pre-fill controllers with any existing data (e.g. name from Google)
    if (_nameController.text.isEmpty && _userName != null && !_userName!.contains('@')) {
      _nameController.text = _userName!;
    }
    if (_classController.text.isEmpty && _className != null) {
      _classController.text = _className!;
    }
    if (_ageController.text.isEmpty && _age != null) {
      _ageController.text = _age!;
    }
    if (_phoneController.text.isEmpty && _phoneNumber != null) {
      _phoneController.text = _phoneNumber!;
    }
    final isDark = _isDarkMode;
    const primaryColor = Color(0xFF155DFC);
    const accentColor = Color(0xFF72E1FF);

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: 520,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0D1B2A), const Color(0xFF111827)]
                  : [Colors.white, const Color(0xFFF0F6FF)],
            ),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : primaryColor.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.10),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 36, 32, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Logo + Glow Halo ─────────────────────────────
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primaryColor.withValues(alpha: 0.30),
                                  primaryColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/logo.jpeg',
                              height: 76,
                              width: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 76,
                                width: 76,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.person_rounded, color: primaryColor, size: 40),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Title ────────────────────────────────────────
                    Center(
                      child: Text(
                        'Set Up Your Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Tell us about yourself to personalise your study cockpit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Step Indicator ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == 0 ? 24 : 8,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == 0 ? primaryColor : (isDark ? Colors.white12 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),

                    // ── Email chip ────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? primaryColor.withValues(alpha: 0.06)
                            : primaryColor.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: primaryColor, size: 16),
                          const SizedBox(width: 10),
                          Text(
                            'Signed in as  ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _email ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? accentColor : primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ── Input Fields ──────────────────────────────────
                    _buildInputLabel('FULL NAME', isDark),
                    const SizedBox(height: 7),
                    _buildInputField(
                      controller: _nameController,
                      hintText: 'e.g. Aryan Sharma',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('CLASS / GRADE', isDark),
                              const SizedBox(height: 7),
                              _buildInputField(
                                controller: _classController,
                                hintText: 'e.g. Class 10',
                                icon: Icons.school_outlined,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputLabel('AGE', isDark),
                              const SizedBox(height: 7),
                              _buildInputField(
                                controller: _ageController,
                                hintText: 'e.g. 16',
                                icon: Icons.cake_outlined,
                                isDark: isDark,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _buildInputLabel('PHONE NUMBER', isDark),
                    const SizedBox(height: 7),
                    _buildInputField(
                      controller: _phoneController,
                      hintText: 'e.g. +91 98765 43210',
                      icon: Icons.phone_outlined,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // ── Save Button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _isSavingProfile
                              ? LinearGradient(colors: [Colors.grey[600]!, Colors.grey[700]!])
                              : const LinearGradient(
                                  colors: [Color(0xFF155DFC), Color(0xFF3B82F6)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          boxShadow: _isSavingProfile
                              ? []
                              : [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.40),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSavingProfile
                              ? null
                              : () async {
                                  final name = _nameController.text.trim();
                                  final className = _classController.text.trim();
                                  final age = _ageController.text.trim();
                                  final phone = _phoneController.text.trim();

                                  if (name.isEmpty || className.isEmpty || age.isEmpty || phone.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                                            SizedBox(width: 10),
                                            Text('Please fill in all fields to continue.'),
                                          ],
                                        ),
                                        backgroundColor: Colors.orange[700],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    return;
                                  }
                                  await _saveProfileDetails(
                                    name: name,
                                    className: className,
                                    age: age,
                                    phoneNumber: phone,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isSavingProfile
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.rocket_launch_rounded, size: 18),
                                    SizedBox(width: 10),
                                    Text(
                                      'Save & Launch Cockpit',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Privacy Note ──────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 11,
                              color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(width: 5),
                          Text(
                            'Your data is encrypted and never shared.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white24 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: isDark ? Colors.white38 : Colors.black45,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 13,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(
            icon,
            color: const Color(0xFF155DFC),
            size: 18,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFF155DFC).withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFF155DFC).withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF155DFC),
            width: 1.8,
          ),
        ),
      ),
    );
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
    if (!_isLoadingProfile && !_isProfileIncomplete() && _paymentPlan != 'Campus Plan') {
      return _buildStudyCockpitDashboard();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    'assets/logo.jpeg',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.school_rounded,
                                      color: Color(0xFF155DFC),
                                      size: 26,
                                    ),
                                  ),
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
                                    _isDarkMode ? Icons.lightbulb_rounded : Icons.school_rounded,
                                    color: _isDarkMode ? Colors.amber : const Color(0xFF155DFC),
                                  ),
                                  onPressed: () {
                                    isDarkModeNotifier.value = !_isDarkMode;
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
                          : _isProfileIncomplete()
                              ? _buildProfileCompletionView()
                              : _buildRoleDashboard(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // ------------------------------------------------------------------------
  // STUDY COCKPIT DASHBOARD (FOR ALL NON-CAMPUS PLANS)
  // ------------------------------------------------------------------------
  Widget _buildStudyCockpitDashboard() {
    final isDark = _isDarkMode;
    final primaryColor = const Color(0xFF155DFC);

    return Scaffold(
      body: AnimatedBackground(
        isDarkMode: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Panel Row
                _buildCockpitHeader(isDark),
                const SizedBox(height: 16),

                // 2. Search Panel
                _buildCockpitSearchPanel(isDark),
                const SizedBox(height: 16),

                // 3. Mode Selection Buttons
                _buildCockpitModeSelector(isDark, primaryColor),
                const SizedBox(height: 16),

                // 4. Main Body Split Area
                _buildCockpitMainBody(isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCockpitHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          // Active Study Workspace Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF155DFC).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF155DFC),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Study Workspace',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Mrivan COCKPIT NODE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Streak & XP Metrics
          Row(
            children: [
              // 3 Day Streak
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '3 Day Streak',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // XP Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '720 XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigoAccent,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Landing Home Button
              ElevatedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout_rounded, size: 14),
                label: const Text(
                  'Landing Home',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitSearchPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'WORKSPACE SEARCH ENGINE / DIRECTORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search folders, educational modules, study suites, or specific subjects instantly.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
              // Search Input Box
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search folders or tags...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.white38,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF155DFC)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'QUICK FOLDERS / TAGS:',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
              _buildSearchTag('Physics & Equations', isDark),
              _buildSearchTag('CBT Diagnostics', isDark),
              _buildSearchTag('AI Lecture Slides', isDark),
              _buildSearchTag('Deep Research Publications', isDark),
              _buildSearchTag('Pomodoro Study Studio & Flashcards', isDark),
              _buildSearchTag('Teacher Grading Assistants', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTag(String text, bool isDark) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
        // Optionally lock or switch mode based on tag
        if (text.contains('Physics')) {
          setState(() {
            _activeMode = 'AI Voice Tutor';
            _selectedSubject = 'Physics & Quantum Mechanics';
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.white24,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCockpitModeSelector(bool isDark, Color primaryColor) {
    final modes = [
      'AI Voice Tutor',
      'CBT Diagnostics',
      'Lecture Slides',
      'Deep Research',
      'Study Studio'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes.map((mode) {
        final isSelected = _activeMode == mode;
        final isPremium = mode == 'CBT Diagnostics' || mode == 'Lecture Slides' || mode == 'Deep Research';
        final isLocked = isPremium && _paymentPlan == 'Free Plan';

        return ElevatedButton(
          onPressed: () {
            if (isLocked) {
              _showUpgradeDialog(mode);
            } else {
              setState(() {
                _activeMode = mode;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? primaryColor : (isDark ? Colors.black26 : Colors.white70),
            foregroundColor: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            elevation: isSelected ? 4 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? primaryColor : (isDark ? Colors.white10 : Colors.black12),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mode,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (isLocked) ...[
                const SizedBox(width: 6),
                const Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showUpgradeDialog(String mode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.workspace_premium_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade Required'),
          ],
        ),
        content: Text(
          'The "$mode" suite is a Premium feature. Upgrade to the Pro Student plan to unlock mock CBT exams, deep research assistants, and lecture summarization tools.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open checkout for Pro plan
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentScreen(
                    planTitle: 'Pro Student 🚀',
                    planPrice: '₹299',
                    planSubtitle: 'Unlimited learning & AI tools',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF155DFC),
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitMainBody(bool isDark, Color primaryColor) {
    // If screen width is small, stack vertically.
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final profileRail = _buildCockpitProfileRail(isDark);
    final workspaceView = _buildCockpitWorkspaceContent(isDark, primaryColor);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 280, child: profileRail),
          const SizedBox(width: 16),
          Expanded(child: workspaceView),
        ],
      );
    } else {
      return Column(
        children: [
          profileRail,
          const SizedBox(height: 16),
          workspaceView,
        ],
      );
    }
  }

  Widget _buildCockpitProfileRail(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Classroom Profile header
          Row(
            children: const [
              Icon(Icons.school_rounded, color: Color(0xFF155DFC), size: 18),
              SizedBox(width: 8),
              Text(
                'CLASSROOM PROFILE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Grade Dropdown
          _buildDropdownLabel('Current Grade / Class', isDark),
          const SizedBox(height: 6),
          _buildDropdown<String>(
            value: _selectedGrade,
            items: [
              'Kindergarten',
              'Elementary School',
              'Middle School',
              'High School',
              'Undergraduate College',
              'Postgraduate',
              'PhD Candidate'
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedGrade = val);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Subject Dropdown
          _buildDropdownLabel('Subject of Interest', isDark),
          const SizedBox(height: 6),
          _buildDropdown<String>(
            value: _selectedSubject,
            items: [
              'Mathematics & Calculus',
              'Physics & Quantum Mechanics',
              'Organic Chemistry',
              'Biology & Genetics',
              'Computer Science & AI',
              'World History',
              'English & Literature',
              'Inorganic Chemistry'
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedSubject = val);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Exam Preparation Dropdown
          _buildDropdownLabel('Exam Preparation', isDark),
          const SizedBox(height: 6),
          _buildDropdown<String>(
            value: _selectedExamPrep,
            items: [
              'None / General Study',
              'SAT Prep',
              'ACT Prep',
              'JEE / Advanced Prep',
              'NEET Prep',
              'GRE / GMAT Focus',
              'AP Calculus',
              'Civil Services Prep'
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedExamPrep = val);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Avenue Grid
          _buildDropdownLabel('Avenue', isDark),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 2.2,
            children: ['Public', 'Private', 'College', 'Coaching'].map((avenue) {
              final isSelected = _selectedAvenue == avenue;
              return InkWell(
                onTap: () => setState(() => _selectedAvenue = avenue),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF155DFC) : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF155DFC) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Text(
                    avenue,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Language Dropdown
          _buildDropdownLabel('Language preference', isDark),
          const SizedBox(height: 6),
          _buildDropdown<String>(
            value: _selectedLanguage,
            items: [
              'English',
              'Hindi',
              'Spanish',
              'French',
              'German',
              'Mandarin',
              'Japanese'
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedLanguage = val);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Auto Interactive Voice Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auto Interactive Voice',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Switch(
                value: _autoInteractiveVoice,
                onChanged: (val) => setState(() => _autoInteractiveVoice = val),
                activeColor: const Color(0xFF155DFC),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Adaptive Learning tag
          Row(
            children: const [
              Icon(Icons.memory_rounded, color: Colors.blueAccent, size: 14),
              SizedBox(width: 6),
              Text(
                'Adaptive learning AI enabled',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white38 : Colors.black45,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 12,
          ),
          dropdownColor: isDark ? Colors.grey[900] : Colors.white,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCockpitWorkspaceContent(bool isDark, Color primaryColor) {
    if (_activeMode == 'AI Voice Tutor') {
      return _buildCockpitChatSection(isDark, primaryColor);
    }

    // Otherwise show mode placeholder
    return Container(
      height: 500,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeMode == 'Study Studio' ? Icons.timer_rounded : Icons.folder_zip_rounded,
              size: 48,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 12),
            Text(
              '$_activeMode Module',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Interactive workspaces for this workspace package are fully loaded and operational.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCockpitChatSection(bool isDark, Color primaryColor) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white24,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
              border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mrivan AI Tutor',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'High School • $_selectedSubject Teacher',
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '720 XP',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),

          // Message Feed & Visualizer area
          Expanded(
            child: Stack(
              children: [
                // Messages List
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    final isAI = message['sender'] == 'ai';

                    return Align(
                      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAI ? (isDark ? Colors.grey[900] : Colors.white) : primaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isAI ? Radius.zero : const Radius.circular(16),
                            bottomRight: isAI ? const Radius.circular(16) : Radius.zero,
                          ),
                          border: isAI ? Border.all(color: isDark ? Colors.white10 : Colors.black12) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['content'],
                              style: TextStyle(
                                fontSize: 13,
                                color: isAI ? (isDark ? Colors.white70 : Colors.black87) : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message['time'],
                              style: TextStyle(
                                fontSize: 9,
                                color: isAI ? Colors.grey : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Microphone Deep Thought Visualizer overlay
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.mic_rounded, color: Colors.blueAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Deep Thought Active',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message Input Field Form
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white24,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ask Mrivan anything about $_selectedSubject...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF155DFC)),
                      ),
                    ),
                    onSubmitted: (val) => _sendCockpitChatMessage(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.mic_rounded, color: Colors.grey),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audio speech-to-text simulation active')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF155DFC)),
                  onPressed: () => _sendCockpitChatMessage(_chatInputController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendCockpitChatMessage(String content) {
    final text = content.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

    setState(() {
      _chatMessages.add({
        'sender': 'user',
        'content': text,
        'time': timeStr,
      });
      _chatInputController.clear();
    });

    // Simulate AI thinking and response
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _chatMessages.add({
          'sender': 'ai',
          'content': 'Excellent question regarding $_selectedSubject! As your tutor, I analyze this based on $_selectedGrade concepts. Let me break down this formula for you: \\( E = mc^2 \\). Let\'s verify this step-by-step!',
          'time': timeStr,
        });
      });
    });
  }
}
