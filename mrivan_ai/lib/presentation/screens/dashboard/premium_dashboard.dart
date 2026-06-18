import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../../theme/theme_config.dart';
import 'dart:ui';

class PremiumDashboard extends StatefulWidget {
  final String userName;
  final String paymentPlan;
  final String email;

  const PremiumDashboard({
    super.key,
    required this.userName,
    required this.paymentPlan,
    required this.email,
  });

  @override
  State<PremiumDashboard> createState() => _PremiumDashboardState();
}

class _PremiumDashboardState extends State<PremiumDashboard> {
  int _currentIndex = 0;

  final List<String> _tabs = [
    'Dashboard',
    'AI Teacher',
    'Career & Coach',
    'Performance',
    'VIP Pass'
  ];

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // debug logging
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 950;
    
    // Primary aesthetic theme values
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final String initialText = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : 'U';

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        final currentBg = isDarkMode ? bgDark : bgLight;
        final currentCard = isDarkMode ? cardDark : cardLight;
        final currentText = isDarkMode ? textDark : textLight;
        final currentBorder = isDarkMode ? borderDark : borderLight;

        Widget currentScreen;
        switch (_currentIndex) {
          case 0:
            currentScreen = DashboardTab(
              userName: widget.userName,
              paymentPlan: widget.paymentPlan,
              isDarkMode: isDarkMode,
              onUpgrade: () {
                setState(() {
                  _currentIndex = 4;
                });
              },
            );
            break;
          case 1:
            currentScreen = AiTeacherTab(
              paymentPlan: widget.paymentPlan,
              isDarkMode: isDarkMode,
              onUpgrade: () {
                setState(() {
                  _currentIndex = 4;
                });
              },
            );
            break;
          case 2:
            final plan = widget.paymentPlan.toLowerCase();
            final hasAccess = plan.contains('pro') || plan.contains('aspirant') || plan.contains('premium') || plan.contains('campus');
            currentScreen = PlanFeatureGate(
              isUnlocked: hasAccess,
              requiredPlan: 'Pro Student Plan',
              isDarkMode: isDarkMode,
              onUpgrade: () {
                setState(() {
                  _currentIndex = 4;
                });
              },
              child: CareerCoachTab(isDarkMode: isDarkMode),
            );
            break;
          case 3:
            final plan = widget.paymentPlan.toLowerCase();
            final hasAccess = plan.contains('pro') || plan.contains('aspirant') || plan.contains('premium') || plan.contains('campus');
            currentScreen = PlanFeatureGate(
              isUnlocked: hasAccess,
              requiredPlan: 'Pro Student/Exam Plan',
              isDarkMode: isDarkMode,
              onUpgrade: () {
                setState(() {
                  _currentIndex = 4;
                });
              },
              child: PerformanceAnalyticsTab(isDarkMode: isDarkMode),
            );
            break;
          case 4:
            currentScreen = PricingVipTab(
              paymentPlan: widget.paymentPlan,
              email: widget.email,
              isDarkMode: isDarkMode,
            );
            break;
          default:
            currentScreen = DashboardTab(
              userName: widget.userName,
              paymentPlan: widget.paymentPlan,
              isDarkMode: isDarkMode,
              onUpgrade: () {
                setState(() {
                  _currentIndex = 4;
                });
              },
            );
        }

        return Scaffold(
          backgroundColor: currentBg,
          appBar: !isDesktop
              ? AppBar(
                  iconTheme: IconThemeData(color: currentText),
                  title: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.jpeg',
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MRIVAN AI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 18,
                          color: currentText,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDarkMode ? const Color(0xFFFFB020) : const Color(0xFF4F46E5),
                      ),
                      onPressed: () {
                        isDarkModeNotifier.value = !isDarkMode;
                      },
                      tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    ),
                  ],
                  backgroundColor: currentCard,
                  elevation: 0,
                  shape: Border(bottom: BorderSide(color: currentBorder, width: 1)),
                )
              : null,
          drawer: !isDesktop
              ? Drawer(
                  child: Container(
                    color: currentCard,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        DrawerHeader(
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1F1F2E) : const Color(0xFFF1F5F9),
                            border: Border(bottom: BorderSide(color: currentBorder, width: 1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/logo.jpeg',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'MRIVAN AI',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: currentText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'The Ultimate Productivity & Learning Suite', 
                                style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white60 : const Color(0xFF64748B))
                              ),
                            ],
                          ),
                        ),
                        for (int i = 0; i < _tabs.length; i++)
                          ListTile(
                            leading: Icon(
                              _getIcon(i),
                              color: _currentIndex == i ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                            ),
                            title: Text(
                              _tabs[i],
                              style: TextStyle(
                                color: _currentIndex == i ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                fontWeight: _currentIndex == i ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: _currentIndex == i,
                            onTap: () {
                              setState(() {
                                _currentIndex = i;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        const Divider(color: Color(0xFFE2E8F0)),
                        ListTile(
                          leading: Icon(
                            isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDarkMode ? const Color(0xFFFFB020) : const Color(0xFF4F46E5),
                          ),
                          title: Text(
                            isDarkMode ? 'Light Mode' : 'Dark Mode',
                            style: TextStyle(color: currentText),
                          ),
                          onTap: () {
                            isDarkModeNotifier.value = !isDarkMode;
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Color(0xFFF05A7E)),
                          title: Text(
                            'Logout',
                            style: TextStyle(color: currentText),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _handleSignOut();
                          },
                        ),
                        const Divider(color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            '${widget.paymentPlan.toUpperCase()} ACTIVE', 
                            style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : null,
          bottomNavigationBar: !isDesktop
              ? BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  backgroundColor: currentCard,
                  selectedItemColor: const Color(0xFF4F46E5),
                  unselectedItemColor: const Color(0xFF64748B),
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(icon: Icon(_getIcon(0)), label: 'Dashboard'),
                    BottomNavigationBarItem(icon: Icon(_getIcon(1)), label: 'AI Teacher'),
                    BottomNavigationBarItem(icon: Icon(_getIcon(2)), label: 'Career'),
                    BottomNavigationBarItem(icon: Icon(_getIcon(3)), label: 'Analytics'),
                    BottomNavigationBarItem(icon: Icon(_getIcon(4)), label: 'VIP Pass'),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (isDesktop) ...[
                Container(
                  width: 250,
                  color: isDarkMode ? const Color(0xFF13131A) : const Color(0xFFF1F5F9),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/logo.jpeg',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'MRIVAN AI',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: currentText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI LEARNING / CAREER',
                        style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.grey : const Color(0xFF64748B), letterSpacing: 2),
                      ),
                      const SizedBox(height: 40),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _tabs.length,
                          itemBuilder: (context, index) {
                            final isSelected = _currentIndex == index;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF6C63FF).withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF6C63FF).withOpacity(0.3)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIcon(index),
                                        color: isSelected 
                                            ? (isDarkMode ? const Color(0xFF00F2FE) : const Color(0xFF4F46E5))
                                            : (isDarkMode ? Colors.grey[400] : const Color(0xFF64748B)),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        _tabs[index],
                                        style: TextStyle(
                                          color: isSelected 
                                              ? currentText
                                              : (isDarkMode ? Colors.grey[400] : const Color(0xFF64748B)),
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
                              child: Text(
                                initialText, 
                                style: TextStyle(color: currentText, fontWeight: FontWeight.bold)
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userName.split('@')[0],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    widget.paymentPlan,
                                    style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                color: isDarkMode ? const Color(0xFFFFB020) : const Color(0xFF4F46E5),
                                size: 20,
                              ),
                              onPressed: () {
                                isDarkModeNotifier.value = !isDarkMode;
                              },
                              tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                            ),
                            IconButton(
                              icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 20),
                              onPressed: _handleSignOut,
                              tooltip: 'Sign Out',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E1E28) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.paymentPlan.toLowerCase().contains('free')
                                  ? (isDarkMode ? Colors.grey.withOpacity(0.2) : const Color(0xFFE2E8F0))
                                  : Colors.amber.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    widget.paymentPlan.toLowerCase().contains('free')
                                        ? Icons.info_outline
                                        : Icons.stars,
                                    color: widget.paymentPlan.toLowerCase().contains('free')
                                        ? Colors.grey
                                        : Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.paymentPlan.toLowerCase().contains('free')
                                        ? 'Free Trial'
                                        : 'Plan Active',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: widget.paymentPlan.toLowerCase().contains('free')
                                          ? Colors.grey
                                          : Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.paymentPlan.toLowerCase().contains('free')
                                    ? 'Core trial features only.'
                                    : 'All plan features unlocked.',
                                style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.grey : const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                VerticalDivider(color: currentBorder, width: 1),
              ],
              Expanded(
                child: SafeArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: currentScreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_outlined;
      case 1:
        return Icons.school_outlined;
      case 2:
        return Icons.rocket_launch_outlined;
      case 3:
        return Icons.analytics_outlined;
      case 4:
        return Icons.workspace_premium_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ==========================================
// SCREEN 1: DASHBOARD TAB
// ==========================================
class DashboardTab extends StatelessWidget {
  final String userName;
  final String paymentPlan;
  final bool isDarkMode;
  final VoidCallback onUpgrade;

  const DashboardTab({
    super.key,
    required this.userName,
    required this.paymentPlan,
    required this.isDarkMode,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 950;
    
    final currentText = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDarkMode ? const Color(0xFF181824) : Colors.white;

    final plan = paymentPlan.toLowerCase();
    final isFreePlan = plan.contains('free');
    final hasProAccess = plan.contains('pro') || plan.contains('aspirant') || plan.contains('premium') || plan.contains('campus');
    final hasInterviewAccess = plan.contains('pro') || plan.contains('premium') || plan.contains('campus') || plan.contains('aspirant');
    final hasPlacementAccess = plan.contains('pro') || plan.contains('premium') || plan.contains('campus');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFreePlan) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2A6D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF2A6D), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free Trial Account',
                          style: TextStyle(
                            color: Color(0xFFFF2A6D),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You are currently on the Free Plan with limited features and a query cap.',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2A6D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Mrivan Cockpit 🚀',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: currentText),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Elevate your learning, target your ultimate career, optimize productivity.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: onUpgrade,
                  icon: const Icon(Icons.bolt, color: Colors.black, size: 18),
                  label: const Text('Fast Assistant', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F2FE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // QUICK INSIGHTS BENTO GRID
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.6 : 1.9,
            children: [
              _buildMetricCard(
                'Career Readiness Index',
                '88.5%',
                'Top 5% among engineering aspirants',
                const Color(0xFF6C63FF),
                Icons.trending_up,
                cardBg,
                isUnlocked: hasProAccess,
                onUpgrade: onUpgrade,
              ),
              _buildMetricCard(
                'Streak & Daily Planning',
                '14 Days',
                '92% habits targets hit this week',
                const Color(0xFF00F2FE),
                Icons.stars,
                cardBg,
                isUnlocked: true,
              ),
              _buildMetricCard(
                'Mock Interview Performance',
                'Level 4/5',
                'Excellent pacing & ATS keywords sync',
                const Color(0xFFFF2A6D),
                Icons.mic_external_on,
                cardBg,
                isUnlocked: hasInterviewAccess,
                onUpgrade: onUpgrade,
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'Explore Ultimate AI Capabilities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 16),

          // FEATURES HUB LIST/GRID
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 2.5 : 2.1,
            children: [
              _buildFeatureTile(
                '👨‍🏫 Personal AI Teacher',
                'Custom structured syllabi creation, real-time explanation level scaling (Simple, Advanced), 24/7 concept test questions solver with Multi-language voice.',
                Icons.person,
                const Color(0xFF6C63FF),
                cardBg,
                currentText,
                isUnlocked: true,
              ),
              _buildFeatureTile(
                '🎯 AI Career Mentor',
                'Roadmaps with dynamic timeline, automated Skill-gap scans. Find missing certifications, and generate growth workflows directly synced to GitHub.',
                Icons.architecture,
                const Color(0xFF00F2FE),
                cardBg,
                currentText,
                isUnlocked: hasProAccess,
                onUpgrade: onUpgrade,
              ),
              _buildFeatureTile(
                '🎤 AI Interview Coach',
                'Simulate voice & technical interview queries with live response feedback. Get transcripts with speech speed, posture analysis, and confidence score summaries.',
                Icons.settings_voice,
                const Color(0xFFFF2A6D),
                cardBg,
                currentText,
                isUnlocked: hasInterviewAccess,
                onUpgrade: onUpgrade,
              ),
              _buildFeatureTile(
                '💼 Placement & Job Readiness',
                'Upload and evaluate resume against ATS systems. Optimize matching descriptors with direct suggestions, and build custom web portfolios.',
                Icons.business_center,
                Colors.amber,
                cardBg,
                currentText,
                isUnlocked: hasPlacementAccess,
                onUpgrade: onUpgrade,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // LOWER BRAND BANNER
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E28), Color(0xFF13131A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔥 Premium AI Ecosystem Integrations',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock WhatsApp Assistant access, Google Calendar event synchronizations, Cloud file processing, and expert webinar entries with direct mentor feedback.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.rocket_launch, color: Color(0xFF00F2FE), size: 36),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String mainValue,
    String subText,
    Color accentColor,
    IconData icon,
    Color bg, {
    bool isUnlocked = true,
    VoidCallback? onUpgrade,
  }) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mainValue,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor),
                ),
                const SizedBox(height: 4),
                Text(
                  subText,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      ),
    );

    if (isUnlocked) return cardContent;

    return GestureDetector(
      onTap: onUpgrade,
      child: Stack(
        children: [
          Opacity(
            opacity: 0.22,
            child: cardContent,
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: accentColor, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade to Unlock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
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

  Widget _buildFeatureTile(
    String title,
    String description,
    IconData icon,
    Color color,
    Color bg,
    Color textColor, {
    bool isUnlocked = true,
    VoidCallback? onUpgrade,
  }) {
    final tileContent = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isUnlocked) return tileContent;

    return GestureDetector(
      onTap: onUpgrade,
      child: Stack(
        children: [
          Opacity(
            opacity: 0.22,
            child: tileContent,
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: color, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      'Upgrade to Unlock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
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
}

// ==========================================
// SCREEN 2: PERSONAL AI TEACHER TAB
// ==========================================
class AiTeacherTab extends StatefulWidget {
  final String paymentPlan;
  final bool isDarkMode;
  final VoidCallback onUpgrade;

  const AiTeacherTab({
    super.key,
    required this.paymentPlan,
    required this.isDarkMode,
    required this.onUpgrade,
  });

  @override
  State<AiTeacherTab> createState() => _AiTeacherTabState();
}

class _AiTeacherTabState extends State<AiTeacherTab> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'Hello! I am your custom Adaptive AI Teacher. Name any topic, or submit a homework problem. I can adapt my teaching level instantly!'
    }
  ];

  String _selectedLevel = 'Simple Explanation';
  int _queriesRemaining = 5;

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final chatBubbleBg = widget.isDarkMode ? const Color(0xFF1E1E2C) : const Color(0xFFF1F5F9);
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    final isFreePlan = widget.paymentPlan.toLowerCase().contains('free');

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal AI Teacher Space 👨‍🏫',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 8),
          const Text(
            '24/7 instant conceptual deep dives with custom learning pathways.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),

          if (isFreePlan) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2A6D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFFF2A6D), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Free Trial Active: You have $_queriesRemaining trial queries remaining today.',
                      style: const TextStyle(
                        color: Color(0xFFFF2A6D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onUpgrade,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        color: Color(0xFFFF2A6D),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // CONFIGURATION HEADER ROW
          runConfigChips(),
          const SizedBox(height: 20),

          // CHAT INTERFACE
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.65,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFF4F46E5)
                                  : chatBubbleBg,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 16),
                              ),
                              border: isUser
                                  ? null
                                  : Border.all(color: borderCol),
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isUser ? Colors.white : currentText),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(color: borderCol, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (widget.paymentPlan.toLowerCase().contains('free') ||
                                widget.paymentPlan.toLowerCase().contains('basic')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Voice Assistant is a Pro feature. Upgrade to unlock.'),
                                  backgroundColor: Color(0xFF4F46E5),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.mic,
                            color: (widget.paymentPlan.toLowerCase().contains('free') ||
                                    widget.paymentPlan.toLowerCase().contains('basic'))
                                ? Colors.grey
                                : const Color(0xFF00F2FE),
                          ),
                          tooltip: 'Speak Voice Input',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: TextStyle(fontSize: 13, color: currentText),
                            decoration: const InputDecoration(
                              hintText: 'Enter topic (e.g. quantum entanglement or backpropagation)',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: const Color(0xFF4F46E5),
                          child: IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget runConfigChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildConfigChip('Simple Explanation', Icons.face),
        _buildConfigChip('Detailed Scientific Code', Icons.code),
        _buildConfigChip('Analogies & Flashcards', Icons.collections),
        _buildConfigChip('Socratic Method Practice', Icons.question_answer),
      ],
    );
  }

  Widget _buildConfigChip(String title, IconData icon) {
    final isSelected = _selectedLevel == title;
    final chipBg = widget.isDarkMode ? const Color(0xFF1E1E28) : const Color(0xFFF1F5F9);
    final selectedBg = const Color(0xFF4F46E5).withOpacity(0.15);
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);
    final textCol = isSelected 
        ? const Color(0xFF4F46E5) 
        : (widget.isDarkMode ? Colors.grey[400] : const Color(0xFF475569));

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : borderCol,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey, size: 16),
            const SizedBox(width: 8),
            Text(
              title, 
              style: TextStyle(
                color: textCol, 
                fontSize: 12, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;
    final isFreePlan = widget.paymentPlan.toLowerCase().contains('free');
    
    if (isFreePlan && _queriesRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free Trial Limit reached. Upgrade to Pro for unlimited access.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final text = _chatController.text;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _chatController.clear();
      if (isFreePlan) {
        _queriesRemaining--;
      }
    });

    // Simulate smart tutor answering
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'Insightful query on "$text"! Let me adjust my explanation model to "$_selectedLevel". This involves dividing the concept into visualizable building blocks. Let me generate interactive exercises next...'
        });
      });
    });
  }
}

// ==========================================
// SCREEN 3: CAREER MENTOR TAB
// ==========================================
class CareerCoachTab extends StatefulWidget {
  final bool isDarkMode;
  const CareerCoachTab({super.key, required this.isDarkMode});

  @override
  State<CareerCoachTab> createState() => _CareerCoachTabState();
}

class _CareerCoachTabState extends State<CareerCoachTab> {
  bool _isRecording = false;
  late math.Random _random;

  @override
  void initState() {
    super.initState();
    _random = math.Random();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 950;
    
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Career Portal & Interview Simulator 🎤', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText)
          ),
          const SizedBox(height: 8),
          const Text('Custom technical roadmap mappings, ATS profile checkers, and real-time audio mock evaluations.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COL 1: Coach Audio Wave Simulator
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Mock Interview Simulation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentText)),
                            const SizedBox(height: 6),
                            const Text('Target Role: Senior Full Stack Engineer (Fintech API Focus)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 32),

                            // Pulsing Wave Animation Container
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF111116),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.04)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(24, (index) {
                                  double waveHeight = _isRecording 
                                      ? (15.0 + _random.nextDouble() * 85.0) 
                                      : (5.0 + math.sin(index * 0.5).abs() * 15.0);
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                    width: 4,
                                    height: waveHeight,
                                    decoration: BoxDecoration(
                                      color: _isRecording ? const Color(0xFF00F2FE) : const Color(0xFF6C63FF).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isRecording = !_isRecording;
                                    });
                                  },
                                  icon: Icon(
                                    _isRecording ? Icons.stop_circle : Icons.mic,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    _isRecording ? 'COMPLETE ANSWER' : 'START VC RESPONSE',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isRecording ? Colors.redAccent : const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ATS Resume Grader
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Portfolio & CV ATS Index Checker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentText)),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: 0.85,
                              color: const Color(0xFF00F2FE),
                              backgroundColor: Colors.grey.withOpacity(0.12),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Job Match Grade: Excellent (85/100)', 
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentText),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Target ATS cutoff: 75', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 14),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Keywords matching: "REST API", "State Architecture" found.', 
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.warning_amber, color: Colors.amber, size: 14),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Recommendation: Add "Automated Continuous Integration" descriptions.', 
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isDesktop) const SizedBox(width: 24),

              // COL 2: Career Stepper Node Plan (Visible on Desktop)
              if (isDesktop)
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dynamic Job Roadmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentText)),
                          const SizedBox(height: 14),
                          _buildRoadmapNode(1, 'Identify Skill Gaps', 'AI processes repositories to discover architectural knowledge gaps.', true, currentText),
                          _buildRoadmapNode(2, 'Optimized ATS CV Matching', 'Formulate custom cover letters & ATS descriptions.', true, currentText),
                          _buildRoadmapNode(3, 'Interview Simulator Drill', 'Conduct AI sound assessments on deep databases.', false, currentText),
                          _buildRoadmapNode(4, 'LinkedIN Profile Polish', 'Deploy standard LinkedIn headings with direct recommendations.', false, currentText),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRoadmapNode(int step, String title, String info, bool completed, Color textCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: completed ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.12),
            child: Icon(
              completed ? Icons.check : Icons.radio_button_unchecked, 
              size: 11, 
              color: completed ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: completed ? textCol : Colors.grey)),
                const SizedBox(height: 4),
                Text(info, style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1.3)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 4: PERFORMANCE & ANALYTICS TAB
// ==========================================
class PerformanceAnalyticsTab extends StatelessWidget {
  final bool isDarkMode;
  const PerformanceAnalyticsTab({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 950;
    
    final currentText = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Analytics & Revision Space 📊', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText)
          ),
          const SizedBox(height: 8),
          const Text('Review mock test outcomes, monthly skill trends, and predictive growth ratings.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),

          // Custom Painted Charts Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.5 : 1.7,
            children: [
              // Chart Card 1: Monthly Growth Trends
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Growth Analytics (Historical vs AI Target)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentText)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: GrowthChartPainter(isDarkMode: isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendDot(const Color(0xFF6C63FF), 'Theoretical Knowledge'),
                          const SizedBox(width: 16),
                          _buildLegendDot(const Color(0xFF00F2FE), 'Practical Coding Scale'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Chart Card 2: Skill Distribution spider chart mock
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Skill Competence Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentText)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: SkillRadarPainter(isDarkMode: isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Exam Preparation Checklist
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI revision checklist & tests tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentText)),
                  const SizedBox(height: 16),
                  _buildChecklistItem('AWS Cloud Practitioner Mock Exams', 'Completed: 3/5 mock tests. Predicted score: 91%', true, currentText),
                  _buildChecklistItem('System Design Blueprint revision', 'Assigned conceptual flashcards pending recall drills.', false, currentText),
                  _buildChecklistItem('Daily Coding Challenge Streak', 'Streak level: Stable 14 days active. 8 solved problems.', true, currentText),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildChecklistItem(String title, String description, bool done, Color textCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(done ? Icons.check_box : Icons.check_box_outline_blank, color: done ? const Color(0xFF00F2FE) : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: done ? textCol : Colors.grey)),
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// SCREEN 5: VIP PORTAL TAB
// ==========================================
class PricingVipTab extends StatelessWidget {
  final String paymentPlan;
  final String email;
  final bool isDarkMode;

  const PricingVipTab({
    super.key,
    required this.paymentPlan,
    required this.email,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final currentText = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VIP Pass & Subscription Portal 💎', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText)
          ),
          const SizedBox(height: 8),
          const Text('Manage your account benefits, access exclusive webinars, and configure external API channels.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 32),

          // Active Plan Glowing Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'VIP MEMBERSHIP ACTIVE', 
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)
                      ),
                    ),
                    const Icon(Icons.stars, color: Colors.amber, size: 28),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  paymentPlan,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Associated with: $email',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Manage Billing Options', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text('Unlocked Benefits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentText)),
          const SizedBox(height: 16),

          // Benefits List
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 750 ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3.2,
            children: [
              _buildBenefitItem(Icons.question_answer_outlined, 'WhatsApp Doubt solver', 'Direct integration to submit questions on-the-go.', cardBg, currentText, borderCol),
              _buildBenefitItem(Icons.calendar_month, 'Calendar Sync', 'Sync homework, mock exams, study slots to Google Calendar.', cardBg, currentText, borderCol),
              _buildBenefitItem(Icons.chat_bubble, 'Voice Conversational AI', 'Natural auditory dialogs with your personal teacher.', cardBg, currentText, borderCol),
              _buildBenefitItem(Icons.speed, 'High Priority GPU Limits', 'Faster response generation for coding and design graphs.', cardBg, currentText, borderCol),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String desc, Color bg, Color textCol, Color borderCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4F46E5), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol)),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    desc, 
                    style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTERS
// ==========================================

class GrowthChartPainter extends CustomPainter {
  final bool isDarkMode;
  GrowthChartPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw background grid lines
    const int rows = 5;
    for (int i = 0; i <= rows; i++) {
      double y = size.height * i / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    const int cols = 5;
    for (int i = 0; i <= cols; i++) {
      double x = size.width * i / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Line 1: Theoretical Knowledge
    final path1 = Path();
    path1.moveTo(0, size.height * 0.85);
    path1.cubicTo(
      size.width * 0.25, size.height * 0.70,
      size.width * 0.50, size.height * 0.45,
      size.width * 0.75, size.height * 0.35,
    );
    path1.lineTo(size.width, size.height * 0.20);

    final strokePaint1 = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Line 2: Practical Coding Scale
    final path2 = Path();
    path2.moveTo(0, size.height * 0.95);
    path2.cubicTo(
      size.width * 0.25, size.height * 0.85,
      size.width * 0.50, size.height * 0.65,
      size.width * 0.75, size.height * 0.25,
    );
    path2.lineTo(size.width, size.height * 0.10);

    final strokePaint2 = Paint()
      ..color = const Color(0xFF00F2FE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw lines
    canvas.drawPath(path1, strokePaint1);
    canvas.drawPath(path2, strokePaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SkillRadarPainter extends CustomPainter {
  final bool isDarkMode;
  SkillRadarPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.4;
    
    final gridPaint = Paint()
      ..color = isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw 5 levels of concentric pentagons
    for (int level = 1; level <= 5; level++) {
      final radius = maxRadius * level / 5;
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (math.pi * 2 / 5) * i - math.pi / 2;
        final x = center.dx + math.cos(angle) * radius;
        final y = center.dy + math.sin(angle) * radius;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final double step = math.pi * 2 / 5;

    // Draw axes
    for (int i = 0; i < 5; i++) {
      final angle = step * i - math.pi / 2;
      final endPoint = Offset(
        center.dx + math.cos(angle) * maxRadius,
        center.dy + math.sin(angle) * maxRadius,
      );
      canvas.drawLine(center, endPoint, gridPaint);
    }

    // Draw user competence shape
    final shapePaint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final values = [0.85, 0.72, 0.90, 0.68, 0.80];
    final path = Path();

    for (int i = 0; i < 5; i++) {
      final angle = step * i - math.pi / 2;
      final radius = maxRadius * values[i];
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, shapePaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlanFeatureGate extends StatelessWidget {
  final bool isUnlocked;
  final String requiredPlan;
  final Widget child;
  final VoidCallback onUpgrade;
  final bool isDarkMode;

  const PlanFeatureGate({
    super.key,
    required this.isUnlocked,
    required this.requiredPlan,
    required this.child,
    required this.onUpgrade,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) return child;

    final overlayBg = isDarkMode 
        ? Colors.black.withOpacity(0.55) 
        : Colors.white.withOpacity(0.55);
    final cardBg = isDarkMode ? const Color(0xFF1E1E2C) : Colors.white;
    final textCol = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final borderCol = isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    return Stack(
      children: [
        AbsorbPointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
            child: child,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: overlayBg,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF4F46E5),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Feature Locked',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Unlock this feature and amplify your career potential by upgrading to the $requiredPlan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onUpgrade,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Upgrade Plan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
