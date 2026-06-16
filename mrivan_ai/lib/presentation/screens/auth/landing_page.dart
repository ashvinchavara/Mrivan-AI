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
  bool _isDarkMode = false;

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
                              color: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
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
                                  _isDarkMode = !_isDarkMode;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _navigateToLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isDarkMode ? Colors.white10 : Colors.deepPurple,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // SECTION 1: HERO
                    const SizedBox(height: 30),
                    _buildHeroSection(isDesktop),
                    
                    const SizedBox(height: 60),
                    // SECTION 2: FEATURES
                    _buildSectionHeader('Powerful Features', 'Everything you need to master your syllabus'),
                    const SizedBox(height: 24),
                    _buildFeaturesGrid(isDesktop),

                    const SizedBox(height: 60),
                    // SECTION 3: PRICING
                    _buildSectionHeader('Pricing Plans', 'Choose the speed that matches your studies'),
                    const SizedBox(height: 24),
                    _buildPricingGrid(isDesktop),

                    const SizedBox(height: 60),
                    // SECTION 4: CALL TO ACTION
                    _buildCtaBanner(),

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
                color: _isDarkMode ? Colors.purpleAccent.withValues(alpha: 0.15) : Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
                  width: 1,
                ),
              ),
              child: Text(
                'Available 24×7 Across the Globe',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
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
                color: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Meet MRVN—your 24/7 hyper-personalized study partner. Learn, practice, and succeed in any subject or language. Solve math calculations, draft study notes, analyze complex concepts, and take CBT mock diagnostics instantly.',
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
                backgroundColor: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                shadowColor: Colors.purple.withValues(alpha: 0.3),
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
    final double cardWidth = isDesktop ? 340 : double.infinity;
    return Center(
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          _buildFeatureCard(
            title: 'MRVN AI Tutor',
            description: 'Get step-by-step solutions to physics equations, language tasks, or writing ideas, in any language.',
            icon: Icons.chat_bubble_outline_rounded,
            color: Colors.purpleAccent,
            width: cardWidth,
          ),
          _buildFeatureCard(
            title: 'AI Outline Builder',
            description: 'Generate comprehensive notes outlines and study summaries based on your class level instantly.',
            icon: Icons.auto_stories_outlined,
            color: Colors.blueAccent,
            width: cardWidth,
          ),
          _buildFeatureCard(
            title: 'CBT Test Diagnostics',
            description: 'Attempt mock quizzes with auto-grading logic to identify syllabus areas that need study.',
            icon: Icons.analytics_outlined,
            color: Colors.orangeAccent,
            width: cardWidth,
          ),
          _buildFeatureCard(
            title: 'unified School CRM',
            description: 'A shared workspace linking attendance logs, homework entries, and performance cards.',
            icon: Icons.checklist_rtl_rounded,
            color: Colors.tealAccent,
            width: cardWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: _buildGlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingGrid(bool isDesktop) {
    return Center(
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: [
          // Starter Plan Card
          _buildPricingCard(
            title: 'Starter',
            price: 'Free',
            subtitle: 'Perfect for individual review',
            features: [
              'Daily AI Tutor queries',
              'Access to student dashboards',
              'Standard study notes',
              'Basic mock quizzes',
            ],
            ctaText: 'Get Started Free',
            isPremium: false,
            width: isDesktop ? 340 : double.infinity,
          ),

          // Campus Premium Card
          _buildPricingCard(
            title: 'Campus Premium',
            price: '\$12',
            subtitle: 'Unlimited learning for power students',
            features: [
              'Unlimited MRVN AI queries',
              'Notes export capabilities',
              'Full CBT mock attempts',
              'Bulk teacher CRM logs',
              'Parent linkage dashboards',
            ],
            ctaText: 'Go Premium',
            isPremium: true,
            width: isDesktop ? 340 : double.infinity,
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
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.purpleAccent,
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
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (price != 'Free')
                  Text(
                    ' / month',
                    style: TextStyle(
                      fontSize: 14,
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
            const Divider(height: 32),
            ...features.map((feat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: isPremium ? Colors.purpleAccent : Colors.tealAccent.shade400,
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
                    ? (_isDarkMode ? Colors.purpleAccent : Colors.deepPurple) 
                    : Colors.transparent,
                foregroundColor: isPremium ? Colors.white : (_isDarkMode ? Colors.white : Colors.black87),
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
                backgroundColor: _isDarkMode ? Colors.purpleAccent.shade400 : Colors.deepPurple,
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
