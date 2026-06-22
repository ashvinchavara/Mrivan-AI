import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../../theme/theme_config.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../data/services/database_service.dart';
import '../auth/payment_screen.dart';

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

  List<String> get _tabs {
    final plan = widget.paymentPlan.toLowerCase();
    if (plan.contains('campus')) {
      return [
        'Dashboard',
        'AI Teacher',
        'School CRM',
        'Career & Coach',
        'Performance',
      ];
    }
    final isPremium = plan.contains('premium');
    if (isPremium) {
      return [
        'Dashboard',
        'AI Teacher',
        'Career & Coach',
        'Performance',
      ];
    }
    return [
      'Dashboard',
      'AI Teacher',
      'Career & Coach',
      'Performance',
      'VIP Pass'
    ];
  }

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // debug logging
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _tabs.length) {
      _currentIndex = 0;
    }
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
        final tabName = _tabs[_currentIndex];
        if (tabName == 'Dashboard') {
          currentScreen = DashboardTab(
            userName: widget.userName,
            paymentPlan: widget.paymentPlan,
            isDarkMode: isDarkMode,
            onUpgrade: () {
              final upgradeIdx = _tabs.indexOf('VIP Pass');
              if (upgradeIdx != -1) {
                setState(() {
                  _currentIndex = upgradeIdx;
                });
              }
            },
          );
        } else if (tabName == 'AI Teacher') {
          currentScreen = AiTeacherTab(
            paymentPlan: widget.paymentPlan,
            isDarkMode: isDarkMode,
            onUpgrade: () {
              final upgradeIdx = _tabs.indexOf('VIP Pass');
              if (upgradeIdx != -1) {
                setState(() {
                  _currentIndex = upgradeIdx;
                });
              }
            },
          );
        } else if (tabName == 'School CRM') {
          currentScreen = StudentCrmTab(
            isDarkMode: isDarkMode,
          );
        } else if (tabName == 'Career & Coach') {
          final plan = widget.paymentPlan.toLowerCase();
          final hasAccess = plan.contains('pro') || plan.contains('aspirant') || plan.contains('premium') || plan.contains('campus');
          currentScreen = PlanFeatureGate(
            isUnlocked: hasAccess,
            requiredPlan: 'Pro Student Plan',
            isDarkMode: isDarkMode,
            onUpgrade: () {
              final upgradeIdx = _tabs.indexOf('VIP Pass');
              if (upgradeIdx != -1) {
                setState(() {
                  _currentIndex = upgradeIdx;
                });
              }
            },
            child: CareerCoachTab(isDarkMode: isDarkMode),
          );
        } else if (tabName == 'Performance') {
          final plan = widget.paymentPlan.toLowerCase();
          final hasAccess = plan.contains('pro') || plan.contains('aspirant') || plan.contains('premium') || plan.contains('campus');
          currentScreen = PlanFeatureGate(
            isUnlocked: hasAccess,
            requiredPlan: 'Pro Student/Exam Plan',
            isDarkMode: isDarkMode,
            onUpgrade: () {
              final upgradeIdx = _tabs.indexOf('VIP Pass');
              if (upgradeIdx != -1) {
                setState(() {
                  _currentIndex = upgradeIdx;
                });
              }
            },
            child: PerformanceAnalyticsTab(
              isDarkMode: isDarkMode,
              isCampusPlan: plan.contains('campus'),
            ),
          );
        } else if (tabName == 'VIP Pass') {
          currentScreen = PricingVipTab(
            paymentPlan: widget.paymentPlan,
            email: widget.email,
            isDarkMode: isDarkMode,
          );
        } else {
          currentScreen = DashboardTab(
            userName: widget.userName,
            paymentPlan: widget.paymentPlan,
            isDarkMode: isDarkMode,
            onUpgrade: () {
              final upgradeIdx = _tabs.indexOf('VIP Pass');
              if (upgradeIdx != -1) {
                setState(() {
                  _currentIndex = upgradeIdx;
                });
              }
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
                  items: _tabs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final name = entry.value;
                    return BottomNavigationBarItem(
                      icon: Icon(_getIcon(index)),
                      label: name == 'Career & Coach' ? 'Career' : (name == 'Performance' ? 'Analytics' : name),
                    );
                  }).toList(),
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
    if (index >= _tabs.length) return Icons.circle_outlined;
    final name = _tabs[index];
    switch (name) {
      case 'Dashboard':
        return Icons.dashboard_outlined;
      case 'AI Teacher':
        return Icons.chat_bubble_outline_rounded;
      case 'School CRM':
        return Icons.school_outlined;
      case 'Career & Coach':
        return Icons.rocket_launch_outlined;
      case 'Performance':
        return Icons.analytics_outlined;
      case 'VIP Pass':
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
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _sessions = [];
  String? _selectedSessionId;
  String? _selectedSubject = 'Math';
  String _gradeLevel = '10th Grade';
  List<Map<String, dynamic>> _messages = [];

  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;

  String _selectedLevel = 'Simple Explanation';
  int _queriesRemaining = 5;

  final List<String> _subjects = ['Math', 'Physics', 'Chemistry', 'Biology', 'History', 'English', 'Computer Science'];
  final List<String> _grades = [
    '1st Grade',
    '2nd Grade',
    '3rd Grade',
    '4th Grade',
    '5th Grade',
    '6th Grade',
    '7th Grade',
    '8th Grade',
    '9th Grade',
    '10th Grade',
    '11th Grade',
    '12th Grade',
    'College'
  ];

  @override
  void initState() {
    super.initState();
    _loadGradeFromProfile();
    _loadSessions();
    _loadDailyLimit();
  }

  Future<void> _loadGradeFromProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await _client
          .from('profiles')
          .select('class')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && profile['class'] != null && (profile['class'] as String).isNotEmpty) {
        if (mounted) {
          setState(() {
            _gradeLevel = profile['class'] as String;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading grade: $e');
    }
  }

  Future<void> _loadDailyLimit() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final dailyCount = await DatabaseService.instance.getDailyQueryCount(user.id);
      if (mounted) {
        setState(() {
          _queriesRemaining = math.max(0, 5 - dailyCount);
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading daily limit: $e');
    }
  }

  Future<void> _loadSessions() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingSessions = true;
    });

    try {
      final sessions = await DatabaseService.instance.fetchAIChatSessions(user.id);
      setState(() {
        _sessions = sessions;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading sessions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    }
  }

  Future<void> _selectSession(String sessionId) async {
    setState(() {
      _selectedSessionId = sessionId;
      _isLoadingMessages = true;
      _messages = [];
    });

    try {
      final messages = await DatabaseService.instance.fetchAIChatMessages(sessionId);
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    } catch (e) {
      if (kDebugMode) print('Error loading messages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  void _startTempSession() {
    final user = _client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to start chatting with the AI Tutor.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _selectedSessionId = 'temp';
      _messages = [
        {
          'id': 'welcome',
          'sender': 'ai',
          'content': 'Hello! I am Mr. Ivan, your AI $_selectedSubject tutor for $_gradeLevel. How can I help you learn today?',
          'timestamp': DateTime.now().toIso8601String(),
        }
      ];
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _selectedSessionId == null || _isSending) return;

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

    final user = _client.auth.currentUser;
    if (user == null) return;

    bool wasTemp = _selectedSessionId == 'temp';
    String activeSessionId = _selectedSessionId!;

    if (wasTemp) {
      setState(() {
        _isSending = true;
      });
      try {
        final sessionTitle = 'Tutor: $_selectedSubject - ${DateTime.now().day}/${DateTime.now().month}';
        final newSession = await DatabaseService.instance.createAIChatSession(
          user.id,
          sessionTitle,
          _selectedSubject ?? 'General',
        );
        activeSessionId = newSession['id'];

        // Also insert welcoming message in database
        final welcomeMsg = 'Hello! I am Mr. Ivan, your AI $_selectedSubject tutor for $_gradeLevel. How can I help you learn today?';
        await DatabaseService.instance.insertChatMessage(
          activeSessionId,
          'ai',
          welcomeMsg,
        );

        setState(() {
          _selectedSessionId = activeSessionId;
          _sessions.insert(0, newSession);
        });
      } catch (e) {
        if (kDebugMode) print('Error creating lazy session: $e');
        if (mounted) {
          setState(() {
            _isSending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start chat session: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    _chatController.clear();

    setState(() {
      _isSending = true;
      if (isFreePlan) {
        _queriesRemaining--;
      }
      // Optimistically insert user message locally
      _messages.add({
        'sender': 'user',
        'content': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    try {
      // 1. Call backend (with simulated offline fallback)
      String aiResponseText = '';
      try {
        final session = _sessions.firstWhere((s) => s['id'] == _selectedSessionId);
        final subjectStr = session['subject'] ?? 'General';
        
        // Retrieve JWT token to authorize with backend
        final jwtToken = _client.auth.currentSession?.accessToken;

        // Try calling the hosted backend API
        const envBackendUrl = String.fromEnvironment(
          'BACKEND_API_URL',
          defaultValue: 'https://mrivan-ai.onrender.com',
        );
        final urls = [
          '$envBackendUrl/api/ai/tutor/chat',
        ];

        // Append the selected level to grade level for context
        final combinedGradeLevel = '$_gradeLevel - $_selectedLevel';
        http.Response? response;
        dynamic lastError;

        for (final url in urls) {
          try {
            if (kDebugMode) {
              print('Attempting primary API request to Mr. Ivan (15s timeout)...');
            }
            response = await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Bypass-Tunnel-Reminder': 'true',
                if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
              },
              body: jsonEncode({
                'message': text,
                'sessionId': _selectedSessionId,
                'subject': subjectStr,
                'gradeLevel': combinedGradeLevel,
                'switchAi': false,
              }),
            ).timeout(const Duration(seconds: 15));
            
            if (response.statusCode == 200) {
              break;
            } else {
              throw Exception('Backend returned status code ${response.statusCode}');
            }
          } catch (e) {
            lastError = e;
            if (kDebugMode) {
              print('Primary AI attempt failed or timed out: $e. Switching AI and retrying (15s timeout)...');
            }
            try {
              response = await http.post(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Bypass-Tunnel-Reminder': 'true',
                  if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
                },
                body: jsonEncode({
                  'message': text,
                  'sessionId': _selectedSessionId,
                  'subject': subjectStr,
                  'gradeLevel': combinedGradeLevel,
                  'switchAi': true,
                }),
              ).timeout(const Duration(seconds: 15));
              
              if (response.statusCode == 200) {
                break;
              } else {
                throw Exception('Switched AI backend returned status code ${response.statusCode}');
              }
            } catch (retryError) {
              lastError = retryError;
              if (kDebugMode) {
                print('Switched AI attempt failed or timed out: $retryError');
              }
            }
          }
        }

        if (response != null && response.statusCode == 200) {
          final data = jsonDecode(response.body);
          aiResponseText = data['response'] ?? '';
        } else {
          throw lastError ?? Exception('Could not connect to any backend API endpoint');
        }
      } catch (backendError) {
        if (kDebugMode) {
          print('Backend offline or failed, using simulated response: $backendError');
        }
        // Fallback: Generate smart simulated pedagogical response
        aiResponseText = _generateSimulatedResponse(text);
        
        // Save user message to Supabase directly since backend was offline
        await DatabaseService.instance.insertChatMessage(
          _selectedSessionId!,
          'user',
          text,
        );
        
        // Save simulated response to Supabase directly
        await DatabaseService.instance.insertChatMessage(
          _selectedSessionId!,
          'ai',
          aiResponseText,
        );
      }

      // 3. Load latest messages
      final updatedMessages = await DatabaseService.instance.fetchAIChatMessages(_selectedSessionId!);
      setState(() {
        _messages = updatedMessages;
      });
      _scrollToBottom();

    } catch (e) {
      if (kDebugMode) print('Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      _scrollToBottom();
    }
  }

  String _generateSimulatedResponse(String prompt) {
    final cleanPrompt = prompt.toLowerCase();
    
    if (cleanPrompt.contains('hello') || cleanPrompt.contains('hi')) {
      return "Hello! I'm here. Let's tackle any hard concept you have. Ask me about formulas, theories, or concepts you're finding tricky!";
    }
    if (cleanPrompt.contains('solve') || cleanPrompt.contains('calculate')) {
      return "I can explain the steps! In physics or math, we start by list-identifying the given variables, selecting the appropriate formula, and solving systematically. Could you share the specific values you have?";
    }
    if (cleanPrompt.contains('why') || cleanPrompt.contains('how')) {
      return "That's an excellent question! In science, we study the fundamental causes. Let's break it down: \n\n1. **First Principle**: Everything starts from basic definitions. \n2. **The Mechanism**: There is a cause-and-effect loop. \n3. **Practical Analogy**: Think of it like water flowing through a pipe - voltage is the pressure, current is the flow.\n\nDoes this analogy make sense, or would you like another example?";
    }
    if (cleanPrompt.contains('exam') || cleanPrompt.contains('quiz')) {
      return "Preparing for a test can be smooth! Try writing down the 3 core formulas from memory. I can generate some practice questions for you if you'd like.";
    }

    return "Fascinating concept! To understand this deeply, let's explore the key ideas:\n\n* **Core Concept**: This relates to foundational parameters of this subject.\n* **Key takeaway**: Always double check the assumptions before formulating a solution.\n\nWould you like me to explain this in more detail, or give you a quick quiz to check your understanding?";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildFormattedMessage(String content, bool isAI, Color textColor) {
    if (!content.contains('**') && !content.contains('- ') && !content.contains('* ') && !content.contains('\n-') && !content.contains('\n*')) {
      return Text(
        content,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: textColor,
        ),
      );
    }

    final lines = content.split('\n');
    final List<Widget> lineWidgets = [];

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        lineWidgets.add(const SizedBox(height: 6));
        continue;
      }

      bool isBullet = false;
      String lineText = line;

      // Handle bullet points starting with "- " or "* "
      if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ')) {
        isBullet = true;
        final prefixLength = trimmedLine.startsWith('- ') ? 2 : 2;
        final index = line.indexOf(trimmedLine.startsWith('- ') ? '- ' : '* ');
        lineText = line.substring(index + prefixLength);
      }

      final List<InlineSpan> spans = [];
      final parts = lineText.split('**');
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i % 2 == 1) {
          spans.add(TextSpan(
            text: part,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 13,
            ),
          ));
        } else {
          if (part.isNotEmpty) {
            spans.add(TextSpan(
              text: part,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
              ),
            ));
          }
        }
      }

      final lineContent = RichText(
        text: TextSpan(
          children: spans,
          style: const TextStyle(
            height: 1.4,
          ),
        ),
      );

      if (isBullet) {
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(child: lineContent),
              ],
            ),
          ),
        );
      } else {
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: lineContent,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lineWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final chatBubbleBg = widget.isDarkMode ? const Color(0xFF1E1E2C) : const Color(0xFFF1F5F9);
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                ),
              );
            },
            child: _selectedSessionId == null
                ? Column(
                    key: const ValueKey('teacher-header-expanded'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
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
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      runConfigChips(),
                      const SizedBox(height: 20),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('teacher-header-collapsed')),
          ),

          // MAIN CONTAINER BODY (GRID / ROW)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sessions list sidebar (Desktop only)
                if (size.width > 750)
                  Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'History',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: currentText,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_comment_rounded, color: Color(0xFF4F46E5), size: 18),
                              onPressed: _showStartSessionDialog,
                              tooltip: 'New Session',
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                        Expanded(
                          child: _isLoadingSessions
                              ? const Center(child: CircularProgressIndicator())
                              : _sessions.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No past chats',
                                        style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _sessions.length,
                                      itemBuilder: (context, index) {
                                        final session = _sessions[index];
                                        final isSelected = session['id'] == _selectedSessionId;
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05))
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                            dense: true,
                                            title: Text(
                                              session['title'] ?? 'Chat Session',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: currentText,
                                              ),
                                            ),
                                            subtitle: Text(
                                              session['subject'] ?? 'General',
                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            ),
                                            onTap: () => _selectSession(session['id']),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),

                // Main panel
                Expanded(
                  child: _selectedSessionId == null
                      ? Stack(
                          children: [
                            _buildCreateSessionPanel(currentText, cardBg, borderCol),
                            if (_isLoadingMessages)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChatConfigDropdown(currentText, cardBg, borderCol),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _buildChatPanel(currentText, cardBg, borderCol, chatBubbleBg),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget runConfigChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildConfigChip('Simple Explanation', Icons.face),
          const SizedBox(width: 12),
          _buildConfigChip('Detailed Scientific Code', Icons.code),
          const SizedBox(width: 12),
          _buildConfigChip('Analogies & Flashcards', Icons.collections),
          const SizedBox(width: 12),
          _buildConfigChip('Socratic Method Practice', Icons.question_answer),
        ],
      ),
    );
  }

  Widget _buildChatConfigDropdown(Color currentText, Color cardBg, Color borderCol) {
    IconData getIconForStyle(String style) {
      switch (style) {
        case 'Simple Explanation': return Icons.face_rounded;
        case 'Detailed Scientific Code': return Icons.code_rounded;
        case 'Analogies & Flashcards': return Icons.collections_rounded;
        case 'Socratic Method Practice': return Icons.question_answer_rounded;
        default: return Icons.face_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLevel,
              dropdownColor: cardBg,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 20),
              style: TextStyle(color: currentText, fontSize: 12, fontWeight: FontWeight.w600),
              items: [
                'Simple Explanation',
                'Detailed Scientific Code',
                'Analogies & Flashcards',
                'Socratic Method Practice'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(getIconForStyle(value), color: const Color(0xFF4F46E5).withOpacity(0.7), size: 14),
                      const SizedBox(width: 8),
                      Text(value, style: TextStyle(color: currentText, fontSize: 12, fontWeight: FontWeight.normal)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLevel = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
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

  Widget _buildCreateSessionPanel(Color currentText, Color cardBg, Color borderCol) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 50,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start a New Learning Session',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: currentText,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select your subject and grade level to begin personalized tutoring.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                // Subject Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  dropdownColor: cardBg,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                  ),
                  items: _subjects.map((sub) {
                    return DropdownMenuItem(value: sub, child: Text(sub));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSubject = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Grade Level (Locked to registration)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Grade Level (Locked)',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                    suffixIcon: const Icon(Icons.lock_rounded, color: Colors.grey, size: 16),
                  ),
                  child: Text(
                    _gradeLevel,
                    style: TextStyle(color: currentText, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _startTempSession,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoadingMessages
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Start Chatting', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (MediaQuery.of(context).size.width <= 750 && _sessions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showHistorySheet,
                    child: const Text(
                      'View Chat History',
                      style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel(Color currentText, Color cardBg, Color borderCol, Color chatBubbleBg) {
    final activeSession = _sessions.firstWhere(
      (s) => s['id'] == _selectedSessionId,
      orElse: () => {'title': 'Tutor: ${_selectedSubject ?? 'General'}'},
    );
    final isFreePlan = widget.paymentPlan.toLowerCase().contains('free');

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          // Active chat sub-header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              border: Border(bottom: BorderSide(color: borderCol)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: currentText, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedSessionId = null;
                    });
                  },
                  tooltip: 'Back to Sessions',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeSession['title'] ?? 'AI Tutor Chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: currentText,
                    ),
                  ),
                ),
                if (isFreePlan) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2A6D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFF2A6D).withOpacity(0.2)),
                    ),
                    child: Text(
                      '$_queriesRemaining remaining',
                      style: const TextStyle(color: Color(0xFFFF2A6D), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Messages View
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isAI = msg['sender'] == 'ai';
                          return Align(
                            alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.65,
                              ),
                              decoration: BoxDecoration(
                                color: isAI
                                    ? chatBubbleBg
                                    : const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isAI ? 0 : 16),
                                  bottomRight: Radius.circular(isAI ? 16 : 0),
                                ),
                                border: isAI
                                    ? Border.all(color: borderCol)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFormattedMessage(
                                    msg['content'] ?? '',
                                    isAI,
                                    isAI ? currentText : Colors.white,
                                  ),
                                  if (isAI) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: msg['content'] ?? ''));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Content copied to clipboard'),
                                              backgroundColor: Color(0xFF4F46E5),
                                              behavior: SnackBarBehavior.floating,
                                              duration: Duration(seconds: 1),
                                              width: 200,
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.copy_rounded,
                                                size: 14,
                                                color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Copy',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Loading/Sending Indicator
          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mr. Ivan is thinking...',
                    style: TextStyle(fontSize: 11, color: widget.isDarkMode ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            ),

          Divider(color: borderCol, height: 1),
          // Input Box
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (isFreePlan || widget.paymentPlan.toLowerCase().contains('basic')) {
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
                    color: (isFreePlan || widget.paymentPlan.toLowerCase().contains('basic'))
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
                      hintText: 'Ask a learning question...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _chatController,
                  builder: (context, value, child) {
                    final isTextEmpty = value.text.trim().isEmpty;
                    return Opacity(
                      opacity: isTextEmpty ? 0.5 : 1.0,
                      child: CircleAvatar(
                        backgroundColor: isTextEmpty ? Colors.grey : const Color(0xFF4F46E5),
                        child: IconButton(
                          onPressed: isTextEmpty ? null : _sendMessage,
                          icon: const Icon(Icons.send, size: 16, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStartSessionDialog() {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      builder: (context) {
        String? localSubject = _selectedSubject;
        String? localGrade = _gradeLevel;
        return AlertDialog(
          backgroundColor: cardBg,
          title: Text('Start New Session', style: TextStyle(color: currentText, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: localSubject,
                dropdownColor: cardBg,
                style: TextStyle(color: currentText, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                ),
                items: _subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                onChanged: (val) => localSubject = val,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Grade Level (Locked)',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                  suffixIcon: const Icon(Icons.lock_rounded, color: Colors.grey, size: 16),
                ),
                child: Text(
                  _gradeLevel,
                  style: TextStyle(color: currentText, fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSubject = localSubject;
                });
                Navigator.pop(context);
                _startTempSession();
              },
              child: const Text('Create', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showHistorySheet() {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: Container(
            color: cardBg,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat Sessions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: currentText,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return ListTile(
                        title: Text(
                          session['title'] ?? '',
                          style: TextStyle(color: currentText),
                        ),
                        subtitle: Text(session['subject'] ?? 'General', style: const TextStyle(color: Colors.grey)),
                        onTap: () {
                          Navigator.pop(context);
                          _selectSession(session['id']);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
class PerformanceAnalyticsTab extends StatefulWidget {
  final bool isDarkMode;
  final bool isCampusPlan;

  const PerformanceAnalyticsTab({
    super.key,
    required this.isDarkMode,
    required this.isCampusPlan,
  });

  @override
  State<PerformanceAnalyticsTab> createState() => _PerformanceAnalyticsTabState();
}

class _PerformanceAnalyticsTabState extends State<PerformanceAnalyticsTab> {
  final _chapterNameController = TextEditingController();
  final _topicController = TextEditingController();

  List<Map<String, dynamic>> _customChapters = [];
  List<String> _tempTopics = [];

  @override
  void initState() {
    super.initState();
    // Default pre-populated syllabus if user hasn't added one yet
    _customChapters = [
      {
        'chapter_name': 'Chapter 1: Core System Architecture',
        'topics': [
          {'topic_name': 'Memory Management & Garbage Collection', 'completed': true},
          {'topic_name': 'Process Scheduling & Thread Safety', 'completed': true},
          {'topic_name': 'Concurrency & Deadlocks', 'completed': false},
        ]
      },
      {
        'chapter_name': 'Chapter 2: Backend & Distributed Systems',
        'topics': [
          {'topic_name': 'Microservices & Service Discovery', 'completed': false},
          {'topic_name': 'Database Partitioning & Replication', 'completed': false},
        ]
      },
    ];
  }

  @override
  void dispose() {
    _chapterNameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _addTopic() {
    final rawText = _topicController.text;
    if (rawText.trim().isEmpty) return;

    final topics = rawText
        .split('\n')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() {
      for (final t in topics) {
        if (!_tempTopics.contains(t)) {
          _tempTopics.add(t);
        }
      }
      _topicController.clear();
    });
  }

  void _commitChapter() {
    final chName = _chapterNameController.text.trim();
    if (chName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Chapter/Lesson Name.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_tempTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one topic to this chapter.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _customChapters.add({
        'chapter_name': chName,
        'topics': _tempTopics.map((t) => {'topic_name': t, 'completed': false}).toList(),
      });
      _chapterNameController.clear();
      _topicController.clear();
      _tempTopics.clear();
    });
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 950;
    
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    // Calculate progress if not campus plan
    double overallProgress = 0.0;
    int totalTopics = 0;
    int completedTopics = 0;
    if (!widget.isCampusPlan) {
      int total = 0;
      int completed = 0;
      for (final ch in _customChapters) {
        final List topics = ch['topics'] ?? [];
        total += topics.length;
        completed += topics.where((t) => t['completed'] == true).length;
      }
      totalTopics = total;
      completedTopics = completed;
      overallProgress = total > 0 ? completed / total : 0.0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isCampusPlan 
                ? 'Advanced Analytics & Revision Space 📊'
                : 'Personal Performance & Syllabus Tracker 📊', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText)
          ),
          const SizedBox(height: 8),
          Text(
            widget.isCampusPlan
                ? 'Review mock test outcomes, monthly skill trends, and predictive growth ratings.'
                : 'Define your curriculum, track topic-wise completion, and visualize your exam readiness.',
            style: const TextStyle(color: Colors.grey, fontSize: 12)
          ),
          const SizedBox(height: 24),

          if (!widget.isCampusPlan) ...[
            // Syllabus Progress Visualization Row
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                // 1. Circular gauge card
                Container(
                  width: isDesktop ? 300 : double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Syllabus Coverage',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentText),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: CustomPaint(
                          painter: SyllabusProgressPainter(
                            progress: overallProgress,
                            isDarkMode: widget.isDarkMode,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${(overallProgress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: currentText,
                                  ),
                                ),
                                const Text(
                                  'Completed',
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Metrics & revision checklist card
                Container(
                  width: isDesktop ? size.width - 300 - 88 : double.infinity,
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(minHeight: 198),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curriculum Summary',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentText),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Chapters', _customChapters.length.toString(), currentText),
                          _buildStatItem('Total Topics', totalTopics.toString(), currentText),
                          _buildStatItem('Completed', completedTopics.toString(), currentText),
                          _buildStatItem(
                            'Ready Score',
                            '${(overallProgress * 100).toStringAsFixed(0)}%',
                            overallProgress >= 0.8
                                ? Colors.green
                                : (overallProgress >= 0.5 ? Colors.amber : Colors.redAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'AI Learning Insights:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallProgress == 1.0
                            ? '🎉 Phenomenal! You have covered 100% of your course syllabus. You are ready to take high-level mock exams.'
                            : overallProgress >= 0.5
                                ? '👍 Great progress! Focus on finishing the remaining ${totalTopics - completedTopics} topics and start revision Recall drills.'
                                : '📚 Keep going! Add your lesson syllabus, and check off topics as you study them with your AI Tutor.',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Syllabus Input Form & Checklist
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track & Configure Your Syllabus 📚',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentText),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add course chapters and topics to track your self-study and revision readiness.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  
                  // Chapter Input Row
                  TextField(
                    controller: _chapterNameController,
                    style: TextStyle(color: currentText, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Chapter Name (e.g. Chapter 3: Relational Databases)',
                      labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Topic input row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _topicController,
                          style: TextStyle(color: currentText, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Topic Name (e.g. SQL Joins & Subqueries)',
                            labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addTopic(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addTopic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),

                  // Temp topics wrap
                  if (_tempTopics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _tempTopics.map((t) {
                        return InputChip(
                          backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.04),
                          label: Text(t, style: TextStyle(color: currentText, fontSize: 11)),
                          onDeleted: () {
                            setState(() {
                              _tempTopics.remove(t);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _commitChapter,
                        icon: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                        label: const Text('Add Chapter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_customChapters.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _customChapters.clear();
                              _tempTopics.clear();
                            });
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                          label: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Checklist list
                  Text(
                    'Your Study Checklist',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentText),
                  ),
                  const SizedBox(height: 12),
                  _customChapters.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No chapters added yet. Add a chapter above to start tracking!',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _customChapters.length,
                          itemBuilder: (context, cIdx) {
                            final ch = _customChapters[cIdx];
                            final String chName = ch['chapter_name'] ?? '';
                            final List topics = ch['topics'] ?? [];
                            
                            // Calculate chapter progress
                            final chCompleted = topics.where((t) => t['completed'] == true).length;
                            final chTotal = topics.length;
                            final chPct = chTotal > 0 ? chCompleted / chTotal : 0.0;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: widget.isDarkMode ? const Color(0xFF1E1E2F) : Colors.grey.withOpacity(0.05),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: borderCol),
                              ),
                              child: ExpansionTile(
                                leading: Icon(
                                  chPct == 1.0
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_actions_rounded,
                                  color: chPct == 1.0 ? Colors.green : const Color(0xFF4F46E5),
                                ),
                                title: Text(
                                  chName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: currentText,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: chPct,
                                            backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${(chPct * 100).toStringAsFixed(0)}% ($chCompleted/$chTotal)',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _customChapters.removeAt(cIdx);
                                    });
                                  },
                                ),
                                children: topics.map((t) {
                                  final String tName = t['topic_name'] ?? '';
                                  final bool isCompleted = t['completed'] ?? false;
                                  return CheckboxListTile(
                                    title: Text(
                                      tName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isCompleted ? Colors.grey : currentText,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    value: isCompleted,
                                    activeColor: const Color(0xFF4F46E5),
                                    onChanged: (val) {
                                      setState(() {
                                        t['completed'] = val ?? false;
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

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
                          painter: GrowthChartPainter(
                            isDarkMode: widget.isDarkMode,
                            progress: widget.isCampusPlan ? 0.8 : overallProgress,
                          ),
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
                          painter: SkillRadarPainter(
                            isDarkMode: widget.isDarkMode,
                            progressValues: widget.isCampusPlan
                                ? [0.85, 0.72, 0.90, 0.68, 0.80]
                                : [
                                    0.4 + (overallProgress * 0.45),
                                    0.3 + (overallProgress * 0.52),
                                    0.5 + (overallProgress * 0.40),
                                    0.2 + (overallProgress * 0.68),
                                    0.35 + (overallProgress * 0.55),
                                  ],
                          ),
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

  static const List<_PricingPlanInfo> _allPlans = [
    _PricingPlanInfo(
      icon: Icons.menu_book_rounded,
      title: 'Free Plan',
      price: 'Free',
      subtitle: 'For first-time learners',
      color: Colors.teal,
      features: ['5 doubt solutions/day', 'Basic notes', 'Limited tests'],
    ),
    _PricingPlanInfo(
      icon: Icons.bolt_rounded,
      title: 'Basic Plan',
      price: 'Rs 99/mo',
      subtitle: 'Affordable daily study help',
      color: Color(0xFF4F46E5),
      features: ['Unlimited doubts', 'AI Tutor access', 'Weekly mock tests'],
    ),
    _PricingPlanInfo(
      icon: Icons.apartment_rounded,
      title: 'Campus Plan',
      price: 'Rs 149 per student/mo',
      subtitle: 'For schools and institutions',
      color: Colors.teal,
      features: ['Teacher & Student dashboards', 'Attendance & Homework CRM', 'School Analytics'],
    ),
    _PricingPlanInfo(
      icon: Icons.workspace_premium_rounded,
      title: 'Pro Student',
      price: 'Rs 299/mo',
      subtitle: 'For personalized AI learning',
      color: Color(0xFF4F46E5),
      features: ['Everything in Basic', 'Unlimited AI chats', 'Voice AI Tutor', 'AI summaries & quizzes'],
    ),
    _PricingPlanInfo(
      icon: Icons.military_tech_rounded,
      title: 'Exam Aspirant',
      price: 'Rs 499/mo',
      subtitle: 'For exam-focused preparation',
      color: Colors.pink,
      features: ['Everything in Pro', 'CBT Mock Tests', 'Previous Year Questions', 'Revision planner'],
    ),
    _PricingPlanInfo(
      icon: Icons.diamond_rounded,
      title: 'Premium AI',
      price: 'Rs 999/mo',
      subtitle: 'For advanced AI productivity',
      color: Color(0xFF7C3AED),
      features: ['Everything in Exam Aspirant', 'AI Image, Writing & Coding Tutors', 'Early access features'],
    ),
  ];

  int _getPlanRank(String planName) {
    final name = planName.toLowerCase();
    if (name.contains('premium')) return 5;
    if (name.contains('aspirant') || name.contains('exam')) return 4;
    if (name.contains('pro')) return 3;
    if (name.contains('campus')) return 2;
    if (name.contains('basic')) return 1;
    return 0; // Free/unknown
  }

  @override
  Widget build(BuildContext context) {
    final currentText = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    final currentRank = _getPlanRank(paymentPlan);
    final higherPlans = _allPlans.where((plan) {
      final planRank = _getPlanRank(plan.title);
      return planRank > currentRank;
    }).toList();

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

          if (higherPlans.isNotEmpty) ...[
            Text('Upgrade Plan Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentText)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 3 : (MediaQuery.of(context).size.width >= 600 ? 2 : 1),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: higherPlans.length,
              itemBuilder: (context, index) {
                final plan = higherPlans[index];
                return _buildPlanUpgradeCard(context, plan, cardBg, currentText, borderCol);
              },
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'You are on the Highest Plan! 🎉',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentText),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You currently have access to all Premium AI tools, CBT preparation materials, and advanced teacher features. Thank you for being a premium member!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanUpgradeCard(
    BuildContext context,
    _PricingPlanInfo plan,
    Color bg,
    Color textCol,
    Color borderCol,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: plan.color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: plan.color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: plan.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(plan.icon, color: plan.color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textCol,
                      ),
                    ),
                    Text(
                      plan.price,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: plan.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: plan.features.map((f) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: plan.color, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(fontSize: 10, color: textCol.withOpacity(0.8)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: bg,
                    title: Text('Upgrade to ${plan.title}', style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.bold)),
                    content: Text('Would you like to upgrade your plan to ${plan.title} for ${plan.price}?', style: TextStyle(color: textCol, fontSize: 13)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                planTitle: plan.title,
                                planPrice: plan.price,
                                planSubtitle: plan.subtitle,
                              ),
                            ),
                          );
                        },
                        child: const Text('Confirm & Pay', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingPlanInfo {
  final IconData icon;
  final String title;
  final String price;
  final String subtitle;
  final Color color;
  final List<String> features;

  const _PricingPlanInfo({
    required this.icon,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.color,
    required this.features,
  });
}

// ==========================================
// CUSTOM PAINTERS
// ==========================================

class SyllabusProgressPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;

  SyllabusProgressPainter({required this.progress, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;

    // Background track
    final bgPaint = Paint()
      ..color = isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Glowing active progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF00F2FE)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SyllabusProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDarkMode != isDarkMode;
  }
}

class GrowthChartPainter extends CustomPainter {
  final bool isDarkMode;
  final double progress;
  GrowthChartPainter({required this.isDarkMode, required this.progress});

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

    final double scale = progress;

    // Line 1: Theoretical Knowledge
    final path1 = Path();
    path1.moveTo(0, size.height * 0.85);
    path1.cubicTo(
      size.width * 0.25, size.height * (0.85 - (0.85 - 0.70) * scale),
      size.width * 0.50, size.height * (0.85 - (0.85 - 0.45) * scale),
      size.width * 0.75, size.height * (0.85 - (0.85 - 0.35) * scale),
    );
    path1.lineTo(size.width, size.height * (0.85 - (0.85 - 0.20) * scale));

    final strokePaint1 = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Line 2: Practical Coding Scale
    final path2 = Path();
    path2.moveTo(0, size.height * 0.95);
    path2.cubicTo(
      size.width * 0.25, size.height * (0.95 - (0.95 - 0.85) * scale),
      size.width * 0.50, size.height * (0.95 - (0.95 - 0.65) * scale),
      size.width * 0.75, size.height * (0.95 - (0.95 - 0.25) * scale),
    );
    path2.lineTo(size.width, size.height * (0.95 - (0.95 - 0.10) * scale));

    final strokePaint2 = Paint()
      ..color = const Color(0xFF00F2FE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw lines
    canvas.drawPath(path1, strokePaint1);
    canvas.drawPath(path2, strokePaint2);
  }

  @override
  bool shouldRepaint(covariant GrowthChartPainter oldDelegate) {
    return oldDelegate.isDarkMode != isDarkMode || oldDelegate.progress != progress;
  }
}

class SkillRadarPainter extends CustomPainter {
  final bool isDarkMode;
  final List<double> progressValues;
  SkillRadarPainter({required this.isDarkMode, required this.progressValues});

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

    final values = progressValues;
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
  bool shouldRepaint(covariant SkillRadarPainter oldDelegate) {
    return oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.progressValues.length != progressValues.length ||
        !listEquals(oldDelegate.progressValues, progressValues);
  }
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

class StudentCrmTab extends StatefulWidget {
  final bool isDarkMode;

  const StudentCrmTab({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<StudentCrmTab> createState() => _StudentCrmTabState();
}

class _StudentCrmTabState extends State<StudentCrmTab> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _loading = true;
  String _classId = '';
  String _className = '';
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _homeworkList = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _submissions = [];
  List<Map<String, dynamic>> _testAttempts = [];
  List<Map<String, dynamic>> _syllabusList = [];

  @override
  void initState() {
    super.initState();
    _loadCrmData();
  }

  Future<void> _loadCrmData() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final profile = await _client
          .from('profiles')
          .select('class_id, class')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _classId = profile['class_id'] as String? ?? '';
        _className = profile['class'] as String? ?? 'N/A';
      }

      final attList = await DatabaseService.instance.fetchAttendance(studentId: user.id);

      List<Map<String, dynamic>> notesList = [];
      if (_classId.isNotEmpty) {
        notesList = await DatabaseService.instance.fetchClassNotes(_classId, user.id);
      }

      List<Map<String, dynamic>> hwList = [];
      if (_classId.isNotEmpty) {
        hwList = await DatabaseService.instance.fetchHomework(classId: _classId);
      }

      final subList = await _client
          .from('homework_submissions')
          .select('homework_id, grade, feedback, submission_text')
          .eq('student_id', user.id);

      final attempts = await _client
          .from('test_attempts')
          .select('score, mock_tests(title, total_marks)')
          .eq('student_id', user.id);

      List<Map<String, dynamic>> syllabusData = [];
      if (_classId.isNotEmpty) {
        syllabusData = await DatabaseService.instance.fetchSyllabus(classId: _classId);
      }

      setState(() {
        _attendance = attList;
        _notes = notesList;
        _homeworkList = hwList;
        _submissions = List<Map<String, dynamic>>.from(subList);
        _testAttempts = List<Map<String, dynamic>>.from(attempts);
        _syllabusList = syllabusData;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading CRM data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitHomeworkText(String hwId, String text) async {
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await DatabaseService.instance.submitHomework(
        homeworkId: hwId,
        studentId: user.id,
        submissionText: text,
      );
      await _loadCrmData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homework submitted successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _loading = false);
    }
  }

  void _showSubmitDialog(String hwId, String title) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
        return AlertDialog(
          backgroundColor: cardBg,
          title: Text('Submit Assignment', style: TextStyle(color: currentText, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Topic: $title', style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                style: TextStyle(color: currentText, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Type your homework submission here...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isNotEmpty) {
                  Navigator.pop(context);
                  _submitHomeworkText(hwId, txt);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _getFormattedSyllabusText(String rawContent) {
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is List) {
        final chapters = List<Map<String, dynamic>>.from(
          decoded.map((x) => Map<String, dynamic>.from(x))
        );
        final buffer = StringBuffer();
        for (var i = 0; i < chapters.length; i++) {
          final ch = chapters[i];
          final chName = ch['chapter_name'] ?? '';
          final List topics = ch['topics'] ?? [];
          buffer.writeln(chName);
          for (final t in topics) {
            buffer.writeln('• $t');
          }
          if (i < chapters.length - 1) {
            buffer.writeln(); // Blank line between chapters
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    return rawContent;
  }

  Widget _buildSyllabusContent(String rawContent, Color currentText) {
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is List) {
        final chapters = List<Map<String, dynamic>>.from(
          decoded.map((x) => Map<String, dynamic>.from(x))
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chapters.map((ch) {
            final chName = ch['chapter_name'] ?? '';
            final List topics = ch['topics'] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chName,
                    style: TextStyle(
                      color: currentText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...topics.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: currentText.withOpacity(0.7), fontSize: 11)),
                        Expanded(
                          child: Text(
                            t.toString(),
                            style: TextStyle(
                              color: currentText.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            );
          }).toList(),
        );
      }
    } catch (_) {}

    // Fallback plain text layout
    return Text(
      rawContent,
      style: TextStyle(color: currentText, fontSize: 12, height: 1.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalAttendance = _attendance.length;
    final presentAttendance = _attendance.where((a) => a['status'] == 'Present' || a['status'] == 'Late').length;
    final attendancePercentage = totalAttendance > 0 ? (presentAttendance / totalAttendance) : 1.0;

    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'School CRM Cockpit 🎒',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
                  ),
                  const SizedBox(height: 4),
                  Text('Class: $_className | Live Database Sync Active', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
                onPressed: () {
                  setState(() => _loading = true);
                  _loadCrmData();
                },
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF4F46E5),
            tabs: const [
              Tab(text: 'Attendance Log'),
              Tab(text: 'Homework Hub'),
              Tab(text: 'Marks Scorecard'),
              Tab(text: 'Class Notes'),
              Tab(text: 'Class Syllabus'),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              children: [
                // 1. Attendance Log
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: CircularProgressIndicator(
                                  value: attendancePercentage,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.grey.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                ),
                              ),
                              Text(
                                '${(attendancePercentage * 100).toStringAsFixed(0)}%',
                                style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ATTENDANCE INDEX', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  attendancePercentage >= 0.85 ? 'Excellent attendance record!' : 'Attendance is below 85% requirement.',
                                  style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text('Attended $presentAttendance out of $totalAttendance lectures logged.', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _attendance.isEmpty
                          ? Center(child: Text('No attendance logs recorded in the database yet.', style: TextStyle(color: currentText)))
                          : ListView.builder(
                              itemCount: _attendance.length,
                              itemBuilder: (context, idx) {
                                final att = _attendance[idx];
                                final isPresent = att['status'] == 'Present';
                                final isLate = att['status'] == 'Late';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_month, color: Colors.grey, size: 18),
                                          const SizedBox(width: 12),
                                          Text(att['date'] ?? 'N/A', style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isPresent
                                              ? Colors.green.withOpacity(0.1)
                                              : isLate
                                                  ? Colors.orange.withOpacity(0.1)
                                                  : Colors.redAccent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          att['status'] ?? 'Present',
                                          style: TextStyle(
                                            color: isPresent
                                                ? Colors.green
                                                : isLate
                                                    ? Colors.orange
                                                    : Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // 2. Homework Hub
                _homeworkList.isEmpty
                    ? Center(child: Text('No homework assignments assigned to your class.', style: TextStyle(color: currentText)))
                    : ListView.builder(
                        itemCount: _homeworkList.length,
                        itemBuilder: (context, idx) {
                          final hw = _homeworkList[idx];
                          final submission = _submissions.firstWhere(
                            (s) => s['homework_id'] == hw['id'],
                            orElse: () => {},
                          );

                          final isSubmitted = submission.isNotEmpty;
                          final grade = submission['grade'] as String?;
                          final isGraded = grade != null && grade.isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(hw['title'] ?? '', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isGraded
                                            ? Colors.green.withOpacity(0.1)
                                            : isSubmitted
                                                ? Colors.orange.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isGraded
                                            ? 'Graded: $grade'
                                            : isSubmitted
                                                ? 'Submitted'
                                                : 'Pending',
                                        style: TextStyle(
                                          color: isGraded
                                              ? Colors.green
                                              : isSubmitted
                                                  ? Colors.orange
                                                  : Colors.grey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(hw['description'] ?? 'No instructions', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text('Due Date: ${hw['due_date'] ?? 'N/A'}', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                if (isGraded && submission['feedback'] != null && submission['feedback'].isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text('Teacher Review: ${submission['feedback']}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                                ],
                                if (!isSubmitted) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton(
                                      onPressed: () => _showSubmitDialog(hw['id'], hw['title'] ?? ''),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                                      child: const Text('Submit Assignment', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                // 3. Marks Scorecard
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grades & Scorecard Logs', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _submissions.isEmpty && _testAttempts.isEmpty
                          ? Center(child: Text('No academic grades logged yet.', style: TextStyle(color: currentText)))
                          : ListView(
                              children: [
                                if (_submissions.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text('GRADED ASSIGNMENTS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  ..._submissions.map((sub) {
                                    final homework = _homeworkList.firstWhere((h) => h['id'] == sub['homework_id'], orElse: () => {});
                                    final title = homework.isNotEmpty ? homework['title'] : 'Class Assignment';
                                    final grade = sub['grade'] ?? 'Pending';
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.05))),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(title, style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold)),
                                                if (sub['feedback'] != null && sub['feedback'].isNotEmpty)
                                                  Text('Feedback: ${sub['feedback']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text('Grade: $grade', style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                if (_testAttempts.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text('MOCK TEST ATTEMPTS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  ..._testAttempts.map((attempt) {
                                    final title = attempt['mock_tests']?['title'] ?? 'Mock Test';
                                    final total = attempt['mock_tests']?['total_marks'] ?? 100;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.05))),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(title, style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                            child: Text('Score: ${attempt['score']} / $total', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),

                // 4. Class Notes Library
                _notes.isEmpty
                    ? Center(child: Text('No notes shared with your class yet.', style: TextStyle(color: currentText)))
                    : ListView.builder(
                        itemCount: _notes.length,
                        itemBuilder: (context, idx) {
                          final note = _notes[idx];
                          final isAi = note['is_ai_generated'] ?? false;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note['title'] ?? '',
                                        style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (isAi)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('AI Generated', style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        IconButton(
                                          icon: Icon(Icons.copy_rounded, color: Colors.grey, size: 16),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: note['content'] ?? ''));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Note content copied to clipboard!'),
                                                backgroundColor: Color(0xFF4F46E5),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          tooltip: 'Copy Note',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Subject: ${note['subject'] ?? 'General'}', style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    note['content'] ?? '',
                                    style: TextStyle(color: currentText, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                // 5. Class Syllabus Viewer
                _syllabusList.isEmpty
                    ? Center(child: Text('No syllabus guidelines published for your class yet.', style: TextStyle(color: currentText)))
                    : ListView.builder(
                        itemCount: _syllabusList.length,
                        itemBuilder: (context, idx) {
                          final syllabus = _syllabusList[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        syllabus['subject'] ?? '',
                                        style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 16),
                                      onPressed: () {
                                        final copyText = _getFormattedSyllabusText(syllabus['content'] ?? '');
                                        Clipboard.setData(ClipboardData(text: copyText));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Syllabus content copied to clipboard!'),
                                            backgroundColor: Color(0xFF4F46E5),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      tooltip: 'Copy Syllabus',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _buildSyllabusContent(
                                    syllabus['content'] ?? '',
                                    currentText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
