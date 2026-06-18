import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/database_service.dart';
import '../../widgets/animated_background.dart';
import '../../theme/theme_config.dart';
import 'payment_screen.dart';
import 'campus_payment_screen.dart';
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
  static const Color _teal = Color(0xFF0FBAA6);
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
      'price': 'Rs 149',
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

  bool _isSaving = false;

  bool get _isDarkMode => isDarkModeNotifier.value;
  bool get _hasPendingPlan =>
      widget.pendingPlanTitle != null && widget.pendingPlanPrice != null;

  @override
  void initState() {
    super.initState();
    _selectedPlanTitle = widget.pendingPlanTitle ?? 'Free Plan';
    if (!_availablePlans.any((p) => p['title'] == _selectedPlanTitle)) {
      _selectedPlanTitle = 'Free Plan';
    }

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
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      await DatabaseService.instance.updateUserProfile(
        userId: user.id,
        fullName: _nameController.text.trim(),
        className: _classController.text.trim(),
        age: _ageController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      final selectedPlan = _availablePlans.firstWhere(
        (p) => p['title'] == _selectedPlanTitle,
        orElse: () => _availablePlans.first,
      );

      if (_selectedPlanTitle == 'Free Plan') {
        // Clear pending plan
        AppRouter.pendingPlanTitle = null;
        AppRouter.pendingPlanPrice = null;
        AppRouter.pendingPlanSubtitle = null;
        AppRouter.isCampus = false;
      } else {
        // Set pending plan
        AppRouter.pendingPlanTitle = selectedPlan['title'];
        AppRouter.pendingPlanPrice = selectedPlan['price'];
        AppRouter.pendingPlanSubtitle = selectedPlan['subtitle'];
        AppRouter.isCampus = selectedPlan['title']!.toLowerCase().contains('campus');
      }

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
                const SizedBox(height: 28),

                // Full Name Input
                _buildInputField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_rounded,
                  hint: 'Enter your full name',
                  isDarkMode: isDarkMode,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Name is required';
                    if (val.trim().contains('@')) return 'Enter a real name, not your email';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Class/Grade Input
                _buildInputField(
                  label: 'Class / Grade',
                  controller: _classController,
                  icon: Icons.school_rounded,
                  hint: 'e.g. Grade 11, college sophomore, self-study',
                  isDarkMode: isDarkMode,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Class/Grade is required' : null,
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
                  validator: (val) => val == null || val.trim().isEmpty ? 'Age is required' : null,
                ),
                const SizedBox(height: 18),

                // Phone Number Input
                _buildInputField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone_rounded,
                  hint: 'Enter your contact number',
                  keyboardType: TextInputType.phone,
                  isDarkMode: isDarkMode,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 18),

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
                          _selectedPlanTitle == 'Free Plan' ? 'Complete Setup' : 'Continue to Checkout',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildPlanDropdown(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Plan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white.withValues(alpha: 0.8) : _ink.withValues(alpha: 0.8),
          ),
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
