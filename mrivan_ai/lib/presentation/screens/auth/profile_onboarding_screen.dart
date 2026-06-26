import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../../data/services/database_service.dart';
import '../../widgets/animated_background.dart';
import '../../theme/theme_config.dart';
import '../dashboard/app_router.dart';

class ProfileOnboardingScreen extends StatefulWidget {
  final String? pendingPlanTitle;
  final String? pendingPlanPrice;
  final String? pendingPlanSubtitle;
  final bool isCampus;

  const ProfileOnboardingScreen({
    super.key,
    this.pendingPlanTitle,
    this.pendingPlanPrice,
    this.pendingPlanSubtitle,
    this.isCampus = false,
  });

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF155DFC);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _rose = Color(0xFFF05A7E);

  static const List<Map<String, String>> _availablePlans = [
    {
      'title': 'Free Plan',
      'price': 'Free',
      'subtitle': 'For first-time learners',
    },
    {
      'title': 'Basic Plan',
      'price': 'Rs 99',
      'subtitle': 'Affordable daily study help',
    },
    {
      'title': 'Campus Plan',
      'price': 'Rs 149/student',
      'subtitle': 'For schools and institutions',
    },
    {
      'title': 'Pro Student',
      'price': 'Rs 299',
      'subtitle': 'For personalized AI learning',
    },
    {
      'title': 'Exam Aspirant',
      'price': 'Rs 499',
      'subtitle': 'For exam-focused preparation',
    },
    {
      'title': 'Premium AI',
      'price': 'Rs 999',
      'subtitle': 'For advanced AI productivity',
    },
  ];

  late String _selectedPlanTitle;
  late final AnimationController _entryController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _studentsController = TextEditingController();
  final TextEditingController _teachersController = TextEditingController();

  bool _isSaving = false;

  bool _isJoinWithCode = false;
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _inviteCodeVerified = false;
  bool _isVerifyingCode = false;
  String? _inviteCodeError;
  String? _verifiedSchoolId;
  String? _verifiedSchoolName;
  int _verifiedTotalSeats = 0;
  int _verifiedTeacherSeats = 20;
  String? _verifiedSchoolAdminPhone;
  String? _verifiedSchoolAdminEmail;

  String _selectedRole = 'student';
  final TextEditingController _subjectController = TextEditingController();
  List<Map<String, dynamic>> _availableClasses = [];
  String? _selectedClassId;

  bool get _isDarkMode => isDarkModeNotifier.value;
  String? get _currentUserEmail => Supabase.instance.client.auth.currentUser?.email;

  int _calculateCampusPrice() {
    final studentCount = int.tryParse(_studentsController.text.trim()) ?? 100;
    return studentCount * 149;
  }

  @override
  void initState() {
    super.initState();
    _selectedPlanTitle = widget.pendingPlanTitle ?? 'Free Plan';
    if (!_availablePlans.any((p) => p['title'] == _selectedPlanTitle)) {
      _selectedPlanTitle = 'Free Plan';
    }

    _studentsController.text = '100';
    _teachersController.text = '10';

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    // Autofill name from authenticated user if possible
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final displayName = user.userMetadata?['full_name'] as String?;
      if (displayName != null && !displayName.contains('@')) {
        _nameController.text = displayName;
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _schoolNameController.dispose();
    _studentsController.dispose();
    _teachersController.dispose();
    _inviteCodeController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _verifyInviteCode() async {
    final code = _inviteCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isVerifyingCode = true;
      _inviteCodeVerified = false;
      _inviteCodeError = null;
      _verifiedSchoolId = null;
      _verifiedSchoolName = null;
      _verifiedSchoolAdminPhone = null;
      _verifiedSchoolAdminEmail = null;
    });

    try {
      final schoolResponse = await Supabase.instance.client
          .from('schools')
          .select('id, name, total_seats, admin_id')
          .eq('invite_code', code)
          .maybeSingle();

      if (schoolResponse == null) {
        setState(() {
          _inviteCodeError = 'Enter a valid code';
        });
        throw Exception('Invalid invite code. Please check and try again.');
      }

      final schoolId = schoolResponse['id'] as String;
      final schoolName = schoolResponse['name'] as String;
      final totalSeats = schoolResponse['total_seats'] as int? ?? 100;
      final teacherSeats = 20; // Default fallback to 20 seats since table doesn't have teacher_seats column
      final adminId = schoolResponse['admin_id'] as String?;

      String? adminPhone;
      String? adminEmail;

      if (adminId != null) {
        final adminResponse = await Supabase.instance.client
            .from('profiles')
            .select('phone_number, email')
            .eq('id', adminId)
            .maybeSingle();

        if (adminResponse != null) {
          adminPhone = adminResponse['phone_number'] as String?;
          adminEmail = adminResponse['email'] as String?;
        }
      }

      setState(() {
        _inviteCodeVerified = true;
        _verifiedSchoolId = schoolId;
        _verifiedSchoolName = schoolName;
        _verifiedTotalSeats = totalSeats;
        _verifiedTeacherSeats = teacherSeats;
        _verifiedSchoolAdminPhone = adminPhone ?? '9999999999';
        _verifiedSchoolAdminEmail = adminEmail ?? 'admin@mrivan.ai';
      });

      await _loadClassesForSchool(schoolId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully linked to $schoolName!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      setState(() {
        _inviteCodeError = 'Enter a valid code';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      setState(() => _isVerifyingCode = false);
    }
  }

  Future<void> _loadClassesForSchool(String schoolId) async {
    try {
      final list = await DatabaseService.instance.fetchClasses(schoolId);
      setState(() {
        _availableClasses = list;
        if (_availableClasses.isNotEmpty) {
          _selectedClassId = _availableClasses.first['id'];
        } else {
          _selectedClassId = null;
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error loading classes: $e');
    }
  }

  void _showQuotaExceededDialog() {
    final adminPhone = _verifiedSchoolAdminPhone ?? '9999999999';
    final adminEmail = _verifiedSchoolAdminEmail ?? 'admin@mrivan.ai';
    final schoolName = _verifiedSchoolName ?? 'the school';
    final message = Uri.encodeComponent('School quota exceeded for $schoolName. Please upgrade our plan.');

    showDialog(
      context: context,
      builder: (context) {
        final isDark = _isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF101827) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _rose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: _rose),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quota Exceeded',
                  style: TextStyle(
                    color: isDark ? Colors.white : _ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'The seat limit for this school campus has been exceeded. Please contact your campus administrator to upgrade.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse('https://wa.me/$adminPhone?text=$message');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.chat_bubble_rounded, size: 16),
              label: const Text('WhatsApp Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse('mailto:$adminEmail?subject=School%20Quota%20Exceeded&body=School%20quota%20exceeded%20for%20$schoolName');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              icon: const Icon(Icons.email_rounded, size: 16),
              label: const Text('Email Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      if (_selectedPlanTitle == 'Campus Plan' && _isJoinWithCode) {
        if (!_inviteCodeVerified || _verifiedSchoolId == null) {
          throw Exception('Please verify a valid school invite code first.');
        }

        // Quota check
        final existingProfiles = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('school_id', _verifiedSchoolId!)
            .eq('role', _selectedRole);

        final currentCount = existingProfiles.length;
        if (_selectedRole == 'student') {
          if (currentCount >= _verifiedTotalSeats) {
            if (mounted) {
              setState(() => _isSaving = false);
              _showQuotaExceededDialog();
            }
            return;
          }
        } else {
          if (currentCount >= _verifiedTeacherSeats) {
            if (mounted) {
              setState(() => _isSaving = false);
              _showQuotaExceededDialog();
            }
            return;
          }
        }

        // Save profile
        final String selectedClassName = _selectedRole == 'student'
            ? (_availableClasses.firstWhere((c) => c['id'] == _selectedClassId, orElse: () => {'name': 'Grade 10'})['name'] ?? 'Grade 10')
            : 'Faculty';

        await DatabaseService.instance.updateUserProfile(
          userId: user.id,
          fullName: _nameController.text.trim(),
          schoolId: _verifiedSchoolId,
          classId: _selectedRole == 'student' ? _selectedClassId : null,
          paymentPlan: 'Campus Plan',
          className: selectedClassName,
          age: _selectedRole == 'student' ? _ageController.text.trim() : 'N/A',
          phoneNumber: _phoneController.text.trim(),
          role: _selectedRole,
          email: user.email,
          teacherSpecialization: _selectedRole == 'teacher' ? _subjectController.text.trim() : null,
        );

        if (_selectedRole == 'teacher' && _selectedClassId != null) {
          try {
            await Supabase.instance.client.from('class_teachers').insert({
              'class_id': _selectedClassId,
              'teacher_id': user.id,
            });
          } catch (e) {
            if (kDebugMode) print('Error saving class_teacher: $e');
          }
        }

        // Clear pending plan (since they joined an existing school)
        AppRouter.pendingPlanTitle = null;
        AppRouter.pendingPlanPrice = null;
        AppRouter.pendingPlanSubtitle = null;
        AppRouter.isCampus = false;
      } else {
        final isCampus = _selectedPlanTitle == 'Campus Plan';
        if (_selectedPlanTitle != 'Free Plan') {
          await DatabaseService.instance.updateUserProfile(
            userId: user.id,
            fullName: _nameController.text.trim(),
            className: isCampus ? 'Campus Admin' : _classController.text.trim(),
            age: isCampus ? 'N/A' : _ageController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            role: isCampus ? 'admin' : 'student',
            email: user.email,
          );
        }

        final selectedPlan = _availablePlans.firstWhere(
          (p) => p['title'] == _selectedPlanTitle,
          orElse: () => _availablePlans.first,
        );

        if (_selectedPlanTitle == 'Free Plan') {
          AppRouter.pendingPlanTitle = null;
          AppRouter.pendingPlanPrice = null;
          AppRouter.pendingPlanSubtitle = null;
          AppRouter.isCampus = false;
        } else if (_selectedPlanTitle == 'Campus Plan') {
          final schoolName = _schoolNameController.text.trim();
          final studentCount = int.tryParse(_studentsController.text.trim()) ?? 100;
          final teacherCount = int.tryParse(_teachersController.text.trim()) ?? 10;

          AppRouter.pendingPlanTitle = 'Campus Plan';
          AppRouter.pendingPlanPrice = '₹${studentCount * 149}';
          AppRouter.pendingPlanSubtitle = 'For $schoolName ($studentCount students, $teacherCount teachers)';
          AppRouter.isCampus = true;

          AppRouter.schoolName = schoolName;
          AppRouter.studentCount = studentCount;
          AppRouter.teacherCount = teacherCount;
        } else {
          AppRouter.pendingPlanTitle = selectedPlan['title'];
          AppRouter.pendingPlanPrice = selectedPlan['price'];
          AppRouter.pendingPlanSubtitle = selectedPlan['subtitle'];
          AppRouter.isCampus = false;
        }
      }

      AppRouter.hasClickedLogin = false;
      if (mounted) {
        AppRouter.notifyProfileUpdated();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF101827) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: _isDarkMode ? Colors.white12 : Colors.black12),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _rose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.error_outline_rounded, color: _rose),
              ),
              const SizedBox(width: 12),
              Text(
                'Failed to Save Profile',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: _primary),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return Scaffold(
          body: AnimatedBackground(
            isDarkMode: isDarkMode,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 36 : 18,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entryController,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _entryController,
                        curve: Curves.easeOutCubic,
                      )),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _buildOnboardingCard(isDarkMode),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnboardingCard(bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDarkMode ? Colors.white12 : Colors.white70,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: isDarkMode ? 0.18 : 0.10),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUserEmailBadge(isDarkMode),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: _primary,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Complete Your Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please tell us a bit about yourself to customize your AI Cockpit learning experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 28),                if (_selectedPlanTitle != 'Free Plan') ...[
                  // Full Name Input
                  _buildInputField(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person_rounded,
                    hint: 'Enter your full name',
                    isDarkMode: isDarkMode,
                    validator: (val) {
                      if (_selectedPlanTitle == 'Free Plan') return null;
                      if (val == null || val.trim().isEmpty) return 'Name is required';
                      if (val.trim().contains('@')) return 'Enter a real name, not your email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  if (_selectedPlanTitle != 'Campus Plan') ...[
                    // Class/Grade Input
                    _buildInputField(
                      label: 'Class / Grade',
                      controller: _classController,
                      icon: Icons.school_rounded,
                      hint: 'e.g. Grade 11, college sophomore, self-study',
                      isDarkMode: isDarkMode,
                      validator: (val) {
                        if (_selectedPlanTitle == 'Free Plan') return null;
                        if (val == null || val.trim().isEmpty) return 'Class/Grade is required';
                        if (val.trim().length < 2) return 'Enter a valid class or grade';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Age Input
                    _buildInputField(
                      label: 'Age',
                      controller: _ageController,
                      icon: Icons.cake_rounded,
                      hint: 'Enter your age',
                      keyboardType: TextInputType.number,
                      isDarkMode: isDarkMode,
                      validator: (val) {
                        if (_selectedPlanTitle == 'Free Plan') return null;
                        if (val == null || val.trim().isEmpty) return 'Age is required';
                        final age = int.tryParse(val.trim());
                        if (age == null) return 'Age must be a number';
                        if (age < 5 || age > 100) return 'Enter a valid age (5–100)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    // Campus Mode Toggle ("New Purchase" vs "Join with Code")
                    _buildCampusModeToggle(isDarkMode),

                    if (!_isJoinWithCode) ...[
                      // New Purchase mode
                      _buildInputField(
                        label: 'School / College Name',
                        controller: _schoolNameController,
                        icon: Icons.business_rounded,
                        hint: 'Enter school/college name',
                        isDarkMode: isDarkMode,
                        validator: (val) {
                          if (_selectedPlanTitle == 'Campus Plan' && !_isJoinWithCode) {
                            if (val == null || val.trim().isEmpty) return 'School/College name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Number of Students
                      _buildInputField(
                        label: 'Number of Students',
                        controller: _studentsController,
                        icon: Icons.people_rounded,
                        hint: 'Enter number of students (min 50)',
                        keyboardType: TextInputType.number,
                        isDarkMode: isDarkMode,
                        onChanged: (val) {
                          setState(() {});
                        },
                        validator: (val) {
                          if (_selectedPlanTitle == 'Campus Plan' && !_isJoinWithCode) {
                            if (val == null || val.trim().isEmpty) return 'Number of students is required';
                            final count = int.tryParse(val.trim());
                            if (count == null || count < 50) return 'Minimum 50 students required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Number of Teachers
                      _buildInputField(
                        label: 'Number of Teachers',
                        controller: _teachersController,
                        icon: Icons.person_outline_rounded,
                        hint: 'Enter number of teachers',
                        keyboardType: TextInputType.number,
                        isDarkMode: isDarkMode,
                        validator: (val) {
                          if (_selectedPlanTitle == 'Campus Plan' && !_isJoinWithCode) {
                            if (val == null || val.trim().isEmpty) return 'Number of teachers is required';
                            final count = int.tryParse(val.trim());
                            if (count == null || count <= 0) return 'Must be at least 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      // Join with Code mode
                      _buildInviteCodeInput(isDarkMode),
                      _buildVerifiedSchoolCard(isDarkMode),
                      _buildRoleToggle(isDarkMode),
                      _buildRoleSpecificFields(isDarkMode),
                    ],
                  ],

                  // Phone Number Input
                  if (_selectedPlanTitle != 'Campus Plan' || !_isJoinWithCode || _inviteCodeVerified) ...[
                    _buildInputField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone_rounded,
                      hint: 'Enter your contact number',
                      keyboardType: TextInputType.phone,
                      isDarkMode: isDarkMode,
                      validator: (val) {
                        if (_selectedPlanTitle != 'Campus Plan' || !_isJoinWithCode || _inviteCodeVerified) {
                          if (val == null || val.trim().isEmpty) return 'Phone number is required';
                          final phone = val.trim();
                          final phoneRegex = RegExp(r'^[6-9]\d{9}$');
                          if (!phoneRegex.hasMatch(phone)) return 'Enter a valid 10-digit Indian mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                ],

                _buildPlanDropdown(isDarkMode),
                const SizedBox(height: 32),

                _isSaving
                    ? Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(_primary),
                        ),
                      )
                    : ((_selectedPlanTitle == 'Campus Plan' && _isJoinWithCode && !_inviteCodeVerified)
                        ? const SizedBox.shrink()
                        : ElevatedButton(
                            onPressed: _handleSaveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              (_selectedPlanTitle == 'Free Plan' || (_selectedPlanTitle == 'Campus Plan' && _isJoinWithCode))
                                  ? 'Complete Setup'
                                  : 'Continue to Checkout',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserEmailBadge(bool isDarkMode) {
    final email = _currentUserEmail;
    if (email == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () async {
          setState(() => _isSaving = true);
          try {
            AppRouter.hasClickedLogin = false;
            await Supabase.instance.client.auth.signOut();
            try {
              final googleSignIn = GoogleSignIn();
              await googleSignIn.signOut().catchError((_) => null);
            } catch (_) {}
          } catch (e) {
            if (mounted) {
              _showErrorDialog(e.toString());
            }
          } finally {
            if (mounted) {
              setState(() => _isSaving = false);
            }
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode ? Colors.white12 : Colors.black12,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_rounded,
                  size: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 6),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.logout_rounded,
                  size: 12,
                  color: _rose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isDarkMode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white.withValues(alpha: 0.8) : _ink.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(color: isDarkMode ? Colors.white : _ink, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white30 : Colors.black38,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: isDarkMode ? Colors.white.withValues(alpha: 0.5) : Colors.black45, size: 20),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorStyle: const TextStyle(color: _rose, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCampusModeToggle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isJoinWithCode = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isJoinWithCode
                      ? (isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isJoinWithCode && !isDarkMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  'New Purchase',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: !_isJoinWithCode
                        ? (isDarkMode ? Colors.white : _primary)
                        : (isDarkMode ? Colors.white60 : Colors.black54),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isJoinWithCode = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isJoinWithCode
                      ? (isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isJoinWithCode && !isDarkMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  'Join with Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _isJoinWithCode
                        ? (isDarkMode ? Colors.white : _primary)
                        : (isDarkMode ? Colors.white60 : Colors.black54),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeInput(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campus Invite Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white.withValues(alpha: 0.8) : _ink.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (val) {
                  if (_inviteCodeError != null || _inviteCodeVerified) {
                    setState(() {
                      _inviteCodeError = null;
                      _inviteCodeVerified = false;
                    });
                  }
                },
                style: TextStyle(color: isDarkMode ? Colors.white : _ink, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter school invite code',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white30 : Colors.black38,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.vpn_key_rounded,
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.5) : Colors.black45,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
                  errorText: _inviteCodeError,
                  errorStyle: const TextStyle(color: _rose, fontSize: 12),
                ),
                validator: (val) {
                  if (_selectedPlanTitle == 'Campus Plan' && _isJoinWithCode) {
                    if (val == null || val.trim().isEmpty) return 'Code is required';
                    if (!_inviteCodeVerified) return 'Please verify code first';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isVerifyingCode ? null : _verifyInviteCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _inviteCodeVerified ? const Color(0xFF059669) : _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _isVerifyingCode
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _inviteCodeVerified ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifiedSchoolCard(bool isDarkMode) {
    if (!_inviteCodeVerified || _verifiedSchoolName == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LINKED SCHOOL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _verifiedSchoolName!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle(bool isDarkMode) {
    if (!_inviteCodeVerified) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRole = 'student';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedRole == 'student'
                      ? (isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedRole == 'student' && !isDarkMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.backpack_rounded,
                      size: 16,
                      color: _selectedRole == 'student'
                          ? (isDarkMode ? Colors.white : _primary)
                          : (isDarkMode ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Student',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _selectedRole == 'student'
                            ? (isDarkMode ? Colors.white : _primary)
                            : (isDarkMode ? Colors.white60 : Colors.black54),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRole = 'teacher';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedRole == 'teacher'
                      ? (isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedRole == 'teacher' && !isDarkMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.co_present_rounded,
                      size: 16,
                      color: _selectedRole == 'teacher'
                          ? (isDarkMode ? Colors.white : _primary)
                          : (isDarkMode ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Teacher',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _selectedRole == 'teacher'
                            ? (isDarkMode ? Colors.white : _primary)
                            : (isDarkMode ? Colors.white60 : Colors.black54),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown(bool isDarkMode) {
    final currentText = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = isDarkMode ? Colors.white24 : const Color(0xFFD1D5DB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Class',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedClassId,
          dropdownColor: cardBg,
          style: TextStyle(color: currentText, fontSize: 13),
          decoration: InputDecoration(
            hintText: _availableClasses.isEmpty ? 'No classes available' : 'Choose a class',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.school_rounded, color: Colors.grey, size: 20),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E1E2F) : const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderCol),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderCol),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
          ),
          items: _availableClasses.map((cls) {
            return DropdownMenuItem<String>(
              value: cls['id'],
              child: Text(cls['name'] ?? '', style: TextStyle(color: currentText, fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedClassId = val;
            });
          },
          validator: (val) {
            if (val == null) return 'Class is required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleSpecificFields(bool isDarkMode) {
    if (!_inviteCodeVerified) return const SizedBox.shrink();
    if (_selectedRole == 'student') {
      return Column(
        children: [
          const SizedBox(height: 18),
          _buildClassDropdown(isDarkMode),
          const SizedBox(height: 18),
          _buildInputField(
            label: 'Age',
            controller: _ageController,
            icon: Icons.cake_rounded,
            hint: 'Enter your age',
            keyboardType: TextInputType.number,
            isDarkMode: isDarkMode,
            validator: (val) {
              if (_selectedPlanTitle == 'Campus Plan' && _isJoinWithCode && _selectedRole == 'student') {
                if (val == null || val.trim().isEmpty) return 'Age is required';
              }
              return null;
            },
          ),
        ],
      );
    } else {
      return Column(
        children: [
          const SizedBox(height: 18),
          _buildInputField(
            label: 'Subject / Specialization',
            controller: _subjectController,
            icon: Icons.subject_rounded,
            hint: 'e.g. Mathematics, Physics, Chemistry',
            isDarkMode: isDarkMode,
            validator: (val) {
              if (_selectedPlanTitle == 'Campus Plan' && _isJoinWithCode && _selectedRole == 'teacher') {
                if (val == null || val.trim().isEmpty) return 'Subject / Specialization is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _buildClassDropdown(isDarkMode),
        ],
      );
    }
  }

  Widget _buildPlanDropdown(bool isDarkMode) {
    if (_selectedPlanTitle == 'Campus Plan' && _isJoinWithCode) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Payment Plan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white.withValues(alpha: 0.8) : _ink.withValues(alpha: 0.8),
              ),
            ),
            if (_selectedPlanTitle == 'Campus Plan')
              Text(
                'Total: ₹${_calculateCampusPrice()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPlanTitle,
          dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(color: isDarkMode ? Colors.white : _ink, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.star_rounded,
              color: isDarkMode ? Colors.white.withValues(alpha: 0.5) : Colors.black45,
              size: 20,
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          items: _availablePlans.map((plan) {
            return DropdownMenuItem<String>(
              value: plan['title'],
              child: Text("${plan['title']} (${plan['price']})"),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedPlanTitle = val;
              });
            }
          },
        ),
      ],
    );
  }
}
