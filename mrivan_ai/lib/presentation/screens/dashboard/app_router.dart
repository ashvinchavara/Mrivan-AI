import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'premium_dashboard.dart';
import '../auth/landing_page.dart';
import '../auth/profile_onboarding_screen.dart';
import '../auth/payment_screen.dart';
import '../../theme/theme_config.dart';
import '../../widgets/animated_background.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  static final profileUpdatedNotifier = ValueNotifier<int>(0);

  static void notifyProfileUpdated() {
    profileUpdatedNotifier.value++;
  }

  static String? pendingPlanTitle;
  static String? pendingPlanPrice;
  static String? pendingPlanSubtitle;
  static bool isCampus = false;
  static bool hasClickedLogin = false;

  static String? schoolName;
  static int? studentCount;
  static int? teacherCount;

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  bool _isProfileIncomplete = true;
  String _userName = '';
  String _paymentPlan = 'Free Plan';
  String _email = '';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final uri = Uri.base;
      final planTitle = uri.queryParameters['plan_title'];
      final planPrice = uri.queryParameters['plan_price'];
      final planSubtitle = uri.queryParameters['plan_subtitle'];
      if (planTitle != null && planPrice != null) {
        AppRouter.pendingPlanTitle = planTitle;
        AppRouter.pendingPlanPrice = planPrice;
        AppRouter.pendingPlanSubtitle = planSubtitle;
        AppRouter.isCampus = planTitle.toLowerCase().contains('campus');
        SystemNavigator.routeInformationUpdated(uri: Uri.parse('/'));
      }
    }
    _loadUserData();
    AppRouter.profileUpdatedNotifier.addListener(_loadUserData);
  }

  @override
  void dispose() {
    AppRouter.profileUpdatedNotifier.removeListener(_loadUserData);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _email = user.email ?? '';
      });
    }

    try {
      final response = await _client
          .from('profiles')
          .select('full_name, payment_plan, class, age, phone_number')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final fullName = response['full_name'] as String?;
        final className = response['class'] as String?;
        final age = response['age'] as String?;
        final phoneNumber = response['phone_number'] as String?;
        final plan = response['payment_plan'] as String?;

        final incomplete = fullName == null ||
            fullName.isEmpty ||
            fullName.contains('@') ||
            className == null ||
            className.isEmpty ||
            age == null ||
            age.isEmpty ||
            phoneNumber == null ||
            phoneNumber.isEmpty;

        if (mounted) {
          setState(() {
            _isProfileIncomplete = incomplete;
            _userName = fullName ?? '';
            _paymentPlan = plan ?? 'Free Plan';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isProfileIncomplete = true;
            _paymentPlan = 'Free Plan';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data in AppRouter: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Check for pending plan redirect (on both native and Web redirect flows)
    _checkPendingPlanRedirect();
  }

  void _checkPendingPlanRedirect() {
    if (_isProfileIncomplete) return; // Don't redirect until profile is completed

    if (AppRouter.pendingPlanTitle != null && AppRouter.pendingPlanPrice != null) {
      final title = AppRouter.pendingPlanTitle!;
      final price = AppRouter.pendingPlanPrice!;
      final subtitle = AppRouter.pendingPlanSubtitle ?? '';

      // Clear the static variables to prevent redirect loop on reload
      AppRouter.pendingPlanTitle = null;
      AppRouter.pendingPlanPrice = null;
      AppRouter.pendingPlanSubtitle = null;
      AppRouter.isCampus = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              planTitle: title,
              planPrice: price,
              planSubtitle: subtitle,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeNotifier.value;

    if (_isLoading) {
      return Scaffold(
        body: AnimatedBackground(
          isDarkMode: isDark,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF155DFC)),
            ),
          ),
        ),
      );
    }

    final showLandingPage = _paymentPlan == 'Free Plan' && AppRouter.pendingPlanTitle == null && !AppRouter.hasClickedLogin;

    if (showLandingPage) {
      return const LandingPageScreen();
    }

    if (_isProfileIncomplete) {
      return Scaffold(
        body: AnimatedBackground(
          isDarkMode: isDark,
          child: ProfileOnboardingScreen(
            pendingPlanTitle: AppRouter.pendingPlanTitle,
            pendingPlanPrice: AppRouter.pendingPlanPrice,
            pendingPlanSubtitle: AppRouter.pendingPlanSubtitle,
            isCampus: AppRouter.isCampus,
          ),
        ),
      );
    }

    return PremiumDashboard(
      userName: _userName,
      paymentPlan: _paymentPlan,
      email: _email,
    );
  }
}
