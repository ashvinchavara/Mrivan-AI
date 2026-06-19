import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';
import '../../theme/theme_config.dart';
import '../dashboard/app_router.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _heroController;
  final GlobalKey _pricingSectionKey = GlobalKey();
  final GlobalKey _featuresSectionKey = GlobalKey();
  int _selectedFeatureCluster = 0;

  static const Color _primary = Color(0xFF155DFC);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _teal = Color(0xFF0FBAA6);
  static const Color _amber = Color(0xFFFFB020);
  static const Color _rose = Color(0xFFF05A7E);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  bool _isAuthLoading = false;

  static const String webClientId =
      '524472321619-ft3dc0catvgplebulv2bqrpakdi8uo18.apps.googleusercontent.com';

  Future<void> _navigateToLogin({
    String? planTitle,
    String? planPrice,
    String? planSubtitle,
    bool isCampus = false,
  }) async {
    setState(() => _isAuthLoading = true);

    try {
      AppRouter.pendingPlanTitle = planTitle;
      AppRouter.pendingPlanPrice = planPrice;
      AppRouter.pendingPlanSubtitle = planSubtitle;
      AppRouter.isCampus = isCampus;
      AppRouter.hasClickedLogin = true;

      if (Supabase.instance.client.auth.currentSession != null) {
        AppRouter.notifyProfileUpdated();
        setState(() => _isAuthLoading = false);
        return;
      }

      if (kIsWeb) {
        final uri = Uri.base;
        final safePath = uri.path.isEmpty ? '/' : uri.path;

        String redirectUrl = Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port,
          path: safePath,
        ).toString();

        if (planTitle != null && planPrice != null) {
          redirectUrl = Uri(
            scheme: uri.scheme,
            host: uri.host,
            port: uri.port,
            path: safePath,
            queryParameters: {
              'plan_title': planTitle,
              'plan_price': planPrice,
              'plan_subtitle': planSubtitle ?? '',
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
        serverClientId: webClientId,
      );

      await googleSignIn.signOut().catchError((_) => null);

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isAuthLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception("Google did not return an ID token.");
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session == null) {
        throw Exception('Supabase login failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthLoading = false);
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

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;
    final isTablet = screenWidth >= 720;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return Scaffold(
          body: AnimatedBackground(
            isDarkMode: isDarkMode,
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 40 : 18,
                      MediaQuery.of(context).padding.top + 92,
                      isDesktop ? 40 : 18,
                      28,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1220),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ScrollFadeIn(
                              controller: _scrollController,
                              child: _buildHeroSection(isDarkMode, isDesktop),
                            ),
                            const SizedBox(height: 40),
                            ScrollFadeIn(
                              controller: _scrollController,
                              delayMs: 80,
                              child: _buildStatsStrip(isDarkMode, isTablet),
                            ),
                            const SizedBox(height: 58),
                            ScrollFadeIn(
                              key: _featuresSectionKey,
                              controller: _scrollController,
                              child: _buildSectionHeader(
                                isDarkMode,
                                'One Workspace For Learning And School Ops',
                                'Students learn, teachers manage, parents stay informed, and schools see the whole picture.',
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildAudienceGrid(isDarkMode, isDesktop),
                            const SizedBox(height: 58),
                            ScrollFadeIn(
                              controller: _scrollController,
                              child: _buildFeatureStudio(isDarkMode, isDesktop),
                            ),
                            const SizedBox(height: 58),
                            ScrollFadeIn(
                              controller: _scrollController,
                              child: _buildWorkflowSection(isDarkMode, isDesktop),
                            ),
                            const SizedBox(height: 58),
                            ScrollFadeIn(
                              key: _pricingSectionKey,
                              controller: _scrollController,
                              child: _buildSectionHeader(
                                isDarkMode,
                                'Plans For Students, Schools, And Power Users',
                                'Start free, upgrade for unlimited AI tutoring, or bring your whole campus online.',
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildPricingGrid(isDarkMode, isDesktop),
                            const SizedBox(height: 58),
                            ScrollFadeIn(
                              controller: _scrollController,
                              child: _buildRoadmapSection(isDarkMode),
                            ),
                            const SizedBox(height: 58),
                            ScrollFadeIn(
                              controller: _scrollController,
                              child: _buildFinalCta(isDarkMode, isDesktop),
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: Text(
                                'Copyright 2026 Mrivan AI CRM & AI Tutor. All rights reserved.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: isDesktop ? 40 : 16,
                  right: isDesktop ? 40 : 16,
                  child: _buildNavBar(isDarkMode, isDesktop),
                ),
                if (_isAuthLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF155DFC)),
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
                  if (isDesktop) ...[
                    const Spacer(),
                    _buildNavLink('Features', () => _scrollTo(_featuresSectionKey), isDarkMode),
                    _buildNavLink('Pricing', () => _scrollTo(_pricingSectionKey), isDarkMode),
                    _buildNavLink('Campus CRM', () => _scrollTo(_featuresSectionKey), isDarkMode),
                  ],
                  const Spacer(),
                  Tooltip(
                    message: isDarkMode ? 'Switch to focus mode' : 'Switch to night study mode',
                    child: IconButton(
                      onPressed: () => isDarkModeNotifier.value = !isDarkMode,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          key: ValueKey(isDarkMode),
                          color: isDarkMode ? _amber : _primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _navigateToLogin(),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(isDesktop ? 'Login' : 'Start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildNavLink(String text, VoidCallback onTap, bool isDarkMode) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isDarkMode ? Colors.white70 : _ink.withValues(alpha: 0.72),
      ),
      child: Text(text),
    );
  }

  Widget _buildHeroSection(bool isDarkMode, bool isDesktop) {
    final textColumn = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        _buildPill(
          icon: Icons.auto_awesome_rounded,
          label: 'AI Tutor + School CRM in one platform',
          isDarkMode: isDarkMode,
          color: _primary,
        ),
        const SizedBox(height: 20),
        Text(
          'A personal AI teacher for every student, with a CRM for every school.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 56 : 34,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: isDarkMode ? Colors.white : _ink,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Mrivan AI helps students solve doubts, build notes, practice CBT tests, and follow personalized study plans while schools manage attendance, homework, analytics, parents, and teacher workflows.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 17 : 15,
            height: 1.55,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => _scrollTo(_pricingSectionKey),
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Explore Plans'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 52),
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _scrollTo(_featuresSectionKey),
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: const Text('View Platform'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 52),
                foregroundColor: isDarkMode ? Colors.white : _ink,
                side: BorderSide(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _buildMiniTrustItem(Icons.translate_rounded, 'Multilingual'),
            _buildMiniTrustItem(Icons.mic_rounded, 'Voice ready'),
            _buildMiniTrustItem(Icons.security_rounded, 'Secure cloud'),
            _buildMiniTrustItem(Icons.devices_rounded, 'Multi-device'),
          ],
        ),
      ],
    );

    if (!isDesktop) {
      return Column(
        children: [
          textColumn,
          const SizedBox(height: 28),
          _buildHeroPreview(isDarkMode),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 11, child: textColumn),
        const SizedBox(width: 36),
        Expanded(flex: 10, child: _buildHeroPreview(isDarkMode)),
      ],
    );
  }

  Widget _buildHeroPreview(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, child) {
        final lift = lerpDouble(0, -10, Curves.easeInOut.transform(_heroController.value))!;
        return Transform.translate(
          offset: Offset(0, lift),
          child: child,
        );
      },
      child: _buildGlassCard(
        isDarkMode: isDarkMode,
        padding: const EdgeInsets.all(18),
        borderRadius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPreviewDot(_rose),
                const SizedBox(width: 6),
                _buildPreviewDot(_amber),
                const SizedBox(width: 6),
                _buildPreviewDot(_teal),
                const Spacer(),
                _buildPill(
                  icon: Icons.bolt_rounded,
                  label: 'Live learning cockpit',
                  isDarkMode: isDarkMode,
                  color: _teal,
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 430;
                if (!isWide) {
                  return Column(
                    children: [
                      _buildTutorPanel(isDarkMode),
                      const SizedBox(height: 14),
                      _buildCrmPanel(isDarkMode),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildTutorPanel(isDarkMode)),
                    const SizedBox(width: 14),
                    Expanded(flex: 5, child: _buildCrmPanel(isDarkMode)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorPanel(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softPanelDecoration(isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_alt_rounded, color: _primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Tutor',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDarkMode ? Colors.white : _ink,
                      ),
                    ),
                    Text(
                      'Class 10 Physics',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.graphic_eq_rounded, color: _teal),
            ],
          ),
          const SizedBox(height: 16),
          _buildChatBubble(
            'Explain refraction with a daily-life example.',
            isDarkMode,
            isUser: true,
          ),
          const SizedBox(height: 10),
          _buildChatBubble(
            'Think of a straw in a glass of water. Light changes speed when it enters water, so the straw appears bent. Want a diagram next?',
            isDarkMode,
            isUser: false,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildProgressLine(_primary, 0.88)),
              const SizedBox(width: 10),
              Expanded(child: _buildProgressLine(_teal, 0.62)),
              const SizedBox(width: 10),
              Expanded(child: _buildProgressLine(_amber, 0.74)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrmPanel(bool isDarkMode) {
    return Column(
      children: [
        _buildMetricTile(isDarkMode, Icons.co_present_rounded, 'Attendance', '94%', _teal),
        const SizedBox(height: 12),
        _buildMetricTile(isDarkMode, Icons.assignment_turned_in_rounded, 'Homework', '37 due', _primary),
        const SizedBox(height: 12),
        _buildMetricTile(isDarkMode, Icons.analytics_rounded, 'Weak Areas', 'Math + Chem', _rose),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _softPanelDecoration(isDarkMode),
          child: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: _amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Parent update sent',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isDarkMode, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? _primary
              : (isDarkMode ? Colors.white.withValues(alpha: 0.07) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: isUser
              ? null
              : Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            color: isUser ? Colors.white : (isDarkMode ? Colors.white70 : _ink),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsStrip(bool isDarkMode, bool isTablet) {
    final stats = [
      ('24x7', 'AI tutor access'),
      ('6', 'pricing paths'),
      ('4', 'dashboards'),
      ('100+', 'learning tools'),
    ];

    return _buildGlassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: GridView.count(
        crossAxisCount: isTablet ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: isTablet ? 2.6 : 2.2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: stats.map((stat) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.$1,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stat.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAudienceGrid(bool isDarkMode, bool isDesktop) {
    final cards = [
      _AudienceCardData(
        icon: Icons.school_rounded,
        title: 'Students',
        subtitle: 'Doubts, homework, notes, quizzes, AI summaries, voice tutor, and study plans.',
        color: _primary,
      ),
      _AudienceCardData(
        icon: Icons.admin_panel_settings_rounded,
        title: 'School Admins',
        subtitle: 'School dashboard, bulk accounts, attendance, analytics, branding, and controls.',
        color: _teal,
      ),
      _AudienceCardData(
        icon: Icons.co_present_rounded,
        title: 'Teachers',
        subtitle: 'Homework management, assignment generation, test insights, and class progress.',
        color: _amber,
      ),
      _AudienceCardData(
        icon: Icons.family_restroom_rounded,
        title: 'Parents',
        subtitle: 'Portal updates, attendance visibility, homework tracking, and performance signals.',
        color: _rose,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.05 : 1.55,
      ),
      itemBuilder: (context, index) {
        return ScrollFadeIn(
          controller: _scrollController,
          delayMs: 80.0 * index,
          beginOffset: const Offset(0, 0.08),
          child: _HoverLift(
            child: _buildAudienceCard(cards[index], isDarkMode),
          ),
        );
      },
    );
  }

  Widget _buildAudienceCard(_AudienceCardData data, bool isDarkMode) {
    return _buildGlassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.42,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureStudio(bool isDarkMode, bool isDesktop) {
    final clusters = _featureClusters;
    final selected = clusters[_selectedFeatureCluster];

    final selector = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(clusters.length, (index) {
        final cluster = clusters[index];
        final isSelected = index == _selectedFeatureCluster;
        return ChoiceChip(
          selected: isSelected,
          showCheckmark: false,
          avatar: Icon(
            cluster.icon,
            size: 18,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.white70 : _ink.withValues(alpha: 0.65)),
          ),
          label: Text(cluster.title),
          onSelected: (_) => setState(() => _selectedFeatureCluster = index),
          selectedColor: cluster.color,
          backgroundColor: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.72),
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.white70 : _ink.withValues(alpha: 0.72)),
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isSelected
                  ? cluster.color
                  : (isDarkMode ? Colors.white12 : Colors.black12),
            ),
          ),
        );
      }),
    );

    final details = AnimatedSwitcher(
      duration: const Duration(milliseconds: 330),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildFeatureDetailCard(selected, isDarkMode),
    );

    return _buildGlassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(22),
      borderRadius: 24,
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        isDarkMode,
                        'Feature Studio',
                        'Choose a platform area to see what is included.',
                        alignLeft: true,
                      ),
                      const SizedBox(height: 22),
                      selector,
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  isDarkMode,
                  'Feature Studio',
                  'Choose a platform area to see what is included.',
                  alignLeft: true,
                ),
                const SizedBox(height: 18),
                selector,
                const SizedBox(height: 22),
                details,
              ],
            ),
    );
  }

  Widget _buildFeatureDetailCard(_FeatureClusterData data, bool isDarkMode) {
    return Container(
      key: ValueKey(data.title),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: data.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 720 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: MediaQuery.of(context).size.width > 720 ? 4.3 : 5.4,
            children: data.items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: data.color, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white70 : _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowSection(bool isDarkMode, bool isDesktop) {
    final steps = [
      _WorkflowStepData(Icons.person_add_alt_1_rounded, 'Join', 'Student, teacher, parent, or school admin signs in with a role-aware setup.'),
      _WorkflowStepData(Icons.tune_rounded, 'Personalize', 'Class, subject, language, exam goals, and school context shape the workspace.'),
      _WorkflowStepData(Icons.auto_awesome_motion_rounded, 'Learn + Manage', 'AI tutoring, tests, homework, attendance, notes, and dashboards run together.'),
      _WorkflowStepData(Icons.insights_rounded, 'Improve', 'Analytics identify weak areas, pending work, revision plans, and school performance signals.'),
    ];

    return Column(
      children: [
        _buildSectionHeader(
          isDarkMode,
          'A Cleaner User Flow',
          'Every user lands in the right workspace and sees the next action quickly.',
        ),
        const SizedBox(height: 22),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 1,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 1.04 : 1.75,
          ),
          itemBuilder: (context, index) {
            final step = steps[index];
            return ScrollFadeIn(
              controller: _scrollController,
              delayMs: 90.0 * index,
              beginOffset: const Offset(0, 0.08),
              child: _buildWorkflowCard(step, index + 1, isDarkMode),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkflowCard(_WorkflowStepData step, int number, bool isDarkMode) {
    return _HoverLift(
      child: _buildGlassCard(
        isDarkMode: isDarkMode,
        padding: const EdgeInsets.all(18),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(step.icon, color: _primary),
                ),
                const Spacer(),
                Text(
                  number.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white12 : Colors.black12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              step.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.42,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingGrid(bool isDarkMode, bool isDesktop) {
    final plans = _plans;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: List.generate(plans.length, (index) {
        return ScrollFadeIn(
          controller: _scrollController,
          delayMs: index * 80.0,
          beginOffset: const Offset(0, 0.08),
          child: _buildPlanCard(
            plans[index],
            isDarkMode,
            width: isDesktop ? 388 : double.infinity,
          ),
        );
      }),
    );
  }

  Widget _buildPlanCard(_PlanData plan, bool isDarkMode, {required double width}) {
    return SizedBox(
      width: width,
      child: _HoverLift(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: plan.isRecommended
                ? Border.all(color: _primary.withValues(alpha: 0.55), width: 1.5)
                : null,
            boxShadow: plan.isRecommended
                ? [
                    BoxShadow(
                      color: _primary.withValues(alpha: isDarkMode ? 0.22 : 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ]
                : null,
          ),
          child: _buildGlassCard(
            isDarkMode: isDarkMode,
            padding: const EdgeInsets.all(22),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: plan.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(plan.icon, color: plan.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDarkMode ? Colors.white : _ink,
                            ),
                          ),
                          Text(
                            plan.subtitle,
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
                if (plan.isRecommended) ...[
                  const SizedBox(height: 14),
                  _buildPill(
                    icon: Icons.star_rounded,
                    label: 'Recommended for serious learners',
                    isDarkMode: isDarkMode,
                    color: _primary,
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        plan.price,
                        style: TextStyle(
                          fontSize: plan.price.length > 12 ? 25 : 34,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? Colors.white : _ink,
                        ),
                      ),
                    ),
                    if (plan.cadence.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          plan.cadence,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: isDarkMode ? Colors.white10 : Colors.black12),
                const SizedBox(height: 10),
                ...plan.features.take(7).map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.done_rounded, color: plan.color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.32,
                              color: isDarkMode ? Colors.white70 : _ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (plan.features.length > 7)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '+ ${plan.features.length - 7} more included features',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: plan.color,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: plan.isCampus
                      ? OutlinedButton.icon(
                          onPressed: () => _navigateToLogin(
                            planTitle: plan.title,
                            planPrice: plan.price,
                            planSubtitle: plan.subtitle,
                            isCampus: true,
                          ),
                          icon: const Icon(Icons.business_rounded, size: 18),
                          label: Text(plan.cta),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode ? Colors.white : _ink,
                            side: BorderSide(color: plan.color.withValues(alpha: 0.7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            if (plan.price == 'Free') {
                              _navigateToLogin();
                            } else {
                              _navigateToLogin(
                                planTitle: plan.title,
                                planPrice: plan.price,
                                planSubtitle: plan.subtitle,
                                isCampus: plan.isCampus,
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(plan.cta),
                          style: FilledButton.styleFrom(
                            backgroundColor: plan.isRecommended ? _primary : plan.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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

  Widget _buildRoadmapSection(bool isDarkMode) {
    final futureFeatures = [
      'Live AI classes',
      'Scholarship finder',
      'College admission assistant',
      'AI interview preparation',
      'AI resume builder',
      'AI project generator',
      'Offline learning mode',
      'Career guidance journeys',
    ];

    return _buildGlassCard(
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDarkMode,
            'Future-Ready Roadmap',
            'Recommended next modules that fit the AI tutor + school CRM direction.',
            alignLeft: true,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: futureFeatures.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_task_rounded, color: _teal, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white70 : _ink,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalCta(bool isDarkMode, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 36 : 24),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.30),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildFinalCtaText()),
                const SizedBox(width: 28),
                _buildFinalCtaActions(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinalCtaText(),
                const SizedBox(height: 22),
                _buildFinalCtaActions(),
              ],
            ),
    );
  }

  Widget _buildFinalCtaText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Build the school operating system around the AI tutor.',
          style: TextStyle(
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Launch with students today, then expand into attendance, homework, parent communication, analytics, exams, and campus branding.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFinalCtaActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () => _scrollTo(_pricingSectionKey),
          icon: const Icon(Icons.workspace_premium_rounded),
          label: const Text('Choose Plan'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(152, 52),
            backgroundColor: Colors.white,
            foregroundColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _navigateToLogin(),
          icon: const Icon(Icons.login_rounded),
          label: const Text('Login'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(132, 52),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    bool isDarkMode,
    String title,
    String subtitle, {
    bool alignLeft = false,
  }) {
    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            height: 1.16,
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.48,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required bool isDarkMode,
    required Widget child,
    required EdgeInsets padding,
    double borderRadius = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.26)
                : Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.09)
                  : Colors.white.withValues(alpha: 0.72),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.16 : 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? Colors.white70 : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTrustItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _teal, size: 16),
          const SizedBox(width: 7),
          const Text(
            '',
            style: TextStyle(fontSize: 0),
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  BoxDecoration _softPanelDecoration(bool isDarkMode) {
    return BoxDecoration(
      color: isDarkMode
          ? Colors.white.withValues(alpha: 0.055)
          : Colors.white.withValues(alpha: 0.70),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
      ),
    );
  }

  Widget _buildMetricTile(
    bool isDarkMode,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softPanelDecoration(isDarkMode),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white.withValues(alpha: 0.46) : Colors.black45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

  Widget _buildProgressLine(Color color, double value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 7,
        value: value,
        color: color,
        backgroundColor: color.withValues(alpha: 0.13),
      ),
    );
  }

  List<_FeatureClusterData> get _featureClusters => const [
        _FeatureClusterData(
          icon: Icons.auto_awesome_rounded,
          title: 'AI Learning',
          color: _primary,
          items: [
            'AI Tutor for all subjects and classes',
            'Multilingual learning support',
            'Voice-based learning',
            'Personalized learning paths',
            'Concept explanations with examples',
            'Doubt-solving assistant',
            'Homework help',
            'Assignment generation',
            'Notes generation',
            'Study planner',
          ],
        ),
        _FeatureClusterData(
          icon: Icons.business_center_rounded,
          title: 'School CRM',
          color: _teal,
          items: [
            'School dashboard',
            'Teacher dashboard',
            'Student dashboard',
            'Attendance management',
            'Homework tracking',
            'Parent portal',
            'Announcements and notices',
            'School analytics',
            'Bulk student onboarding',
            'Custom branding',
          ],
        ),
        _FeatureClusterData(
          icon: Icons.fact_check_rounded,
          title: 'Exam Prep',
          color: _rose,
          items: [
            'CBT simulations',
            'Mock tests for school exams',
            'Competitive exam preparation',
            'Adaptive testing',
            'Previous year question analysis',
            'Performance analytics',
            'Weak area identification',
            'Revision schedules',
          ],
        ),
        _FeatureClusterData(
          icon: Icons.library_books_rounded,
          title: 'Content Library',
          color: _amber,
          items: [
            'NCERT solutions',
            'Study materials',
            'Question banks',
            'Practice worksheets',
            'Video lessons',
            'Interactive quizzes',
            'Peer learning groups',
            'Mentor support',
          ],
        ),
        _FeatureClusterData(
          icon: Icons.handyman_rounded,
          title: 'AI Productivity',
          color: Color(0xFF7C3AED),
          items: [
            'AI Chat Assistant',
            'AI Writing Assistant',
            'AI Research Assistant',
            'AI Presentation Generator',
            'AI Image Generation',
            'AI Summarization',
            'AI Translation',
            'AI Coding Tutor',
            'AI Career Counselor',
          ],
        ),
        _FeatureClusterData(
          icon: Icons.cloud_done_rounded,
          title: 'Platform',
          color: Color(0xFF2563EB),
          items: [
            'Cloud-based access',
            'Mobile-friendly platform',
            'Secure data storage',
            'Scalable infrastructure',
            'Multi-device synchronization',
            '24/7 availability',
            'School-wide licenses',
            'Dedicated support',
          ],
        ),
      ];

  List<_PlanData> get _plans => const [
        _PlanData(
          icon: Icons.menu_book_rounded,
          title: 'Free Plan',
          price: 'Free',
          paymentPrice: 'Free',
          cadence: '',
          subtitle: 'For first-time learners',
          cta: 'Start Free',
          color: _teal,
          features: [
            'Limited AI Tutor chats',
            '5 doubt solutions/day',
            'Basic notes',
            'Limited tests',
            'Community support',
          ],
        ),
        _PlanData(
          icon: Icons.bolt_rounded,
          title: 'Basic Plan',
          price: 'Rs 99',
          paymentPrice: '\u20B999',
          cadence: '/ month',
          subtitle: 'Affordable daily study help',
          cta: 'Get Basic',
          color: _primary,
          features: [
            'Unlimited doubts',
            'AI Tutor access',
            'Notes generation',
            'Homework help',
            'Weekly mock tests',
            'Progress tracking',
          ],
        ),
        _PlanData(
          icon: Icons.apartment_rounded,
          title: 'Campus Plan',
          price: 'Rs 149',
          paymentPrice: '\u20B9149',
          cadence: 'per student/month',
          subtitle: 'For schools and institutions',
          cta: 'Contact Campus',
          color: _teal,
          isCampus: true,
          features: [
            'School dashboard',
            'Teacher dashboard',
            'Parent dashboard',
            'Attendance Management',
            'Homework Management',
            'School Analytics',
            'Bulk Student Accounts',
            'Custom Branding',
            'Dedicated Support',
          ],
        ),
        _PlanData(
          icon: Icons.workspace_premium_rounded,
          title: 'Pro Student',
          price: 'Rs 299',
          paymentPrice: '\u20B9299',
          cadence: '/ month',
          subtitle: 'For personalized AI learning',
          cta: 'Upgrade To Pro',
          color: _primary,
          isRecommended: true,
          features: [
            'Everything in Basic',
            'Unlimited AI chats',
            'Personalized study plans',
            'Voice AI Tutor',
            'AI summaries',
            'AI quizzes',
            'Priority support',
          ],
        ),
        _PlanData(
          icon: Icons.military_tech_rounded,
          title: 'Exam Aspirant',
          price: 'Rs 499',
          paymentPrice: '\u20B9499',
          cadence: '/ month',
          subtitle: 'For exam-focused preparation',
          cta: 'Get Exam Plan',
          color: _rose,
          features: [
            'Everything in Pro',
            'CBT Mock Tests',
            'Previous Year Questions',
            'Performance analytics',
            'Revision planner',
            'Exam-specific AI mentor',
          ],
        ),
        _PlanData(
          icon: Icons.diamond_rounded,
          title: 'Premium AI',
          price: 'Rs 999',
          paymentPrice: '\u20B9999',
          cadence: '/ month',
          subtitle: 'For advanced AI productivity',
          cta: 'Get Premium',
          color: Color(0xFF7C3AED),
          features: [
            'Everything in Exam Aspirant',
            'AI Research Assistant',
            'AI Presentation Maker',
            'AI Image Generator',
            'AI Coding Tutor',
            'AI Career Counselor',
            'Early access features',
          ],
        ),
      ];
}

class ScrollFadeIn extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final double delayMs;
  final Offset beginOffset;

  const ScrollFadeIn({
    super.key,
    required this.child,
    required this.controller,
    this.delayMs = 0,
    this.beginOffset = const Offset(0.0, 0.1),
  });

  @override
  State<ScrollFadeIn> createState() => _ScrollFadeInState();
}

class _ScrollFadeInState extends State<ScrollFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacityAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    final curve = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(curve);
    _slideAnim = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curve);
    _scaleAnim = Tween<double>(begin: 0.97, end: 1).animate(curve);
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    _animController.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (!mounted || _hasAnimated) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    if (position.dy < screenHeight * 0.94 && position.dy > -renderBox.size.height) {
      _hasAnimated = true;
      widget.controller.removeListener(_checkVisibility);
      Future.delayed(Duration(milliseconds: widget.delayMs.toInt()), () {
        if (mounted) _animController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: FractionalTranslation(
              translation: _slideAnim.value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _HoverLift extends StatefulWidget {
  final Widget child;

  const _HoverLift({required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        scale: _hovered ? 1.018 : 1,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          offset: Offset(0, _hovered ? -0.012 : 0),
          child: widget.child,
        ),
      ),
    );
  }
}

class _AudienceCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AudienceCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _FeatureClusterData {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;

  const _FeatureClusterData({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });
}

class _WorkflowStepData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WorkflowStepData(this.icon, this.title, this.subtitle);
}

class _PlanData {
  final IconData icon;
  final String title;
  final String price;
  final String paymentPrice;
  final String cadence;
  final String subtitle;
  final String cta;
  final Color color;
  final List<String> features;
  final bool isRecommended;
  final bool isCampus;

  const _PlanData({
    required this.icon,
    required this.title,
    required this.price,
    required this.paymentPrice,
    required this.cadence,
    required this.subtitle,
    required this.cta,
    required this.color,
    required this.features,
    this.isRecommended = false,
    this.isCampus = false,
  });
}
