import 'dart:ui';
import 'package:flutter/gestures.dart';
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    ScrollFadeIn(
                      controller: _scrollController,
                      child: _buildHeroSection(isDesktop),
                    ),
                    
                    const SizedBox(height: 60),
                    ScrollFadeIn(
                      controller: _scrollController,
                      child: _buildSectionHeader('Pricing Plans', 'Choose the speed that matches your studies'),
                    ),
                    const SizedBox(height: 24),
                    _buildPricingGrid(isDesktop),

                    const SizedBox(height: 60),
                    ScrollFadeIn(
                      controller: _scrollController,
                      child: _buildCtaBanner(),
                    ),

                    const SizedBox(height: 40),
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

  Widget _buildPricingGrid(bool isDesktop) {
    final double cardWidth = isDesktop ? 300.0 : double.infinity;
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: List.generate(6, (index) {
          return ScrollFadeIn(
            controller: _scrollController,
            delayMs: index * 100.0,
            beginOffset: const Offset(0.0, 0.15),
            child: _buildPricingCardByIndex(index, cardWidth),
          );
        }),
      ),
    );
  }

  Widget _buildPricingCardByIndex(int index, double cardWidth) {
    switch (index) {
      case 0:
        return _buildPricingCard(
          title: 'Free Plan 📚',
          price: 'Free',
          subtitle: 'Essential features for single students',
          featureGroups: const [
            FeatureGroup(
              title: 'AI Learning Features',
              items: [
                'Limited AI Tutor chats',
                '5 doubt solutions/day',
                'Basic notes',
                'Limited tests',
              ],
            ),
            FeatureGroup(
              title: 'Community Features',
              items: [
                'Community support',
                'Student communities',
              ],
            ),
            FeatureGroup(
              title: 'Platform Features',
              items: [
                'Cloud-based access',
                'Mobile-friendly platform',
              ],
            ),
          ],
          ctaText: 'Start Free',
          isPremium: false,
          width: cardWidth,
        );
      case 1:
        return _buildPricingCard(
          title: 'Basic Plan ⚡',
          price: '₹99',
          subtitle: 'Affordable booster for self-study',
          featureGroups: const [
            FeatureGroup(
              title: 'AI Learning Features',
              items: [
                'Unlimited doubts',
                'AI Tutor access',
                'Notes generation',
                'Homework help',
              ],
            ),
            FeatureGroup(
              title: 'Exam Preparation',
              items: [
                'Weekly mock tests',
                'Progress tracking',
              ],
            ),
            FeatureGroup(
              title: 'Platform Features',
              items: [
                'Cloud-based access',
                'Mobile-friendly platform',
                'Secure data storage',
              ],
            ),
          ],
          ctaText: 'Get Basic',
          isPremium: false,
          width: cardWidth,
        );
      case 2:
        return _buildPricingCard(
          title: 'Campus Plan 🏫',
          price: '₹149',
          subtitle: 'For schools and institutions',
          featureGroups: const [
            FeatureGroup(
              title: 'School Dashboards',
              items: [
                'School dashboard',
                'Teacher dashboard',
                'Student dashboard',
                'Parent portal',
              ],
            ),
            FeatureGroup(
              title: 'School CRM Management',
              items: [
                'Attendance management',
                'Homework tracking',
                'Announcements and notices',
                'School analytics',
              ],
            ),
            FeatureGroup(
              title: 'Campus Plan CRM features',
              items: [
                'School-wide licenses',
                'Admin controls',
                'Bulk student onboarding',
                'Institution analytics',
                'Custom branding',
                'Dedicated support',
              ],
            ),
          ],
          ctaText: 'Contact School Admin',
          isPremium: false,
          width: cardWidth,
        );
      case 3:
        return _buildPricingCard(
          title: 'Pro Student 🚀',
          price: '₹299',
          subtitle: 'Unlimited learning & AI tools',
          inheritsText: 'Everything in Basic',
          featureGroups: const [
            FeatureGroup(
              title: 'AI Learning Features',
              items: [
                'Unlimited AI chats',
                'Personalized study plans',
                'Voice AI Tutor',
                'Priority support',
              ],
            ),
            FeatureGroup(
              title: 'AI Productivity Tools',
              items: [
                'AI Chat Assistant',
                'AI Summarization',
                'AI Translation',
              ],
            ),
            FeatureGroup(
              title: 'Content Library',
              items: [
                'Interactive quizzes',
              ],
            ),
          ],
          ctaText: 'Upgrade to Pro',
          isPremium: true,
          width: cardWidth,
        );
      case 4:
        return _buildPricingCard(
          title: 'Exam Aspirant 🎯',
          price: '₹499',
          subtitle: 'Cracking competitive tests',
          inheritsText: 'Everything in Pro',
          featureGroups: const [
            FeatureGroup(
              title: 'Exam Preparation',
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
            FeatureGroup(
              title: 'Content Library',
              items: [
                'NCERT solutions',
                'Study materials',
                'Question banks',
                'Practice worksheets',
                'Video lessons',
              ],
            ),
            FeatureGroup(
              title: 'Community Features',
              items: [
                'Mentor support',
              ],
            ),
          ],
          ctaText: 'Get Aspirant Plan',
          isPremium: false,
          width: cardWidth,
        );
      case 5:
      default:
        return _buildPricingCard(
          title: 'Premium AI 🤖',
          price: '₹999',
          subtitle: 'Ultimate researcher & advisor tools',
          inheritsText: 'Everything in Exam Aspirant',
          featureGroups: const [
            FeatureGroup(
              title: 'AI Productivity Tools',
              items: [
                'AI Research Assistant',
                'AI Presentation Maker',
                'AI Image Generator',
                'AI Coding Tutor',
                'AI Career Counselor',
                'AI Writing Assistant',
              ],
            ),
            FeatureGroup(
              title: 'Platform Features',
              items: [
                'Early access features',
                'Cloud-based access',
                'Secure data storage',
                'Scalable infrastructure',
                '24/7 availability',
              ],
            ),
          ],
          ctaText: 'Get Ultimate AI',
          isPremium: false,
          width: cardWidth,
        );
    }
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String subtitle,
    required List<FeatureGroup> featureGroups,
    String? inheritsText,
    required String ctaText,
    required bool isPremium,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(24),
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
            Divider(height: 24, color: _isDarkMode ? Colors.white12 : Colors.black12),
            if (inheritsText != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: const Color(0xFF155DFC),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      inheritsText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Expandable Feature Items
            ...featureGroups.map((group) => ExpandableFeatureItem(
                  title: group.title,
                  subFeatures: group.items,
                  isDarkMode: _isDarkMode,
                  isPremium: isPremium,
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

class FeatureGroup {
  final String title;
  final List<String> items;

  const FeatureGroup({required this.title, required this.items});
}

class ExpandableFeatureItem extends StatefulWidget {
  final String title;
  final List<String> subFeatures;
  final bool isDarkMode;
  final bool isPremium;

  const ExpandableFeatureItem({
    key,
    required this.title,
    required this.subFeatures,
    required this.isDarkMode,
    required this.isPremium,
  }) : super(key: key);

  @override
  State<ExpandableFeatureItem> createState() => _ExpandableFeatureItemState();
}

class _ExpandableFeatureItemState extends State<ExpandableFeatureItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                  color: widget.isPremium 
                      ? const Color(0xFF155DFC) 
                      : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 28.0, bottom: 8.0, top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.subFeatures.map((feat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: widget.isPremium
                                    ? const Color(0xFF155DFC)
                                    : (widget.isDarkMode ? Colors.tealAccent.shade400 : Colors.teal.shade700),
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feat,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
