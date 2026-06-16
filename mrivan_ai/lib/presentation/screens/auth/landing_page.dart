import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/animated_background.dart';
import 'login_screen.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  bool? _isDarkModeState;
  bool get _isDarkMode => _isDarkModeState ?? false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkModeState ??= MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      body: AnimatedBackground(
        isDarkMode: _isDarkMode,
        child: Stack(
          children: [
            // 1. Navigation Header
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App Brand Logo
                        Row(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              color: const Color(0xFF155DFC),
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mrivan AI',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),

                        // Actions: Theme Switcher & Login
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                                color: _isDarkMode ? Colors.amber : Colors.indigo,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isDarkModeState = !_isDarkMode;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _navigateToLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isDarkMode ? Colors.white10 : const Color(0xFF155DFC),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Main Scrollable Landing Sections
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 80,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // SECTION 1: HERO
                    const SizedBox(height: 30),
                    ScrollFadeIn(
                      controller: _scrollController,
                      child: _buildHeroSection(isDesktop),
                    ),
                    
                    const SizedBox(height: 60),
                    // SECTION 2: FEATURES
                    ScrollFadeIn(
                      controller: _scrollController,
                      child: _buildSectionHeader('Powerful Features', 'Everything you need to master your syllabus'),
                    ),
                    const SizedBox(height: 24),
                    _buildFeaturesGrid(isDesktop),

                    const SizedBox(height: 60),
                    // SECTION 3: PRICING
                    ScrollFadeIn(
                      controller: _scrollController,
                      child: _buildSectionHeader('Pricing Plans', 'Choose the speed that matches your studies'),
                    ),
                    const SizedBox(height: 24),
                    _buildPricingGrid(isDesktop),

                    const SizedBox(height: 60),
                    // SECTION 4: CALL TO ACTION
                    ScrollFadeIn(
                      controller: _scrollController,
                      child: _buildCtaBanner(),
                    ),

                    const SizedBox(height: 40),
                    // FOOTER
                    Text(
                      '© 2026 Mrivan AI CRM & AI Tutor. All rights reserved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: _isDarkMode ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            // Top Highlight Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF155DFC).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF155DFC),
                  width: 1,
                ),
              ),
              child: Text(
                'Available 24×7 Across the Globe',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF155DFC),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Slogan 1
            Text(
              'A Personal AI Teacher\nFor Every Student On Earth',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 46 : 32,
                fontWeight: FontWeight.w900,
                color: _isDarkMode ? Colors.white : Colors.black87,
                height: 1.15,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),

            // Slogan 2 (Tagline)
            Text(
              'One AI Tutor. Unlimited Learning. Available 24×7.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 22 : 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF155DFC),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Meet Mrivan AI—your 24/7 hyper-personalized study partner. Learn, practice, and succeed in any subject or language. Solve math calculations, draft study notes, analyze complex concepts, and take CBT mock diagnostics instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 32),

            // Main CTA Button
            ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 56),
                backgroundColor: const Color(0xFF155DFC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                shadowColor: const Color(0xFF155DFC).withValues(alpha: 0.3),
                elevation: 10,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Learning Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(bool isDesktop) {
    return CategoryFeaturesWidget(
      isDarkMode: _isDarkMode,
      scrollController: _scrollController,
    );
  }

  Widget _buildPricingGrid(bool isDesktop) {
    final double cardWidth = isDesktop ? 300.0 : double.infinity;
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          // 1. Free Plan
          ScrollFadeIn(
            controller: _scrollController,
            delayMs: 0.0,
            beginOffset: const Offset(0.2, 0.0),
            beginRotation: 2 * pi,
            child: _buildPricingCard(
              title: 'Free Plan 📚',
              price: 'Free',
              subtitle: 'Essential features for single students',
              features: [
                'Limited AI Tutor chats',
                '5 doubt solutions/day',
                'Basic notes',
                'Limited tests',
                'Community support',
              ],
              ctaText: 'Start Free',
              isPremium: false,
              width: cardWidth,
            ),
          ),

          // 2. Basic Plan
          ScrollFadeIn(
            controller: _scrollController,
            delayMs: 100.0,
            beginOffset: const Offset(0.2, 0.0),
            beginRotation: 2 * pi,
            child: _buildPricingCard(
              title: 'Basic Plan ⚡',
              price: '₹99',
              subtitle: 'Affordable booster for self-study',
              features: [
                'Unlimited doubts',
                'AI Tutor access',
                'Notes generation',
                'Homework help',
                'Weekly mock tests',
                'Progress tracking',
              ],
              ctaText: 'Get Basic',
              isPremium: false,
              width: cardWidth,
            ),
          ),

          // 3. Campus Plan
          ScrollFadeIn(
            controller: _scrollController,
            delayMs: 200.0,
            beginOffset: const Offset(0.2, 0.0),
            beginRotation: 2 * pi,
            child: _buildPricingCard(
              title: 'Campus Plan 🏫',
              price: '₹49–99',
              subtitle: 'For schools and institutions',
              features: [
                'School Dashboard',
                'Teacher Dashboard',
                'Parent Dashboard',
                'Attendance Management',
                'Homework Management',
                'School Analytics',
                'Bulk Student Accounts',
                'Custom Branding',
                'Dedicated Support',
              ],
              ctaText: 'Contact School Admin',
              isPremium: false,
              width: cardWidth,
            ),
          ),

          // 4. Pro Student
          ScrollFadeIn(
            controller: _scrollController,
            delayMs: 300.0,
            beginOffset: const Offset(0.2, 0.0),
            beginRotation: 2 * pi,
            child: _buildPricingCard(
              title: 'Pro Student 🚀',
              price: '₹299',
              subtitle: 'Unlimited learning & AI tools',
              features: [
                'Everything in Basic',
                'Unlimited AI chats',
                'Personalized study plans',
                'Voice AI Tutor',
                'AI summaries',
                'AI quizzes',
                'Priority support',
              ],
              ctaText: 'Upgrade to Pro',
              isPremium: true,
              width: cardWidth,
            ),
          ),

          // 5. Exam Aspirant
          ScrollFadeIn(
            controller: _scrollController,
            delayMs: 400.0,
            beginOffset: const Offset(0.2, 0.0),
            beginRotation: 2 * pi,
            child: _buildPricingCard(
              title: 'Exam Aspirant 🎯',
              price: '₹499',
              subtitle: 'Cracking competitive tests',
              features: [
                'Everything in Pro',
                'CBT Mock Tests',
                'Previous Year Questions',
                'Performance analytics',
                'Revision planner',
                'Exam-specific AI mentor',
              ],
              ctaText: 'Get Aspirant Plan',
              isPremium: false,
              width: cardWidth,
            ),
          ),

          // 6. Premium AI
          ScrollFadeIn(
            controller: _scrollController,
            delayMs: 500.0,
            beginOffset: const Offset(0.2, 0.0),
            beginRotation: 2 * pi,
            child: _buildPricingCard(
              title: 'Premium AI 🤖',
              price: '₹999',
              subtitle: 'Ultimate researcher & advisor tools',
              features: [
                'Everything in Exam Aspirant',
                'AI Research Assistant',
                'AI Presentation Maker',
                'AI Image Generator',
                'AI Coding Tutor',
                'AI Career Counselor',
                'Early access features',
              ],
              ctaText: 'Get Ultimate AI',
              isPremium: false,
              width: cardWidth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String subtitle,
    required List<String> features,
    required String ctaText,
    required bool isPremium,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPremium) ...[
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF155DFC).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF155DFC),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: price.contains('–') ? 26 : 34,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (price != 'Free')
                  Text(
                    price.contains('–') ? ' per student/month' : ' / month',
                    style: TextStyle(
                      fontSize: 13,
                      color: _isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: _isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
            Divider(height: 32, color: _isDarkMode ? Colors.white12 : Colors.black12),
            ...features.map((feat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: isPremium 
                            ? const Color(0xFF155DFC) 
                            : (_isDarkMode ? Colors.tealAccent.shade400 : Colors.teal.shade700),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feat,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: isPremium 
                    ? const Color(0xFF155DFC) 
                    : Colors.transparent,
                foregroundColor: isPremium ? Colors.white : (_isDarkMode ? Colors.white : Colors.black87),
                elevation: 0,
                shadowColor: Colors.transparent,
                side: isPremium 
                    ? BorderSide.none 
                    : BorderSide(color: _isDarkMode ? Colors.white30 : Colors.black26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                ctaText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaBanner() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: _buildGlassCard(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text(
              'Join the Classroom of the Future',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to boost your classroom experience? Setup your account as a student, teacher, admin, or parent in seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: const Color(0xFF155DFC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Get Started Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required EdgeInsets padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ScrollFadeIn extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final double delayMs;
  final Offset beginOffset;
  final double beginRotation;

  const ScrollFadeIn({
    super.key,
    required this.child,
    required this.controller,
    this.delayMs = 0,
    this.beginOffset = const Offset(0.0, 0.1),
    this.beginRotation = 0.0,
  });

  @override
  State<ScrollFadeIn> createState() => _ScrollFadeInState();
}

class _ScrollFadeInState extends State<ScrollFadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotationAnim;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _rotationAnim = Tween<double>(begin: widget.beginRotation, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    widget.controller.addListener(_checkVisibility);
    // Also check on the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
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

    // Check if the element enters 95% of screen height
    if (position.dy < screenHeight * 0.95 && position.dy > -renderBox.size.height) {
      setState(() {
        _hasAnimated = true; // Permanently set to true so animation only runs once
      });
      // Remove listener immediately so it becomes static and stops checking
      widget.controller.removeListener(_checkVisibility);

      Future.delayed(Duration(milliseconds: widget.delayMs.toInt()), () {
        if (mounted) {
          _animController.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: FractionalTranslation(
              translation: _slideAnim.value,
              child: Transform.rotate(
                angle: _rotationAnim.value,
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class CategoryFeaturesWidget extends StatefulWidget {
  final bool isDarkMode;
  final ScrollController scrollController;

  const CategoryFeaturesWidget({
    super.key,
    required this.isDarkMode,
    required this.scrollController,
  });

  @override
  State<CategoryFeaturesWidget> createState() => _CategoryFeaturesWidgetState();
}

class _CategoryFeaturesWidgetState extends State<CategoryFeaturesWidget> {
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'AI Learning Features',
      'icon': Icons.psychology_rounded,
      'features': [
        {'title': 'AI Tutor for all subjects & classes', 'icon': Icons.chat_bubble_outline_rounded},
        {'title': 'Multilingual learning support', 'icon': Icons.translate_rounded},
        {'title': 'Voice-based learning interaction', 'icon': Icons.mic_rounded},
        {'title': 'Personalized learning paths', 'icon': Icons.insights_rounded},
        {'title': 'Concept explanations with examples', 'icon': Icons.lightbulb_outline_rounded},
        {'title': 'Doubt-solving assistant', 'icon': Icons.help_outline_rounded},
        {'title': 'Homework help', 'icon': Icons.menu_book_rounded},
        {'title': 'Assignment generation', 'icon': Icons.assignment_rounded},
        {'title': 'Notes generation', 'icon': Icons.edit_note_rounded},
        {'title': 'Study planner', 'icon': Icons.calendar_month_rounded},
      ],
    },
    {
      'name': 'AI Productivity Tools',
      'icon': Icons.bolt_rounded,
      'features': [
        {'title': 'AI Chat Assistant', 'icon': Icons.chat_rounded},
        {'title': 'AI Writing Assistant', 'icon': Icons.create_rounded},
        {'title': 'AI Research Assistant', 'icon': Icons.manage_search_rounded},
        {'title': 'AI Presentation Generator', 'icon': Icons.slideshow_rounded},
        {'title': 'AI Image Generation', 'icon': Icons.image_rounded},
        {'title': 'AI Summarization', 'icon': Icons.summarize_rounded},
        {'title': 'AI Translation', 'icon': Icons.g_translate_rounded},
      ],
    },
    {
      'name': 'School Features',
      'icon': Icons.school_rounded,
      'features': [
        {'title': 'School dashboard', 'icon': Icons.dashboard_rounded},
        {'title': 'Teacher dashboard', 'icon': Icons.people_alt_rounded},
        {'title': 'Student dashboard', 'icon': Icons.person_pin_rounded},
        {'title': 'Attendance management', 'icon': Icons.how_to_reg_rounded},
        {'title': 'Homework tracking', 'icon': Icons.checklist_rtl_rounded},
        {'title': 'Parent portal', 'icon': Icons.family_restroom_rounded},
        {'title': 'Announcements and notices', 'icon': Icons.campaign_rounded},
        {'title': 'School analytics', 'icon': Icons.analytics_rounded},
      ],
    },
    {
      'name': 'Exam Preparation',
      'icon': Icons.edit_document,
      'features': [
        {'title': 'CBT simulations', 'icon': Icons.computer_rounded},
        {'title': 'Mock tests for school exams', 'icon': Icons.quiz_rounded},
        {'title': 'Competitive exam preparation', 'icon': Icons.stars_rounded},
        {'title': 'Adaptive testing', 'icon': Icons.bar_chart_rounded},
        {'title': 'Previous year question analysis', 'icon': Icons.history_edu_rounded},
        {'title': 'Performance analytics', 'icon': Icons.trending_up_rounded},
        {'title': 'Weak area identification', 'icon': Icons.report_problem_rounded},
        {'title': 'Revision schedules', 'icon': Icons.schedule_rounded},
      ],
    },
    {
      'name': 'Content Library',
      'icon': Icons.library_books_rounded,
      'features': [
        {'title': 'NCERT solutions', 'icon': Icons.menu_book_rounded},
        {'title': 'Study materials', 'icon': Icons.book_rounded},
        {'title': 'Question banks', 'icon': Icons.folder_open_rounded},
        {'title': 'Practice worksheets', 'icon': Icons.article_rounded},
        {'title': 'Video lessons', 'icon': Icons.video_library_rounded},
        {'title': 'Interactive quizzes', 'icon': Icons.sports_esports_rounded},
      ],
    },
    {
      'name': 'Campus Plan Features',
      'icon': Icons.business_rounded,
      'features': [
        {'title': 'School-wide licenses', 'icon': Icons.vpn_key_rounded},
        {'title': 'Admin controls', 'icon': Icons.admin_panel_settings_rounded},
        {'title': 'Bulk student onboarding', 'icon': Icons.group_add_rounded},
        {'title': 'Institution analytics', 'icon': Icons.donut_large_rounded},
        {'title': 'Custom branding', 'icon': Icons.palette_rounded},
        {'title': 'Dedicated support', 'icon': Icons.support_agent_rounded},
      ],
    },
    {
      'name': 'Community Features',
      'icon': Icons.groups_rounded,
      'features': [
        {'title': 'Student communities', 'icon': Icons.group_work_rounded},
        {'title': 'Discussion forums', 'icon': Icons.forum_rounded},
        {'title': 'Peer learning groups', 'icon': Icons.connect_without_contact_rounded},
        {'title': 'Mentor support', 'icon': Icons.supervised_user_circle_rounded},
      ],
    },
    {
      'name': 'Platform Features',
      'icon': Icons.cloud_done_rounded,
      'features': [
        {'title': 'Cloud-based access', 'icon': Icons.cloud_done_rounded},
        {'title': 'Mobile-friendly platform', 'icon': Icons.phone_android_rounded},
        {'title': 'Secure data storage', 'icon': Icons.security_rounded},
        {'title': 'Scalable infrastructure', 'icon': Icons.dns_rounded},
        {'title': 'Multi-device synchronization', 'icon': Icons.sync_rounded},
        {'title': '24/7 availability', 'icon': Icons.more_time_rounded},
      ],
    },
    {
      'name': 'Future Features (recommended)',
      'icon': Icons.rocket_launch_rounded,
      'features': [
        {'title': 'AI Voice Tutor', 'icon': Icons.keyboard_voice_rounded},
        {'title': 'Live AI Classes', 'icon': Icons.live_tv_rounded},
        {'title': 'AI Career Guidance', 'icon': Icons.work_outline_rounded},
        {'title': 'Scholarship Finder', 'icon': Icons.card_membership_rounded},
        {'title': 'College Admission Assistant', 'icon': Icons.account_balance_rounded},
        {'title': 'AI Coding Tutor', 'icon': Icons.code_rounded},
        {'title': 'AI Interview Preparation', 'icon': Icons.record_voice_over_rounded},
        {'title': 'AI Resume Builder', 'icon': Icons.contact_page_rounded},
        {'title': 'AI Project Generator', 'icon': Icons.construction_rounded},
        {'title': 'Offline Learning Mode', 'icon': Icons.cloud_off_rounded},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Column(
      children: [
        // Category Tabs selector (wrap for flexibility)
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(_categories.length, (index) {
              final cat = _categories[index];
              final isSelected = index == _selectedCategoryIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF155DFC)
                        : (widget.isDarkMode
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (widget.isDarkMode
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08)),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 32),

        // Grid of Features in Selected Category (rebuilt with new key to trigger scroll fade in animations again on click!)
        KeyedSubtree(
          key: ValueKey(_selectedCategoryIndex),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(
              (_categories[_selectedCategoryIndex]['features'] as List).length,
              (index) {
                final feat = (_categories[_selectedCategoryIndex]['features'] as List)[index];
                return ScrollFadeIn(
                  controller: widget.scrollController,
                  delayMs: index * 50.0,
                  child: SizedBox(
                    width: isDesktop ? 240 : double.infinity,
                    child: _buildFeatureMicroCard(
                      title: feat['title'] as String,
                      icon: feat['icon'] as IconData,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureMicroCard({required String title, required IconData icon}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF155DFC).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF155DFC), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
