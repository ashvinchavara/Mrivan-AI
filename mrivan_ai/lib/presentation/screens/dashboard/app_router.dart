import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'premium_dashboard.dart';
import '../auth/profile_onboarding_screen.dart';
import '../auth/payment_screen.dart';
import '../auth/campus_payment_screen.dart';
import '../../theme/theme_config.dart';
import '../../widgets/animated_background.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  static final profileUpdatedNotifier = ValueNotifier<int>(0);

  static void notifyProfileUpdated() {
    profileUpdatedNotifier.value++;
  }

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

    // Check for pending plan redirect (on Web / redirect flows)
    _checkPendingPlanRedirect();
  }

  void _checkPendingPlanRedirect() {
    if (_isProfileIncomplete) return; // Don't redirect until profile is completed

    final uri = Uri.base;
    final planTitle = uri.queryParameters['plan_title'];
    final planPrice = uri.queryParameters['plan_price'];
    final planSubtitle = uri.queryParameters['plan_subtitle'];

    if (planTitle != null && planPrice != null) {
      // Clear query parameters in URL to prevent redirect loop on reload
      SystemNavigator.routeInformationUpdated(uri: Uri.parse('/'));
      
      final isCampus = planTitle.toLowerCase().contains('campus');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => isCampus
              ? CampusPaymentScreen(
                  planTitle: planTitle,
                  planPrice: planPrice,
                  planSubtitle: planSubtitle ?? '',
                )
              : PaymentScreen(
                  planTitle: planTitle,
                  planPrice: planPrice,
                  planSubtitle: planSubtitle ?? '',
                ),
        ),
      );
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

    if (_isProfileIncomplete) {
      final uri = Uri.base;
      final planTitle = uri.queryParameters['plan_title'];
      final planPrice = uri.queryParameters['plan_price'];
      final planSubtitle = uri.queryParameters['plan_subtitle'];
      final isCampus = planTitle != null && planTitle.toLowerCase().contains('campus');

      return Scaffold(
        body: AnimatedBackground(
          isDarkMode: isDark,
          child: ProfileOnboardingScreen(
            pendingPlanTitle: planTitle,
            pendingPlanPrice: planPrice,
            pendingPlanSubtitle: planSubtitle,
            isCampus: isCampus,
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
