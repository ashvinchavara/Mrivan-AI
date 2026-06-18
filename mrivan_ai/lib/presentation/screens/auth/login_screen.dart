import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';
import '../../theme/theme_config.dart';



class LoginScreen extends StatefulWidget {
  final String? pendingPlanTitle;
  final String? pendingPlanPrice;
  final String? pendingPlanSubtitle;
  final bool isCampus;

  const LoginScreen({
    super.key,
    this.pendingPlanTitle,
    this.pendingPlanPrice,
    this.pendingPlanSubtitle,
    this.isCampus = false,
  });

  static const String webClientId =
      '524472321619-ft3dc0catvgplebulv2bqrpakdi8uo18.apps.googleusercontent.com';
  static const String androidClientId =
      '524472321619-06jghr6deij7ig11u2smbk2gts6scn1k.apps.googleusercontent.com';
  static const String iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF155DFC);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _teal = Color(0xFF0FBAA6);
  static const Color _amber = Color(0xFFFFB020);
  static const Color _rose = Color(0xFFF05A7E);

  late final StreamSubscription<AuthState> _authSubscription;
  late final AnimationController _entryController;
  bool _isLoading = false;

  bool get _hasPendingPlan =>
      widget.pendingPlanTitle != null && widget.pendingPlanPrice != null;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (data.event == AuthChangeEvent.signedIn && session != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in as ${session.user.email}'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        final uri = Uri.base;
        final safePath = uri.path.isEmpty ? '/' : uri.path;

        String redirectUrl = Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port,
          path: safePath,
        ).toString();

        if (_hasPendingPlan) {
          redirectUrl = Uri(
            scheme: uri.scheme,
            host: uri.host,
            port: uri.port,
            path: safePath,
            queryParameters: {
              'plan_title': widget.pendingPlanTitle,
              'plan_price': widget.pendingPlanPrice,
              'plan_subtitle': widget.pendingPlanSubtitle ?? '',
            },
          ).toString();
        }

        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
        );
        return;
      }

      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? LoginScreen.iosClientId
            : null,
        serverClientId: LoginScreen.webClientId,
      );

      await googleSignIn.signOut().catchError((_) => null);

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception(
          "Google did not return an ID token.\n\n"
          "Verify your Android SHA-1 fingerprint, web client ID, package name, "
          "and OAuth consent screen in Google Cloud Console.",
        );
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session == null) {
        throw Exception('Supabase login failed');
      }



      if (!mounted) return;

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      var errorMessage = e.toString();
      if (errorMessage.contains('ApiException: 10')) {
        errorMessage =
            'Google Sign-In Developer Error (ApiException 10).\n\n'
            'Register the Android SHA-1 certificate fingerprint in Google Cloud Console '
            'and confirm package name com.ash.mrivan_ai matches the OAuth client.';
      } else if (errorMessage.contains('ApiException: 12500')) {
        errorMessage =
            'Google Sign-In Error (ApiException 12500).\n\n'
            'Check the OAuth consent screen and Google Cloud project configuration.';
      }

      if (kDebugMode) {
        print('Google Sign-In Error Details: $e');
      }

      if (mounted) {
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = isDarkModeNotifier.value;
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
                child: const Icon(Icons.error_outline_rounded, color: _rose),
              ),
              const SizedBox(width: 12),
              Text(
                'Authentication Error',
                style: TextStyle(
                  color: isDark ? Colors.white : _ink,
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
                color: isDark ? Colors.white70 : Colors.black87,
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
            child: Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: 16,
                  right: 16,
                  child: _buildNavBar(isDarkMode, isDesktop),
                ),
                Positioned.fill(
                  top: MediaQuery.of(context).padding.top + 82,
                  child: SafeArea(
                    top: false,
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
                              constraints: const BoxConstraints(maxWidth: 1080),
                              child: isDesktop
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildStoryPanel(isDarkMode),
                                              const SizedBox(height: 18),
                                              _buildHowItWorks(isDarkMode),
                                              const SizedBox(height: 18),
                                              _buildSocialProof(isDarkMode),
                                              const SizedBox(height: 18),
                                              _buildFooter(isDarkMode),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        SizedBox(
                                          width: 420,
                                          child: _buildLoginCard(isDarkMode),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildLoginCard(isDarkMode),
                                        const SizedBox(height: 18),
                                        _buildStoryPanel(isDarkMode),
                                        const SizedBox(height: 18),
                                        _buildHowItWorks(isDarkMode),
                                        const SizedBox(height: 18),
                                        _buildSocialProof(isDarkMode),
                                        const SizedBox(height: 18),
                                        _buildFooter(isDarkMode),
                                      ],
                                    ),
                            ),
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
      },
    );
  }

  Widget _buildNavBar(bool isDarkMode, bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.60),
                border: Border.all(
                  color: isDarkMode ? Colors.white12 : Colors.white70,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/logo.jpeg',
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.school_rounded,
                        color: _primary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      children: [
                        TextSpan(
                          text: 'Mrivan',
                          style: TextStyle(color: Color(0xFF24BDEB)),
                        ),
                        TextSpan(
                          text: ' AI',
                          style: TextStyle(color: Color(0xFFFF8B53)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: isDarkMode ? 'Switch to focus mode' : 'Switch to night study mode',
                    child: IconButton(
                      onPressed: () => isDarkModeNotifier.value = !isDarkMode,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: Icon(
                          isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          key: ValueKey(isDarkMode),
                          color: isDarkMode ? _amber : _primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(bool isDarkMode) {
    return _glassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: isDarkMode ? 0.22 : 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logo.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.login_rounded,
                    color: _primary,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _hasPendingPlan ? 'Secure your plan' : 'Welcome back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              height: 1.12,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasPendingPlan
                ? 'Sign in once to activate checkout and keep your learning workspace synced.'
                : 'Sign in to continue to your AI tutor, study cockpit, and school CRM tools.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
          if (_hasPendingPlan) ...[
            const SizedBox(height: 20),
            _buildPendingPlanCard(isDarkMode),
          ],
          const SizedBox(height: 26),
          _isLoading
              ? Container(
                  height: 54,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                    ),
                  ),
                )
              : _AnimatedPressButton(
                  onTap: _handleGoogleSignIn,
                  isDarkMode: isDarkMode,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://developers.google.com/identity/images/g-logo.png',
                        height: 20,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.g_mobiledata_rounded, color: _primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : _ink,
                        ),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _trustPill(Icons.security_rounded, 'Secure login', isDarkMode),
              _trustPill(Icons.sync_rounded, 'Synced workspace', isDarkMode),
              _trustPill(Icons.school_rounded, 'Role aware', isDarkMode),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'By continuing, you agree to our Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: isDarkMode ? Colors.white30 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPlanCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: isDarkMode ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pendingPlanTitle ?? 'Selected plan',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.pendingPlanSubtitle ?? 'Ready for checkout',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.pendingPlanPrice ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryPanel(bool isDarkMode) {
    return _glassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionPill(Icons.auto_awesome_rounded, 'Your learning command center', isDarkMode),
          const SizedBox(height: 22),
          Text(
            'One sign-in opens the tutor, CRM, tests, notes, and progress trail.',
            style: TextStyle(
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : _ink,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mrivan AI keeps the student flow simple: authenticate, complete your profile, choose a study mode, and continue learning with synced dashboards.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth > 520;
              final cards = [
                _StoryCardData(Icons.psychology_rounded, 'AI Tutor', 'Doubts, voice help, explanations'),
                _StoryCardData(Icons.fact_check_rounded, 'CBT Tests', 'Mock tests and weak-area analytics'),
                _StoryCardData(Icons.assignment_rounded, 'Homework', 'Tasks, notes, and study planner'),
                _StoryCardData(Icons.dashboard_customize_rounded, 'CRM', 'School, parent, and teacher views'),
              ];
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: twoColumns ? 2 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: twoColumns ? 2.45 : 3.5,
                children: cards.map((card) => _storyTile(card, isDarkMode)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _storyTile(_StoryCardData card, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(card.icon, color: _primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  card.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
    required bool isDarkMode,
    required Widget child,
    required EdgeInsets padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.white.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.22 : 0.06),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionPill(IconData icon, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: isDarkMode ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white70 : _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustPill(IconData icon, String label, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: _teal),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks(bool isDarkMode) {
    return _glassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionPill(Icons.route_rounded, 'How it works', isDarkMode),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              final steps = [
                _stepItem('1', 'Sign in with Google', 'Secure OAuth login', _primary, isDarkMode),
                _stepItem('2', 'Set up your profile', 'Name, class & grade', _teal, isDarkMode),
                _stepItem('3', 'Start learning', 'AI tutor, notes & tests', _amber, isDarkMode),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: steps[0]),
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0, left: 8.0, right: 8.0),
                      child: Container(
                        height: 1,
                        width: 28,
                        color: isDarkMode ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    Expanded(child: steps[1]),
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0, left: 8.0, right: 8.0),
                      child: Container(
                        height: 1,
                        width: 28,
                        color: isDarkMode ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    Expanded(child: steps[2]),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    steps[0],
                    const SizedBox(height: 18),
                    steps[1],
                    const SizedBox(height: 18),
                    steps[2],
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _stepItem(String number, String title, String subtitle, Color color, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : _ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialProof(bool isDarkMode) {
    return _glassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _metricItem(Icons.people_rounded, '500+', 'Students', _primary, isDarkMode),
          _metricItem(Icons.psychology_rounded, '10k+', 'AI Sessions', _teal, isDarkMode),
          _metricItem(Icons.thumb_up_rounded, '98%', 'Satisfaction', _amber, isDarkMode),
        ],
      ),
    );
  }

  Widget _metricItem(IconData icon, String value, String label, Color color, bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/logo.jpeg',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Mrivan AI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? Colors.white : _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '© 2025 Mrivan AI • Privacy • Terms',
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.white30 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPressButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isDarkMode;

  const _AnimatedPressButton({
    required this.onTap,
    required this.child,
    required this.isDarkMode,
  });

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.018 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.white.withValues(alpha: _hovered ? 0.12 : 0.08)
                    : Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered
                      ? const Color(0xFF155DFC)
                      : (widget.isDarkMode ? Colors.white12 : Colors.black12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF155DFC).withValues(alpha: _hovered ? 0.18 : 0.08),
                    blurRadius: _hovered ? 22 : 12,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryCardData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StoryCardData(this.icon, this.title, this.subtitle);
}
