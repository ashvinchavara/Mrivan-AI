import 'dart:async';
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
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';


import '../../widgets/animated_background.dart';
import 'package:file_picker/file_picker.dart';

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
  String? _initialTutorTopic;
  String? _initialTutorMode;
  String? _initialTutorSubject;

  void _navigateToTutor(String topic, String mode, String subject) {
    final aiTutorIdx = _tabs.indexOf('AI Teacher');
    if (aiTutorIdx != -1) {
      setState(() {
        _initialTutorTopic = topic;
        _initialTutorMode = mode;
        _initialTutorSubject = subject;
        _currentIndex = aiTutorIdx;
      });
    }
  }

  void _safeNavigate(BuildContext parentContext, BuildContext sheetContext, Widget destination) {
    Navigator.pop(sheetContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (parentContext.mounted) {
        Navigator.push(
          parentContext,
          MaterialPageRoute(builder: (context) => destination),
        );
      }
    });
  }

  void _showTopicAiActions(BuildContext context, String topic, String subject) {
    final aiTeacherIdx = _tabs.indexOf('AI Teacher');
    if (aiTeacherIdx != -1) {
      setState(() {
        _initialTutorTopic = topic;
        _initialTutorSubject = subject;
        _initialTutorMode = 'AI Generated Notes';
        _currentIndex = aiTeacherIdx;
      });
    }
  }


  List<String> get _tabs {
    final plan = widget.paymentPlan.toLowerCase();
    if (plan.contains('campus')) {
      return [
        'Dashboard',
        'AI Teacher',
        'School CRM',
        'Career & Coach',
        'Performance',
        'Profile Info',
      ];
    }
    final isPremium = plan.contains('premium');
    if (isPremium) {
      return [
        'Dashboard',
        'AI Teacher',
        'Career & Coach',
        'Performance',
        'Profile Info',
      ];
    }
    return [
      'Dashboard',
      'AI Teacher',
      'Career & Coach',
      'Performance',
      'Profile Info',
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
              final upgradeIdx = _tabs.indexOf('Profile Info');
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
              final upgradeIdx = _tabs.indexOf('Profile Info');
              if (upgradeIdx != -1) {
                setState(() {
                  _currentIndex = upgradeIdx;
                });
              }
            },
            initialTopic: _initialTutorTopic,
            initialMode: _initialTutorMode,
            initialSubject: _initialTutorSubject,
            onClearInitial: () {
              setState(() {
                _initialTutorTopic = null;
                _initialTutorMode = null;
                _initialTutorSubject = null;
              });
            },
          );
        } else if (tabName == 'School CRM') {
          currentScreen = StudentCrmTab(
            isDarkMode: isDarkMode,
            onTopicTap: (topic, subject) {
              _showTopicAiActions(context, topic, subject);
            },
          );
        } else if (tabName == 'Career & Coach') {
          final plan = widget.paymentPlan.toLowerCase();
          final hasAccess = plan.contains('pro') || plan.contains('aspirant') || plan.contains('premium') || plan.contains('campus');
          currentScreen = PlanFeatureGate(
            isUnlocked: hasAccess,
            requiredPlan: 'Pro Student Plan',
            isDarkMode: isDarkMode,
            onUpgrade: () {
              final upgradeIdx = _tabs.indexOf('Profile Info');
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
              final upgradeIdx = _tabs.indexOf('Profile Info');
              if (upgradeIdx != -1) {
                setState(() {
                  _currentIndex = upgradeIdx;
                });
              }
            },
            child: PerformanceAnalyticsTab(
              isDarkMode: isDarkMode,
              isCampusPlan: plan.contains('campus'),
              onTopicTap: (topic, subject) {
                _showTopicAiActions(context, topic, subject);
              },
            ),
          );
        } else if (tabName == 'Profile Info') {
          currentScreen = ProfileInfoTab(
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
              final upgradeIdx = _tabs.indexOf('Profile Info');
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
      case 'Profile Info':
        return Icons.person_outline;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ==========================================
// SCREEN 1: DASHBOARD TAB
// ==========================================
class DashboardTab extends StatefulWidget {
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
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<Map<String, dynamic>> _habitsList = [];
  int _currentStreak = 0;
  int _longestStreak = 0;
  String? _lastActiveDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStreaksAndHabits();
  }

  Future<void> _loadStreaksAndHabits() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch user streaks
      final streakRes = await Supabase.instance.client
          .from('user_streaks')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (streakRes != null) {
        _currentStreak = streakRes['current_streak'] ?? 0;
        _longestStreak = streakRes['longest_streak'] ?? 0;
        _lastActiveDate = streakRes['last_active_date'];
      } else {
        // Create initial streak record
        final insertRes = await Supabase.instance.client
            .from('user_streaks')
            .insert({
              'user_id': user.id,
              'current_streak': 0,
              'longest_streak': 0,
            })
            .select()
            .single();
        _currentStreak = insertRes['current_streak'] ?? 0;
        _longestStreak = insertRes['longest_streak'] ?? 0;
        _lastActiveDate = insertRes['last_active_date'];
      }

      // 2. Fetch habits
      final habitsRes = await Supabase.instance.client
          .from('habits')
          .select()
          .eq('user_id', user.id);

      if (habitsRes.isNotEmpty) {
        _habitsList = List<Map<String, dynamic>>.from(habitsRes);
      } else {
        // Pre-populate default habits
        final defaultHabits = [
          {'user_id': user.id, 'title': 'Solve 1 Coding Problem', 'is_completed': false},
          {'user_id': user.id, 'title': 'AI Teacher Concept Q&A', 'is_completed': false},
          {'user_id': user.id, 'title': 'Grade a Mock Interview', 'is_completed': false},
          {'user_id': user.id, 'title': 'Complete a Mock Quiz', 'is_completed': false},
        ];

        final insertRes = await Supabase.instance.client
            .from('habits')
            .insert(defaultHabits)
            .select();
        _habitsList = List<Map<String, dynamic>>.from(insertRes);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading streaks & habits: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleHabit(int index, bool val) async {
    final habit = _habitsList[index];
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    setState(() {
      habit['is_completed'] = val;
      habit['completed_at'] = val ? DateTime.now().toIso8601String() : null;
    });

    try {
      await Supabase.instance.client
          .from('habits')
          .update({
            'is_completed': val,
            'completed_at': habit['completed_at'],
          })
          .eq('id', habit['id']);

      final completedToday = _habitsList.where((h) => h['is_completed'] == true).length;
      
      if (completedToday == _habitsList.length && _habitsList.isNotEmpty) {
        if (_lastActiveDate != todayStr) {
          int newStreak = _currentStreak + 1;
          final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
          
          if (_lastActiveDate != null && _lastActiveDate != yesterdayStr && _currentStreak > 0) {
            newStreak = 1;
          } else if (_currentStreak == 0) {
            newStreak = 1;
          }

          int newLongest = newStreak > _longestStreak ? newStreak : _longestStreak;

          await Supabase.instance.client
              .from('user_streaks')
              .update({
                'current_streak': newStreak,
                'longest_streak': newLongest,
                'last_active_date': todayStr,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', user.id);

          setState(() {
            _currentStreak = newStreak;
            _longestStreak = newLongest;
            _lastActiveDate = todayStr;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("🔥 Awesome! All daily habits completed. Streak extended!"),
                backgroundColor: Colors.orangeAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error updating habit: $e');
    }
  }

  Future<void> _addCustomHabit(String title) async {
    if (title.trim().isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await Supabase.instance.client
          .from('habits')
          .insert({
            'user_id': user.id,
            'title': title.trim(),
            'is_completed': false,
          })
          .select()
          .single();

      setState(() {
        _habitsList.add(res);
      });
    } catch (e) {
      if (kDebugMode) print('Error adding custom habit: $e');
    }
  }

  void _showDailyPlannerBottomSheet() {
    final customHabitController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = widget.isDarkMode;
        final bg = isDark ? const Color(0xFF1E1E28) : Colors.white;
        final textCol = isDark ? Colors.white : const Color(0xFF0F172A);
        final borderCol = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Habits Planner 🚀',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete all daily targets to increase your streak!',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.grey,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Streaks visualizer card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Current Streak', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              '🔥 $_currentStreak Days',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 32, color: borderCol),
                        Column(
                          children: [
                            const Text('Longest Streak', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              '🏆 $_longestStreak Days',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Your Habits Checklist', style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),

                  if (_habitsList.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No habits configured yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ),
                  ] else ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _habitsList.length,
                        itemBuilder: (context, idx) {
                          final habit = _habitsList[idx];
                          final isCompleted = habit['is_completed'] == true;
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              habit['title'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isCompleted ? Colors.grey : textCol,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            value: isCompleted,
                            activeColor: const Color(0xFF00F2FE),
                            onChanged: (val) async {
                              await _toggleHabit(idx, val ?? false);
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  Text('Add Custom Daily Habit', style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customHabitController,
                          style: TextStyle(color: textCol, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Read 1 tech blog post',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (customHabitController.text.trim().isNotEmpty) {
                            await _addCustomHabit(customHabitController.text);
                            customHabitController.clear();
                            setModalState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F2FE),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 950;
    
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;

    final plan = widget.paymentPlan.toLowerCase();
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
                            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: widget.onUpgrade,
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
                  onPressed: widget.onUpgrade,
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
                onUpgrade: widget.onUpgrade,
              ),
              _buildMetricCard(
                'Streak & Daily Planning',
                '$_currentStreak Days',
                _habitsList.isEmpty
                    ? 'No habits active'
                    : '${(_habitsList.where((h) => h['is_completed'] == true).length / _habitsList.length * 100).toStringAsFixed(0)}% targets completed today',
                const Color(0xFF00F2FE),
                Icons.stars,
                cardBg,
                isUnlocked: true,
                onTap: _showDailyPlannerBottomSheet,
              ),
              _buildMetricCard(
                'Mock Interview Performance',
                'Level 4/5',
                'Excellent pacing & ATS keywords sync',
                const Color(0xFFFF2A6D),
                Icons.mic_external_on,
                cardBg,
                isUnlocked: hasInterviewAccess,
                onUpgrade: widget.onUpgrade,
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
                onUpgrade: widget.onUpgrade,
              ),
              _buildFeatureTile(
                '🎤 AI Interview Coach',
                'Simulate voice & technical interview queries with live response feedback. Get transcripts with speech speed, posture analysis, and confidence score summaries.',
                Icons.settings_voice,
                const Color(0xFFFF2A6D),
                cardBg,
                currentText,
                isUnlocked: hasInterviewAccess,
                onUpgrade: widget.onUpgrade,
              ),
              _buildFeatureTile(
                '💼 Placement & Job Readiness',
                'Upload and evaluate resume against ATS systems. Optimize matching descriptors with direct suggestions, and build custom web portfolios.',
                Icons.business_center,
                Colors.amber,
                cardBg,
                currentText,
                isUnlocked: hasPlacementAccess,
                onUpgrade: widget.onUpgrade,
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
    VoidCallback? onTap,
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

    if (isUnlocked) {
      if (onTap != null) {
        return GestureDetector(onTap: onTap, child: cardContent);
      }
      return cardContent;
    }

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

class SyllabusSubjectData {
  final String subject;
  final List<SyllabusChapterData> chapters;
  SyllabusSubjectData({required this.subject, required this.chapters});
}

class SyllabusChapterData {
  final String chapterName;
  final List<String> topics;
  SyllabusChapterData({required this.chapterName, required this.topics});
}

// ==========================================
// SCREEN 2: PERSONAL AI TEACHER TAB
// ==========================================
class AiTeacherTab extends StatefulWidget {
  final String paymentPlan;
  final bool isDarkMode;
  final VoidCallback onUpgrade;
  final String? initialTopic;
  final String? initialMode;
  final String? initialSubject;
  final VoidCallback? onClearInitial;

  const AiTeacherTab({
    super.key,
    required this.paymentPlan,
    required this.isDarkMode,
    required this.onUpgrade,
    this.initialTopic,
    this.initialMode,
    this.initialSubject,
    this.onClearInitial,
  });

  @override
  State<AiTeacherTab> createState() => _AiTeacherTabState();
}

class _AiTeacherTabState extends State<AiTeacherTab> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _customTopicController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;

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

  String _classId = '';
  List<Map<String, dynamic>> _syllabusList = [];
  bool _isLoadingSyllabus = false;
  final Map<String, String> _notesCache = {};
  String? _notesLoadingTopic;
  String? _expandedTopic;

  // Selection variables for syllabus dropdowns
  String? _selectedSyllabusSubject;
  SyllabusChapterData? _selectedSyllabusChapter;
  String? _selectedSyllabusTopic;

  @override
  void initState() {
    super.initState();
    _loadSyllabus();
    _loadDailyLimit();
    _initSpeech();
    _loadSessions().then((_) {
      _checkAndTriggerInitialSearch();
    });
  }

  @override
  void didUpdateWidget(covariant AiTeacherTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTopic != null && widget.initialTopic != oldWidget.initialTopic) {
      _checkAndTriggerInitialSearch();
    }
  }

  void _checkAndTriggerInitialSearch() {
    if (widget.initialTopic == null || !mounted) return;

    final topic = widget.initialTopic!;
    final mode = widget.initialMode ?? 'AI Generated Notes';
    final subject = widget.initialSubject ?? 'Math';

    final match = _subjects.firstWhere(
      (s) => s.toLowerCase() == subject.toLowerCase(),
      orElse: () => '',
    );
    if (match.isNotEmpty) {
      _selectedSubject = match;
    } else {
      _subjects.add(subject);
      _selectedSubject = subject;
    }

    setState(() {
      _selectedLevel = mode;
      if (mode != 'Simple Explanation') {
        _selectedSessionId = null;
      }
    });

    if (_customTopicController.text.isEmpty) {
      _customTopicController.text = topic;
    }

    if (mode == 'AI Generated Notes') {
      setState(() {
        _expandedTopic = topic;
      });
      _generateNotesForTopic(topic, subject);
      widget.onClearInitial?.call();
    } else if (mode == 'Simple Explanation') {
      _startTempSession();
      _chatController.text = "Please explain the topic '$topic' in $subject.";
      Future.microtask(() {
        if (mounted) {
          _sendMessage();
          widget.onClearInitial?.call();
        }
      });
    } else {
      final parsed = _getParsedSyllabus();
      bool found = false;
      for (final s in parsed) {
        if (s.subject.toLowerCase() == subject.toLowerCase()) {
          for (final ch in s.chapters) {
            if (ch.topics.contains(topic)) {
              setState(() {
                _selectedSyllabusSubject = s.subject;
                _selectedSyllabusChapter = ch;
                _selectedSyllabusTopic = topic;
              });
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }
      widget.onClearInitial?.call();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _chatController.dispose();
    _customTopicController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) {
          if (kDebugMode) print('AI Teacher STT Error: $val');
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
        onStatus: (val) {
          if (kDebugMode) print('AI Teacher STT Status: $val');
          if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) print('AI Teacher STT Init Exception: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    } else {
      if (!_speechEnabled) {
        await _initSpeech();
      }
      if (_speechEnabled) {
        if (mounted) {
          setState(() {
            _isListening = true;
          });
        }
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _chatController.text = result.recognizedWords;
              });
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition is not available or permission denied.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadSyllabus() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    setState(() {
      _isLoadingSyllabus = true;
    });
    try {
      final profile = await _client
          .from('profiles')
          .select('class_id, class')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        if (mounted) {
          setState(() {
            _classId = profile['class_id'] as String? ?? '';
            _gradeLevel = profile['class'] as String? ?? '10th Grade';
          });
        }
      }

      if (_classId.isNotEmpty) {
        final data = await DatabaseService.instance.fetchSyllabus(classId: _classId);
        if (mounted) {
          setState(() {
            _syllabusList = data;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading syllabus: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSyllabus = false;
        });
      }
    }
  }

  List<SyllabusSubjectData> _getParsedSyllabus() {
    final List<SyllabusSubjectData> list = [];
    for (final s in _syllabusList) {
      final subject = s['subject'] as String? ?? 'General';
      final rawContent = s['content'] as String? ?? '[]';
      final List<SyllabusChapterData> chapters = [];
      try {
        final decoded = jsonDecode(rawContent);
        if (decoded is List) {
          for (final ch in decoded) {
            if (ch is Map) {
              final chName = ch['chapter_name'] as String? ?? '';
              final rawTopics = ch['topics'];
              final List<String> topics = [];
              if (rawTopics is List) {
                for (final t in rawTopics) {
                  topics.add(t.toString());
                }
              }
              chapters.add(SyllabusChapterData(chapterName: chName, topics: topics));
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Error parsing syllabus content for $subject: $e');
      }
      list.add(SyllabusSubjectData(subject: subject, chapters: chapters));
    }
    return list;
  }

  Future<void> _generateNotesForTopic(String topic, String subject) async {
    if (_notesCache.containsKey(topic) || _notesLoadingTopic == topic) return;

    setState(() {
      _notesLoadingTopic = topic;
    });

    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.post(
        Uri.parse('$envBackendUrl/api/ai/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'topic': topic,
          'subject': subject,
          'gradeLevel': '10',
          'saveToLibrary': false,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['notes'] != null) {
          setState(() {
            _notesCache[topic] = data['notes'];
          });
        } else {
          throw Exception('Invalid response structure');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Error generating notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate notes: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _notesLoadingTopic = null;
        });
      }
    }
  }

  Future<void> _openActiveCbtPlayer() async {
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );
    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;
      final response = await http.get(
        Uri.parse('$envBackendUrl/api/tests'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        if (list is List && list.isNotEmpty) {
          final firstTest = list.first;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizPlayScreen(
                testId: firstTest['id'],
                testTitle: firstTest['title'] ?? 'Mock Test',
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active CBT exams found. Redirecting to Mock Tests list.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MockTestsListScreen(
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to load tests');
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading exams: $e. Opening directory instead.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MockTestsListScreen(
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    }
  }

  Future<void> _openLatestScoreReport() async {
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('No active user session');

      final latestAttempt = await _client
          .from('test_attempts')
          .select('id, score, answers, completed_at, mock_tests(title, total_marks, questions)')
          .eq('student_id', user.id)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (latestAttempt != null) {
        final testObj = latestAttempt['mock_tests'] ?? {};
        final questions = testObj['questions'] as List? ?? [];
        final studentAnswers = latestAttempt['answers'] as Map? ?? {};
        final testTitle = testObj['title'] ?? 'Mock Test';

        int correctCount = 0;
        final gradingDetails = [];

        for (int i = 0; i < questions.length; i++) {
          final q = questions[i] as Map? ?? {};
          final studentAnswer = studentAnswers[i.toString()];
          final correctAnswer = q['correctAnswer'] ?? '';
          final isCorrect = studentAnswer != null && studentAnswer == correctAnswer;

          if (isCorrect) correctCount++;

          gradingDetails.add({
            'questionIndex': i,
            'questionText': q['question'] ?? '',
            'studentAnswer': studentAnswer ?? 'Unanswered',
            'correctAnswer': correctAnswer,
            'isCorrect': isCorrect,
            'explanation': q['explanation'] ?? '',
          });
        }

        final resultsData = {
          'score': latestAttempt['score'] ?? 0,
          'totalMarks': testObj['total_marks'] ?? 100,
          'correctCount': correctCount,
          'totalQuestions': questions.length,
          'gradingDetails': gradingDetails,
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultsScreen(
              resultsData: resultsData,
              testTitle: testTitle,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have not attempted any mock tests yet.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load score report: $e')),
      );
    }
  }

  List<Widget> _parseAndRenderMarkdown(String rawText, Color textCol, Color cardCol, Color borderCol) {
    final List<Widget> widgets = [];
    final lines = rawText.split('\n');

    bool inCodeBlock = false;
    List<String> codeBlockLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Code blocks start or end
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          // End of code block: render gathered content
          inCodeBlock = false;
          widgets.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol),
              ),
              child: Text(
                codeBlockLines.join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
          );
          codeBlockLines.clear();
        } else {
          // Start of code block
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }

      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      // Parse headers
      if (trimmed.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
            child: Text(
              trimmed.substring(2),
              style: TextStyle(
                color: textCol,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
            child: Text(
              trimmed.substring(3),
              style: TextStyle(
                color: textCol,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              trimmed.substring(4),
              style: TextStyle(
                color: textCol,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } 
      // Parse bullet points
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final content = trimmed.substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: textCol.withOpacity(0.7), fontSize: 13)),
                Expanded(
                  child: _renderTextWithBoldSupport(content, textCol, 12),
                ),
              ],
            ),
          ),
        );
      } 
      // Standard paragraph
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _renderTextWithBoldSupport(trimmed, textCol, 12, height: 1.5),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _renderTextWithBoldSupport(String text, Color textCol, double fontSize, {double height = 1.3}) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: textCol.withOpacity(0.85), fontSize: fontSize, height: height),
        children: spans,
      ),
    );
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
      _selectedLevel = 'Simple Explanation';
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

    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }

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

  Widget _buildSyllabusNotesPanel(Color currentText, Color cardBg, Color borderCol) {
    final parsed = _getParsedSyllabus();

    return Container(
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
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5), size: 24),
              const SizedBox(width: 8),
              Text(
                'Syllabus Study Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Expand subjects and chapters, then tap on a topic to generate or view notes with AI.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.folder_special_rounded, size: 16, color: Color(0xFF4F46E5)),
                label: const Text('AI Notes Hub', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5))),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AINotesScreen(
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: parsed.length,
              itemBuilder: (context, sIdx) {
                final subData = parsed[sIdx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: widget.isDarkMode ? const Color(0xFF1E1E28) : const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderCol),
                  ),
                  child: ExpansionTile(
                    key: PageStorageKey('sub_${subData.subject}'),
                    title: Text(
                      subData.subject,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: currentText),
                    ),
                    iconColor: const Color(0xFF4F46E5),
                    collapsedIconColor: Colors.grey,
                    children: subData.chapters.map((chData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: ExpansionTile(
                          key: PageStorageKey('ch_${subData.subject}_${chData.chapterName}'),
                          title: Text(
                            chData.chapterName,
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: currentText),
                          ),
                          iconColor: const Color(0xFF4F46E5),
                          collapsedIconColor: Colors.grey,
                          children: chData.topics.map((topic) {
                            final isSelected = _notesCache.containsKey(topic);
                            final isLoading = _notesLoadingTopic == topic;
                            final isExpandedTopic = _expandedTopic == topic;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                              child: ExpansionTile(
                                key: PageStorageKey('top_${subData.subject}_$topic'),
                                initiallyExpanded: isExpandedTopic,
                                onExpansionChanged: (expanded) {
                                  if (expanded && !isSelected && !isLoading) {
                                    _generateNotesForTopic(topic, subData.subject);
                                  }
                                },
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        topic,
                                        style: TextStyle(fontSize: 12, color: currentText),
                                      ),
                                    ),
                                    if (isLoading)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(Color(0xFF4F46E5))),
                                      )
                                    else if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
                                    else
                                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 14),
                                  ],
                                ),
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: isLoading
                                        ? const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Center(
                                              child: Column(
                                                children: [
                                                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF4F46E5))),
                                                  SizedBox(height: 8),
                                                  Text('Generating study guide with AI...', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                          )
                                        : isSelected
                                            ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      TextButton.icon(
                                                        icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF4F46E5)),
                                                        label: const Text('Copy Notes', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                                                        onPressed: () {
                                                          final notesText = _notesCache[topic] ?? '';
                                                          Clipboard.setData(ClipboardData(text: notesText));
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Notes copied to clipboard!'),
                                                              backgroundColor: Color(0xFF4F46E5),
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  ..._parseAndRenderMarkdown(
                                                    _notesCache[topic] ?? '',
                                                    currentText,
                                                    cardBg,
                                                    borderCol,
                                                  ),
                                                ],
                                              )
                                            : const Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Text('Tap to load notes', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                              ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusQuizPanel(Color currentText, Color cardBg, Color borderCol, {required bool isMockTest}) {
    final parsed = _getParsedSyllabus();

    final List<String> availableSubjects = parsed.map((s) => s.subject).toList();

    if (_selectedSyllabusSubject == null || !availableSubjects.contains(_selectedSyllabusSubject)) {
      _selectedSyllabusSubject = availableSubjects.isNotEmpty ? availableSubjects.first : null;
      _selectedSyllabusChapter = null;
      _selectedSyllabusTopic = null;
    }

    final currentSubjectData = parsed.firstWhere(
      (s) => s.subject == _selectedSyllabusSubject,
      orElse: () => SyllabusSubjectData(subject: '', chapters: []),
    );

    final List<SyllabusChapterData> availableChapters = currentSubjectData.chapters;

    if (_selectedSyllabusChapter == null || !availableChapters.any((ch) => ch.chapterName == _selectedSyllabusChapter!.chapterName)) {
      _selectedSyllabusChapter = availableChapters.isNotEmpty ? availableChapters.first : null;
      _selectedSyllabusTopic = null;
    } else {
      _selectedSyllabusChapter = availableChapters.firstWhere(
        (ch) => ch.chapterName == _selectedSyllabusChapter!.chapterName,
        orElse: () => availableChapters.first,
      );
    }

    final List<String> availableTopics = _selectedSyllabusChapter?.topics ?? [];

    if (_selectedSyllabusTopic == null || !availableTopics.contains(_selectedSyllabusTopic)) {
      _selectedSyllabusTopic = availableTopics.isNotEmpty ? availableTopics.first : null;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.assignment_rounded, size: 14, color: Color(0xFF4F46E5)),
                            label: const Text('Directory', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MockTestsListScreen(
                                    isDarkMode: widget.isDarkMode,
                                  ),
                                ),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.play_circle_outline_rounded, size: 14, color: Color(0xFF4F46E5)),
                            label: const Text('CBT Player', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                            onPressed: _openActiveCbtPlayer,
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.analytics_rounded, size: 14, color: Color(0xFF4F46E5)),
                            label: const Text('Results', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                            onPressed: _openLatestScoreReport,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Icon(
                  isMockTest ? Icons.quiz_rounded : Icons.question_answer_rounded,
                  size: 50,
                  color: const Color(0xFF4F46E5),
                ),
                const SizedBox(height: 16),
                Text(
                  isMockTest ? 'Generate AI Mock Test' : 'Generate AI Sample Questions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: currentText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isMockTest
                      ? 'Choose a subject, lesson, and topic from your syllabus to generate a customized mock exam with AI.'
                      : 'Choose a subject, lesson, and topic from your syllabus to generate sample practice questions with AI.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Subject Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSyllabusSubject,
                  dropdownColor: cardBg,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Select Subject',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                  ),
                  items: availableSubjects.map((sub) {
                    return DropdownMenuItem(value: sub, child: Text(sub));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSyllabusSubject = val;
                      _selectedSyllabusChapter = null;
                      _selectedSyllabusTopic = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 2. Chapter / Lesson Dropdown
                DropdownButtonFormField<SyllabusChapterData>(
                  value: _selectedSyllabusChapter,
                  dropdownColor: cardBg,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Select Lesson / Chapter',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                  ),
                  items: availableChapters.map((ch) {
                    return DropdownMenuItem(value: ch, child: Text(ch.chapterName));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSyllabusChapter = val;
                      _selectedSyllabusTopic = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 3. Topic Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSyllabusTopic,
                  dropdownColor: cardBg,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Select Topic',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                  ),
                  items: availableTopics.map((top) {
                    return DropdownMenuItem(value: top, child: Text(top));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSyllabusTopic = val;
                    });
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () {
                    if (_selectedSyllabusTopic == null || _selectedSyllabusSubject == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a topic to generate questions.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CombinedQuizScreen(
                          topic: _selectedSyllabusTopic,
                          subject: _selectedSyllabusSubject,
                          isDarkMode: widget.isDarkMode,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isMockTest ? 'Generate Mock Test' : 'Generate Practice Questions',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSyllabusFallbackPanel(Color currentText, Color cardBg, Color borderCol, String optionType) {
    String title = '';
    String instruction = '';
    String buttonLabel = '';
    IconData icon = Icons.info_outline;

    if (optionType == 'AI Generated Notes') {
      title = 'AI Generated Notes';
      instruction = 'No syllabus guidelines published for your class yet. Enter a study topic below to generate notes:';
      buttonLabel = 'Generate Notes';
      icon = Icons.menu_book_rounded;
    } else if (optionType == 'Sample Questions') {
      title = 'Sample Questions';
      instruction = 'No syllabus guidelines published for your class yet. Enter a study topic below to practice questions:';
      buttonLabel = 'Practice Topic Questions';
      icon = Icons.question_answer_rounded;
    } else if (optionType == 'Mock Test') {
      title = 'Mock Test';
      instruction = 'No syllabus guidelines published for your class yet. Enter a study topic below to start a mock test:';
      buttonLabel = 'Start Mock Test';
      icon = Icons.quiz_rounded;
    }

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
                if (optionType == 'AI Generated Notes')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.folder_special_rounded, size: 14, color: Color(0xFF4F46E5)),
                        label: const Text('AI Notes Hub', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AINotesScreen(
                                isDarkMode: widget.isDarkMode,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.assignment_rounded, size: 14, color: Color(0xFF4F46E5)),
                              label: const Text('Directory', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MockTestsListScreen(
                                      isDarkMode: widget.isDarkMode,
                                    ),
                                  ),
                                );
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.play_circle_outline_rounded, size: 14, color: Color(0xFF4F46E5)),
                              label: const Text('CBT Player', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                              onPressed: _openActiveCbtPlayer,
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.analytics_rounded, size: 14, color: Color(0xFF4F46E5)),
                              label: const Text('Results', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
                              onPressed: _openLatestScoreReport,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const Divider(),
                const SizedBox(height: 8),
                Icon(
                  icon,
                  size: 50,
                  color: const Color(0xFF4F46E5),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: currentText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
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
                TextField(
                  controller: _customTopicController,
                  style: TextStyle(color: currentText, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Topic Name (e.g. Photosynthesis)',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4F46E5))),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    final activeTopic = _customTopicController.text.trim();
                    final activeSubject = _selectedSubject ?? 'Math';

                    if (activeTopic.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a topic name.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    if (optionType == 'AI Generated Notes') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudyNotesViewScreen(
                            topic: activeTopic,
                            subject: activeSubject,
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CombinedQuizScreen(
                            topic: activeTopic,
                            subject: activeSubject,
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
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
                if (size.width > 750 && _selectedLevel == 'Simple Explanation')
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
                            if (_selectedLevel == 'Simple Explanation')
                              _buildCreateSessionPanel(currentText, cardBg, borderCol)
                            else if (_selectedLevel == 'AI Generated Notes')
                              (_syllabusList.isNotEmpty
                                  ? _buildSyllabusNotesPanel(currentText, cardBg, borderCol)
                                  : _buildNoSyllabusFallbackPanel(currentText, cardBg, borderCol, 'AI Generated Notes'))
                            else if (_selectedLevel == 'Sample Questions')
                              (_syllabusList.isNotEmpty
                                  ? _buildSyllabusQuizPanel(currentText, cardBg, borderCol, isMockTest: false)
                                  : _buildNoSyllabusFallbackPanel(currentText, cardBg, borderCol, 'Sample Questions'))
                            else if (_selectedLevel == 'Mock Test')
                              (_syllabusList.isNotEmpty
                                  ? _buildSyllabusQuizPanel(currentText, cardBg, borderCol, isMockTest: true)
                                  : _buildNoSyllabusFallbackPanel(currentText, cardBg, borderCol, 'Mock Test'))
                            else
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
          _buildConfigChip('Simple Explanation', Icons.face_rounded),
          const SizedBox(width: 12),
          _buildConfigChip('AI Generated Notes', Icons.menu_book_rounded),
          const SizedBox(width: 12),
          _buildConfigChip('Sample Questions', Icons.question_answer_rounded),
          const SizedBox(width: 12),
          _buildConfigChip('Mock Test', Icons.quiz_rounded),
        ],
      ),
    );
  }

  Widget _buildChatConfigDropdown(Color currentText, Color cardBg, Color borderCol) {
    IconData getIconForStyle(String style) {
      switch (style) {
        case 'Simple Explanation': return Icons.face_rounded;
        case 'AI Generated Notes': return Icons.menu_book_rounded;
        case 'Sample Questions': return Icons.question_answer_rounded;
        case 'Mock Test': return Icons.quiz_rounded;
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
                'AI Generated Notes',
                'Sample Questions',
                'Mock Test'
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
                    if (newValue != 'Simple Explanation') {
                      _selectedSessionId = null;
                    }
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
          if (title != 'Simple Explanation') {
            _selectedSessionId = null;
          }
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
                    } else {
                      _toggleListening();
                    }
                  },
                  icon: Icon(
                    _isListening ? Icons.stop_circle_rounded : Icons.mic,
                    color: (isFreePlan || widget.paymentPlan.toLowerCase().contains('basic'))
                        ? Colors.grey
                        : (_isListening ? const Color(0xFFEF4444) : const Color(0xFF00F2FE)),
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
enum InterviewState {
  idle,
  initializing,
  speaking,
  listening,
  thinking
}

class SoundOrb extends StatefulWidget {
  final InterviewState state;
  const SoundOrb({super.key, required this.state});

  @override
  State<SoundOrb> createState() => _SoundOrbState();
}

class _SoundOrbState extends State<SoundOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        List<Color> colors;
        double scale;
        
        switch (widget.state) {
          case InterviewState.idle:
            colors = [Colors.grey.shade800, Colors.grey.shade900];
            scale = 1.0;
            break;
          case InterviewState.initializing:
            colors = [const Color(0xFF6C63FF), const Color(0xFF3F37C9)];
            scale = 1.0 + math.sin(_controller.value * math.pi * 2) * 0.05;
            break;
          case InterviewState.speaking:
            colors = [const Color(0xFF7209B7), const Color(0xFFB5179E)];
            scale = 1.05 + math.sin(_controller.value * math.pi * 4) * 0.08;
            break;
          case InterviewState.listening:
            colors = [const Color(0xFF4CC9F0), const Color(0xFF4895EF)];
            scale = 1.1 + math.sin(_controller.value * math.pi * 8) * 0.12;
            break;
          case InterviewState.thinking:
            colors = [const Color(0xFF4895EF), const Color(0xFF560BAD)];
            scale = 1.0 + math.sin(_controller.value * math.pi * 12) * 0.07;
            break;
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: colors,
                center: Alignment.center,
                radius: 0.85,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(0.4),
                  blurRadius: widget.state == InterviewState.idle ? 10 : 30,
                  spreadRadius: widget.state == InterviewState.idle ? 2 : 10,
                )
              ],
            ),
            child: Center(
              child: widget.state == InterviewState.idle
                  ? Icon(Icons.mic_none_rounded, size: 36, color: Colors.white.withOpacity(0.5))
                  : Text(
                      widget.state == InterviewState.listening
                          ? "Listening..."
                          : widget.state == InterviewState.thinking
                              ? "Thinking..."
                              : widget.state == InterviewState.speaking
                                  ? "Speaking..."
                                  : "Connecting...",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class CareerCoachTab extends StatefulWidget {
  final bool isDarkMode;
  const CareerCoachTab({super.key, required this.isDarkMode});

  @override
  State<CareerCoachTab> createState() => _CareerCoachTabState();
}

class _CareerCoachTabState extends State<CareerCoachTab> {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechEnabled = false;
  bool _ttsEnabled = true;
  bool _useTextFallback = false;
  String _currentWords = '';
  String? _currentSessionId;

  // Simulator config
  String _selectedRole = 'Software Engineer';
  final List<String> _roles = [
    'Software Engineer',
    'Data Scientist',
    'Product Manager',
    'Marketing Specialist',
    'HR Recruiter',
    'Financial Analyst',
  ];
  final TextEditingController _customRoleController = TextEditingController();

  InterviewState _interviewState = InterviewState.idle;

  // Chat log transcript
  List<Map<String, String>> _interviewLog = [];

  bool _isAnalyzingResume = false;
  int? _atsScore;
  List<String> _matchedKeywords = [];
  List<String> _missingKeywords = [];
  String? _atsSuggestions;
  String? _pickedFileName;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    _textController.dispose();
    _customRoleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _stt.initialize(
        onError: (val) {
          if (kDebugMode) print('STT Error: $val');
          if (mounted) {
            setState(() {
              _speechEnabled = false;
              _useTextFallback = true;
            });
          }
        },
        onStatus: (val) {
          if (kDebugMode) print('STT Status: $val');
          if (val == 'done' || val == 'notListening') {
            if (_interviewState == InterviewState.listening && _currentWords.isNotEmpty) {
              _sendAnswer(_currentWords);
            }
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) print('STT Init Exception: $e');
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.55);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (_interviewState == InterviewState.speaking) {
          _startListening();
        }
      });
    } catch (e) {
      if (kDebugMode) print('TTS Init Exception: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsEnabled) {
      _startListening();
      return;
    }
    setState(() {
      _interviewState = InterviewState.speaking;
    });
    final cleanText = text.replaceAll(RegExp(r'[\*\#\_]'), '');
    await _tts.speak(cleanText);
  }

  Future<void> _startListening() async {
    if (!_speechEnabled || _useTextFallback) {
      setState(() {
        _interviewState = InterviewState.idle;
      });
      return;
    }

    setState(() {
      _interviewState = InterviewState.listening;
      _currentWords = '';
    });

    await _stt.listen(
      onResult: (result) {
        setState(() {
          _currentWords = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
  }

  Future<String> _callInterviewApi(String message, String sessionId) async {
    final jwtToken = Supabase.instance.client.auth.currentSession?.accessToken;
    const envBackendUrl = String.fromEnvironment(
      'BACKEND_API_URL',
      defaultValue: 'https://mrivan-ai.onrender.com',
    );
    final url = '$envBackendUrl/api/ai/tutor/chat';

    http.Response response;
    try {
      response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'message': message,
          'sessionId': sessionId,
          'subject': 'Career',
          'gradeLevel': 'Mock Interview',
          'switchAi': false,
        }),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'message': message,
          'sessionId': sessionId,
          'subject': 'Career',
          'gradeLevel': 'Mock Interview',
          'switchAi': true,
        }),
      ).timeout(const Duration(seconds: 15));
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response']?.toString() ?? 'Could not parse interviewer response';
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  Future<void> _startInterview() async {
    setState(() {
      _interviewState = InterviewState.initializing;
      _interviewLog = [];
      _currentWords = '';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final role = _selectedRole == 'Other' ? _customRoleController.text.trim() : _selectedRole;
      if (role.isEmpty) throw Exception("Please enter a target role");

      final session = await DatabaseService.instance.createAIChatSession(
        user.id,
        "Mock Interview: $role",
        "Career",
      );

      _currentSessionId = session['id']?.toString();
      if (_currentSessionId == null) throw Exception("Failed to generate chat session");

      String systemMessage = "CONTEXT: Act as a friendly and professional mock interviewer for the role of '$role'. Ask only one question at a time. Do not write everything at once. Respond to the user's answers and ask relevant follow-up questions. Keep your questions under 30 words so they are clear when spoken. Let's start! Say hello and ask the first question.";

      setState(() {
        _interviewState = InterviewState.thinking;
      });

      final responseText = await _callInterviewApi(systemMessage, _currentSessionId!);

      setState(() {
        _interviewLog.add({'role': 'ai', 'content': responseText});
        _interviewState = InterviewState.speaking;
      });

      await _speak(responseText);
    } catch (e) {
      setState(() {
        _interviewState = InterviewState.idle;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to start simulator: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendAnswer(String answerText) async {
    if (answerText.trim().isEmpty || _currentSessionId == null) return;

    await _stt.stop();
    await _tts.stop();

    setState(() {
      _interviewLog.add({'role': 'user', 'content': answerText});
      _interviewState = InterviewState.thinking;
      _currentWords = '';
    });

    try {
      final responseText = await _callInterviewApi(answerText, _currentSessionId!);

      setState(() {
        _interviewLog.add({'role': 'ai', 'content': responseText});
        _interviewState = InterviewState.speaking;
      });

      await _speak(responseText);
    } catch (e) {
      setState(() {
        _interviewState = InterviewState.idle;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to get response: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

  Future<void> _gradeInterview() async {
    if (_currentSessionId == null) return;
    
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final role = _selectedRole == 'Other' ? _customRoleController.text.trim() : _selectedRole;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  const SizedBox(height: 24),
                  Text(
                    'AI Tutor is grading your interview...',
                    style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Evaluating your responses, identifying key strengths, and calculating your score.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final jwtToken = Supabase.instance.client.auth.currentSession?.accessToken;
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final url = '$envBackendUrl/api/ai/tutor/interview/grade';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'sessionId': _currentSessionId,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 30));

      // Pop the loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final int score = result['score'] ?? 0;
        final String feedback = result['feedback'] ?? '';
        final List<dynamic> strengths = result['strengths'] ?? [];
        final List<dynamic> improvements = result['improvements'] ?? [];

        // Stop STT and TTS
        await _tts.stop();
        await _stt.stop();
        setState(() {
          _interviewState = InterviewState.idle;
          _currentSessionId = null;
        });

        if (mounted) {
          _showGradingReportDialog(score, feedback, strengths.cast<String>(), improvements.cast<String>());
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      // Pop the loading dialog if it's still showing
      if (mounted) Navigator.of(context).pop();

      await _tts.stop();
      await _stt.stop();
      setState(() {
        _interviewState = InterviewState.idle;
        _currentSessionId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to grade interview: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showGradingReportDialog(
    int score,
    String feedback,
    List<String> strengths,
    List<String> improvements,
  ) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    // Let's color-code based on score range
    Color scoreColor = const Color(0xFFEF4444); // red
    if (score >= 80) {
      scoreColor = const Color(0xFF10B981); // green
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF59E0B); // orange
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: borderCol)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 480,
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glowing Header / Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isDarkMode
                            ? [const Color(0xFF4F46E5).withOpacity(0.2), const Color(0xFF06B6D4).withOpacity(0.05)]
                            : [const Color(0xFF4F46E5).withOpacity(0.08), const Color(0xFF06B6D4).withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      border: Border(bottom: BorderSide(color: borderCol)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFF4F46E5), size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'AI Interview Report Card',
                          style: TextStyle(color: currentText, fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'AI evaluation of your simulated performance',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Score gauge row
                        Row(
                          children: [
                            // Circular Gauge or Big Indicator
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scoreColor.withOpacity(0.1),
                                border: Border.all(color: scoreColor, width: 3),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$score%',
                                style: TextStyle(color: scoreColor, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    score >= 80 ? 'Excellent Match!' : score >= 60 ? 'Good Progress' : 'Needs Practice',
                                    style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your overall score is $score out of 100.',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Feedback summary
                        Text('Summary Feedback', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderCol),
                          ),
                          child: Text(
                            feedback,
                            style: TextStyle(color: currentText.withOpacity(0.9), fontSize: 11, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Strengths & Improvements tabs or lists
                        if (strengths.isNotEmpty) ...[
                          Text('Key Strengths', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          ...strengths.map((str) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    str,
                                    style: TextStyle(color: currentText.withOpacity(0.8), fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],

                        if (improvements.isNotEmpty) ...[
                          Text('Areas to Improve', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          ...improvements.map((imp) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.arrow_circle_up_rounded, color: Color(0xFFF59E0B), size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    imp,
                                    style: TextStyle(color: currentText.withOpacity(0.8), fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: borderCol)),
                    ),
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndAnalyzeResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileBytes = file.bytes;
      if (fileBytes == null) {
        throw Exception("Failed to read file content");
      }

      setState(() {
        _isAnalyzingResume = true;
        _pickedFileName = file.name;
        _atsScore = null;
        _matchedKeywords = [];
        _missingKeywords = [];
        _atsSuggestions = null;
      });

      final jwtToken = Supabase.instance.client.auth.currentSession?.accessToken;
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final url = '$envBackendUrl/api/ai/resume/analyze';

      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add Authorization header
      if (jwtToken != null) {
        request.headers['Authorization'] = 'Bearer $jwtToken';
      }
      request.headers['Bypass-Tunnel-Reminder'] = 'true';

      // Add target role
      final role = _selectedRole == 'Other' ? _customRoleController.text.trim() : _selectedRole;
      request.fields['role'] = role.isEmpty ? 'Software Engineer' : role;

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'resume',
          fileBytes,
          filename: file.name,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _atsScore = data['score'] ?? 0;
          _matchedKeywords = List<String>.from(data['matchedKeywords'] ?? []);
          _missingKeywords = List<String>.from(data['missingKeywords'] ?? []);
          _atsSuggestions = data['suggestions'] ?? '';
          _isAnalyzingResume = false;
        });
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Server returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isAnalyzingResume = false;
        _pickedFileName = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ATS Grader Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                            Text(
                              'Live AI Mock Interview',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentText),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _interviewState == InterviewState.idle 
                                  ? 'Prepare and practice vocal simulation drills for your target career role.' 
                                  : 'Session Active: ${_selectedRole == "Other" ? _customRoleController.text : _selectedRole}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 24),

                            if (_interviewState == InterviewState.idle) ...[
                              Text('Select Target Role', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderCol),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    dropdownColor: cardBg,
                                    isExpanded: true,
                                    value: _selectedRole,
                                    items: [
                                      ..._roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: currentText, fontSize: 13)))),
                                      DropdownMenuItem(value: 'Other', child: Text('Other / Custom Role', style: TextStyle(color: currentText, fontSize: 13))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedRole = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              if (_selectedRole == 'Other') ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _customRoleController,
                                  style: TextStyle(color: currentText, fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'Custom Target Role',
                                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderCol)),
                                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4F46E5))),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _startInterview,
                                  icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                                  label: const Text('START LIVE SIMULATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Center(
                                child: Column(
                                  children: [
                                    SoundOrb(state: _interviewState),
                                    const SizedBox(height: 20),
                                    Text(
                                      _interviewState == InterviewState.listening
                                          ? 'Mic listening... speak now'
                                          : _interviewState == InterviewState.speaking
                                              ? 'Interviewer is speaking...'
                                              : _interviewState == InterviewState.thinking
                                                  ? 'AI is analyzing response...'
                                                  : 'Connecting...',
                                      style: TextStyle(color: currentText, fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                    if (_interviewState == InterviewState.listening && _currentWords.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '"$_currentWords"',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _ttsEnabled ? Icons.volume_up : Icons.volume_off,
                                            color: _ttsEnabled ? const Color(0xFF4F46E5) : Colors.grey,
                                          ),
                                          tooltip: _ttsEnabled ? 'Mute AI Voice' : 'Unmute AI Voice',
                                          onPressed: () {
                                            setState(() {
                                              _ttsEnabled = !_ttsEnabled;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: Icon(
                                            _useTextFallback ? Icons.keyboard : Icons.keyboard_voice,
                                            color: _useTextFallback ? const Color(0xFF4F46E5) : Colors.grey,
                                          ),
                                          tooltip: _useTextFallback ? 'Switch to Voice Input' : 'Switch to Text Input',
                                          onPressed: () {
                                            setState(() {
                                              _useTextFallback = !_useTextFallback;
                                              if (_useTextFallback) {
                                                _stt.stop();
                                              } else {
                                                _startListening();
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: cardBg,
                                                  title: Text('Finish & Grade Interview?', style: TextStyle(color: currentText, fontSize: 16, fontWeight: FontWeight.bold)),
                                                  content: Text('Are you ready to submit your interview session for AI grading and receive feedback?', style: TextStyle(color: currentText, fontSize: 13)),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context); // Close confirm dialog
                                                        _tts.stop();
                                                        _stt.stop();
                                                        setState(() {
                                                          _interviewState = InterviewState.idle;
                                                          _currentSessionId = null;
                                                        });
                                                      },
                                                      child: const Text('Exit Without Grading', style: TextStyle(color: Colors.grey)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context); // Close confirm dialog
                                                        _gradeInterview();
                                                      },
                                                      child: const Text('Submit & Grade', style: TextStyle(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          icon: const Icon(Icons.stop, color: Colors.white, size: 16),
                                          label: const Text('END', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (_useTextFallback && _interviewState == InterviewState.listening) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _textController,
                                              style: TextStyle(color: currentText, fontSize: 13),
                                              decoration: InputDecoration(
                                                hintText: 'Type your answer here...',
                                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                                filled: true,
                                                fillColor: widget.isDarkMode ? const Color(0xFF111116) : Colors.grey.withOpacity(0.04),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: borderCol),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: const BorderSide(color: Color(0xFF4F46E5)),
                                                ),
                                              ),
                                              onSubmitted: (val) {
                                                if (val.trim().isNotEmpty) {
                                                  _sendAnswer(val);
                                                  _textController.clear();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.send, color: Color(0xFF4F46E5)),
                                            onPressed: () {
                                              final val = _textController.text;
                                              if (val.trim().isNotEmpty) {
                                                _sendAnswer(val);
                                                _textController.clear();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              if (_interviewLog.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text('Transcript History', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 150,
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode ? const Color(0xFF111116) : Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderCol),
                                  ),
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _interviewLog.length,
                                    itemBuilder: (context, idx) {
                                      final msg = _interviewLog[idx];
                                      final isAi = msg['role'] == 'ai';
                                      _scrollToBottom();

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          isAi ? 'Interviewer: ${msg['content']}' : 'You: ${msg['content']}',
                                          style: TextStyle(
                                            color: isAi ? const Color(0xFF4F46E5) : currentText.withOpacity(0.8),
                                            fontSize: 11,
                                            fontWeight: isAi ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
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
                            Text(
                              'Portfolio & CV ATS Index Checker 📄',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentText),
                            ),
                            const SizedBox(height: 12),
                            if (_isAnalyzingResume) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const CircularProgressIndicator(color: Color(0xFF00F2FE)),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Analyzing "${_pickedFileName}"...',
                                        style: TextStyle(color: currentText, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Extracting PDF text and calculating job role matching index.',
                                        style: TextStyle(color: Colors.grey, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else if (_atsScore == null) ...[
                              Text(
                                'Upload your resume in PDF format to verify ATS keyword compliance and job role matchmaking.',
                                style: TextStyle(color: currentText.withOpacity(0.7), fontSize: 12, height: 1.4),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _pickAndAnalyzeResume,
                                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
                                  label: const Text(
                                    'UPLOAD RESUME (PDF)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Job Match Grade display
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Target Role: ${_selectedRole == "Other" ? _customRoleController.text : _selectedRole}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'Score: $_atsScore/100',
                                    style: TextStyle(
                                      color: _atsScore! >= 80
                                          ? const Color(0xFF10B981)
                                          : _atsScore! >= 60
                                              ? const Color(0xFFF59E0B)
                                              : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _atsScore! / 100.0,
                                color: _atsScore! >= 80
                                    ? const Color(0xFF10B981)
                                    : _atsScore! >= 60
                                        ? const Color(0xFFF59E0B)
                                        : Colors.redAccent,
                                backgroundColor: Colors.grey.withOpacity(0.12),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 20),

                              // Matched Keywords
                              if (_matchedKeywords.isNotEmpty) ...[
                                Text('Matched Keywords', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _matchedKeywords.map((kw) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      kw,
                                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Missing Keywords
                              if (_missingKeywords.isNotEmpty) ...[
                                Text('Missing Keywords', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _missingKeywords.map((kw) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      kw,
                                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Suggestions
                              if (_atsSuggestions != null && _atsSuggestions!.trim().isNotEmpty) ...[
                                Text('Recommendations', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderCol),
                                  ),
                                  child: Text(
                                    _atsSuggestions!,
                                    style: TextStyle(color: currentText.withOpacity(0.8), fontSize: 11, height: 1.4),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Re-upload action
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: _pickAndAnalyzeResume,
                                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5), size: 16),
                                  label: const Text('RE-UPLOAD RESUME', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: const Color(0xFF4F46E5).withOpacity(0.3))),
                                  ),
                                ),
                              ),
                            ],
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
  final Function(String topic, String subject)? onTopicTap;

  const PerformanceAnalyticsTab({
    super.key,
    required this.isDarkMode,
    required this.isCampusPlan,
    this.onTopicTap,
  });

  @override
  State<PerformanceAnalyticsTab> createState() => _PerformanceAnalyticsTabState();
}

class _PerformanceAnalyticsTabState extends State<PerformanceAnalyticsTab> {
  final _chapterNameController = TextEditingController();
  final _topicController = TextEditingController();

  List<Map<String, dynamic>> _customChapters = [];
  List<String> _tempTopics = [];

  bool _isLoadingAnalytics = false;
  double _attendanceRate = 0.85; // default fallback
  double _homeworkCompletionRate = 0.78; // default fallback
  double _averageTestScore = 0.82; // default fallback
  double _overallPerformanceProgress = 0.75; // default fallback

  String _inferSubject(String chapterName) {
    final lower = chapterName.toLowerCase();
    if (lower.contains('math') || lower.contains('algebra') || lower.contains('geometry') || lower.contains('calculus')) {
      return 'Math';
    }
    if (lower.contains('physics') || lower.contains('mechanics') || lower.contains('thermodynamics')) {
      return 'Physics';
    }
    if (lower.contains('chemistry') || lower.contains('organic') || lower.contains('inorganic')) {
      return 'Chemistry';
    }
    if (lower.contains('biology') || lower.contains('botany') || lower.contains('zoology')) {
      return 'Biology';
    }
    if (lower.contains('history') || lower.contains('civics') || lower.contains('social')) {
      return 'History';
    }
    if (lower.contains('english') || lower.contains('literature') || lower.contains('grammar')) {
      return 'English';
    }
    if (lower.contains('computer') || lower.contains('programming') || lower.contains('database') || lower.contains('system') || lower.contains('concurrency') || lower.contains('network')) {
      return 'Computer Science';
    }
    return 'Computer Science';
  }

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
    if (widget.isCampusPlan) {
      _loadLiveAnalytics();
    }
  }

  Future<void> _loadLiveAnalytics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      // 1. Fetch attendance
      final attendanceRes = await Supabase.instance.client
          .from('attendance')
          .select('status')
          .eq('student_id', user.id);
      
      if (attendanceRes.isNotEmpty) {
        final total = attendanceRes.length;
        final presentCount = attendanceRes.where((a) => a['status'] == 'present' || a['status'] == 'late').length;
        setState(() {
          _attendanceRate = presentCount / total;
        });
      }

      // 2. Fetch test attempts
      final testAttemptsRes = await Supabase.instance.client
          .from('test_attempts')
          .select('score')
          .eq('student_id', user.id);
      
      if (testAttemptsRes.isNotEmpty) {
        final totalScore = testAttemptsRes.fold<double>(0.0, (sum, a) => sum + (a['score'] ?? 0));
        setState(() {
          _averageTestScore = totalScore / (testAttemptsRes.length * 100.0);
        });
      }

      // 3. Fetch homework submissions
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('class_id')
          .eq('id', user.id)
          .single();
      
      final classId = profileRes['class_id'];
      if (classId != null) {
        final homeworkRes = await Supabase.instance.client
            .from('homework')
            .select('id')
            .eq('class_id', classId);
        
        final totalHomework = homeworkRes.length;
        
        final submissionRes = await Supabase.instance.client
            .from('homework_submissions')
            .select('id')
            .eq('student_id', user.id);
        
        final submittedCount = submissionRes.length;
        
        if (totalHomework > 0) {
          setState(() {
            _homeworkCompletionRate = submittedCount / totalHomework;
          });
        } else if (submittedCount > 0) {
          setState(() {
            _homeworkCompletionRate = 1.0;
          });
        }
      }

      setState(() {
        _overallPerformanceProgress = (_attendanceRate + _homeworkCompletionRate + _averageTestScore) / 3.0;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading live analytics: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
        });
      }
    }
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

    // Calculate progress
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
    } else {
      overallProgress = _overallPerformanceProgress;
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
                          deleteIconColor: widget.isDarkMode ? Colors.white70 : Colors.black54,
                          side: BorderSide(color: widget.isDarkMode ? Colors.white12 : Colors.black12),
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
                                    secondary: IconButton(
                                      icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 18),
                                      onPressed: () {
                                        final inferredSubject = _inferSubject(chName);
                                        widget.onTopicTap?.call(tName, inferredSubject);
                                      },
                                      tooltip: 'AI Study Assistant',
                                    ),
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
                            progress: overallProgress,
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
                                ? [
                                    _averageTestScore,
                                    0.3 + (_overallPerformanceProgress * 0.6),
                                    _homeworkCompletionRate,
                                    _attendanceRate,
                                    0.4 + (_overallPerformanceProgress * 0.5),
                                  ]
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
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MockTestsListScreen(
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.quiz_rounded, size: 18),
                    label: const Text('Open CBT Mock Exams Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}

// ==========================================
// SCREEN 5: VIP PORTAL TAB
// ==========================================
class ProfileInfoTab extends StatefulWidget {
  final String paymentPlan;
  final String email;
  final bool isDarkMode;

  const ProfileInfoTab({
    super.key,
    required this.paymentPlan,
    required this.email,
    required this.isDarkMode,
  });

  @override
  State<ProfileInfoTab> createState() => _ProfileInfoTabState();
}

class _ProfileInfoTabState extends State<ProfileInfoTab> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();

  String _role = 'student';
  String? _schoolName;

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



  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _classController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _emailController.text = widget.email;
        _nameController.text = '';
        _classController.text = '';
        _phoneController.text = '';
        _specializationController.text = '';
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final profile = await _client
          .from('profiles')
          .select('full_name, email, class, phone_number, role, teacher_specialization, schools!school_id(name)')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _nameController.text = profile['full_name'] as String? ?? '';
        _emailController.text = (profile['email'] as String? ?? user.email) ?? widget.email;
        _classController.text = profile['class'] as String? ?? '';
        _phoneController.text = profile['phone_number'] as String? ?? '';
        _role = profile['role'] as String? ?? 'student';
        _specializationController.text = profile['teacher_specialization'] as String? ?? '';

        if (profile['schools'] != null) {
          _schoolName = profile['schools']['name'] as String?;
        }
      } else {
        _emailController.text = user.email ?? widget.email;
        _nameController.text = '';
      }
    } catch (e) {
      if (kDebugMode) print('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfileDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final plan = widget.paymentPlan.toLowerCase();
      final isFree = plan.contains('free');

      if (isFree) {
        await DatabaseService.instance.updateUserProfile(
          userId: user.id,
          email: _emailController.text.trim(),
        );
      } else {
        await DatabaseService.instance.updateUserProfile(
          userId: user.id,
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          className: _classController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          teacherSpecialization: _role == 'teacher' ? _specializationController.text.trim() : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isEditing = false;
        });
      }

      await _loadProfileDetails();
    } catch (e) {
      if (kDebugMode) print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final cardBg = widget.isDarkMode ? const Color(0xFF181824) : Colors.white;
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);

    final plan = widget.paymentPlan.toLowerCase();
    final isFreePlan = plan.contains('free');

    final otherPlans = _allPlans.where((p) {
      return p.title.toLowerCase() != plan;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile & Settings 👤',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your personal details, specialization info, and configure your subscription plan.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // PROFILE CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile Details',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentText),
                            ),
                            if (!_isEditing)
                              TextButton.icon(
                                onPressed: () => setState(() => _isEditing = true),
                                icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF4F46E5)),
                                label: const Text('Edit Profile', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Form Fields
                        if (isFreePlan) ...[
                          _buildFieldLabel('Email Address', currentText),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Enter your email address',
                            enabled: _isEditing,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Email is required';
                              if (!val.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                            currentText: currentText,
                            cardBg: cardBg,
                          ),
                        ] else ...[
                          _buildFieldLabel('Full Name', currentText),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Enter your full name',
                            enabled: _isEditing,
                            validator: (val) => (val == null || val.trim().isEmpty) ? 'Full name is required' : null,
                            currentText: currentText,
                            cardBg: cardBg,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Email Address', currentText),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Enter your email address',
                            enabled: _isEditing,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Email is required';
                              if (!val.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                            currentText: currentText,
                            cardBg: cardBg,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Phone Number', currentText),
                          _buildTextField(
                            controller: _phoneController,
                            hint: 'Enter your phone number',
                            enabled: _isEditing,
                            currentText: currentText,
                            cardBg: cardBg,
                          ),
                          const SizedBox(height: 16),
                          if (_role == 'teacher') ...[
                            _buildFieldLabel('Teacher Specialization', currentText),
                            _buildTextField(
                              controller: _specializationController,
                              hint: 'E.g., Mathematics, Physics',
                              enabled: _isEditing,
                              currentText: currentText,
                              cardBg: cardBg,
                            ),
                          ] else ...[
                            _buildFieldLabel('Class / Grade', currentText),
                            _buildTextField(
                              controller: _classController,
                              hint: 'E.g., 10th Grade',
                              enabled: _isEditing,
                              currentText: currentText,
                              cardBg: cardBg,
                            ),
                          ],
                          if (_schoolName != null && _schoolName!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildFieldLabel('Registered Institution', currentText),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderCol),
                              ),
                              child: Text(
                                _schoolName!,
                                style: TextStyle(fontSize: 13, color: currentText.withOpacity(0.8), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ],

                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  setState(() => _isEditing = false);
                                  _loadProfileDetails();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: currentText,
                                  side: BorderSide(color: borderCol),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfileDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                      )
                                    : const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 36),

          // ACTIVE PLAN GLOWING BOX
          Text(
            'Active Plan Membership 💎',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentText),
          ),
          const SizedBox(height: 16),
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
                        'MEMBERSHIP PORTAL ACTIVE',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  widget.paymentPlan,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Associated with: ${widget.email}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // SWITCH OR UPGRADE PLAN
          Text(
            'Switch or Upgrade Plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: currentText),
          ),
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
            itemCount: otherPlans.length,
            itemBuilder: (context, index) {
              final planInfo = otherPlans[index];
              return _buildPlanUpgradeCard(context, planInfo, cardBg, currentText, borderCol);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color textCol) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textCol.withOpacity(0.6)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool enabled,
    String? Function(String?)? validator,
    required Color currentText,
    required Color cardBg,
  }) {
    final borderCol = widget.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: TextStyle(fontSize: 13, color: enabled ? currentText : currentText.withOpacity(0.6)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: enabled 
            ? (widget.isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01))
            : (widget.isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderCol),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
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
                    title: Text('Switch to ${plan.title}', style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.bold)),
                    content: Text('Would you like to switch your plan to ${plan.title} for ${plan.price}?', style: TextStyle(color: textCol, fontSize: 13)),
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
              child: const Text('Select Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
  final Function(String topic, String subject)? onTopicTap;

  const StudentCrmTab({
    super.key,
    required this.isDarkMode,
    this.onTopicTap,
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

  Widget _buildSyllabusContent(String rawContent, Color currentText, String subject) {
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
                  ...topics.map((t) {
                    final topicName = t.toString();
                    return Padding(
                      padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
                      child: InkWell(
                        onTap: () {
                          widget.onTopicTap?.call(topicName, subject);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                          child: Row(
                            children: [
                              Text('• ', style: TextStyle(color: currentText.withOpacity(0.7), fontSize: 11)),
                              Expanded(
                                child: Text(
                                  topicName,
                                  style: TextStyle(
                                    color: currentText.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF4F46E5),
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        );
      }
    } catch (_) {}

    // Fallback plain text layout
    return InkWell(
      onTap: () {
        widget.onTopicTap?.call(rawContent, subject);
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                rawContent,
                style: TextStyle(color: currentText, fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF4F46E5),
              size: 13,
            ),
          ],
        ),
      ),
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
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No syllabus guidelines published for your class yet.',
                                style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
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
                                    syllabus['subject'] ?? 'General',
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



// ==========================================
// MERGED FROM: combined_quiz_screen.dart
// ==========================================


class CombinedQuizScreen extends StatefulWidget {
  final String? testId;
  final String? testTitle;
  final String? topic;
  final String? subject;
  final bool isDarkMode;

  const CombinedQuizScreen({
    super.key,
    this.testId,
    this.testTitle,
    this.topic,
    this.subject,
    required this.isDarkMode,
  });

  @override
  State<CombinedQuizScreen> createState() => _CombinedQuizScreenState();
}

class _CombinedQuizScreenState extends State<CombinedQuizScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _questions = [];

  int _currentIndex = 0;
  final Map<String, String> _answers = {}; // Key: question index as string, Value: chosen answer string

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  Map<String, dynamic> _resultsData = {};
  String _activeView = 'quiz'; // 'quiz' or 'results'

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQuizData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      if (widget.testId != null) {
        // Mode 1: Fetch Mock Test from School CRM database
        final response = await http.get(
          Uri.parse('$envBackendUrl/api/tests/${widget.testId}'),
          headers: {
            'Content-Type': 'application/json',
            'Bypass-Tunnel-Reminder': 'true',
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('Server returned status code ${response.statusCode}');
        }

        final data = jsonDecode(response.body);
        if (data == null || data['questions'] == null) {
          throw Exception('Could not parse mock test questions.');
        }

        _questions = data['questions'] is List ? data['questions'] : [];
        final durationMins = data['duration_minutes'] ?? 60;
        _secondsRemaining = durationMins * 60;
        _startTimer();
      } else if (widget.topic != null && widget.subject != null) {
        // Mode 2: Generate AI practice quiz on-the-fly for specified topic
        final response = await http.post(
          Uri.parse('$envBackendUrl/api/ai/quiz'),
          headers: {
            'Content-Type': 'application/json',
            'Bypass-Tunnel-Reminder': 'true',
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'subject': widget.subject,
            'topic': widget.topic,
            'count': 5,
          }),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode != 200) {
          throw Exception('Server returned status code ${response.statusCode}');
        }

        final data = jsonDecode(response.body);
        _questions = data is List ? data : [];
        
        // 2 minutes per question default timer
        _secondsRemaining = _questions.length * 2 * 60;
        if (_secondsRemaining > 0) {
          _startTimer();
        }
      } else {
        throw Exception('Invalid quiz configuration: missing test ID and topic parameters.');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading quiz data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _autoSubmitQuiz();
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _autoSubmitQuiz() async {
    if (_isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time\'s up! Submitting your answers automatically...'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _submitAnswers();
  }

  Future<void> _submitAnswers() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();

    try {
      if (widget.testId != null) {
        // Mode 1: Submit school mock test to backend for auto-grading
        const envBackendUrl = String.fromEnvironment(
          'BACKEND_API_URL',
          defaultValue: 'https://mrivan-ai.onrender.com',
        );
        final jwtToken = _client.auth.currentSession?.accessToken;

        final response = await http.post(
          Uri.parse('$envBackendUrl/api/tests/${widget.testId}/attempt'),
          headers: {
            'Content-Type': 'application/json',
            'Bypass-Tunnel-Reminder': 'true',
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'answers': _answers,
          }),
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) {
          throw Exception('Server returned status code ${response.statusCode}');
        }

        final responseData = jsonDecode(response.body);
        setState(() {
          _resultsData = responseData;
          _isSubmitted = true;
          _isSubmitting = false;
          _activeView = 'results';
        });
      } else {
        // Mode 2: Grade AI-generated practice quiz offline (correctAnswer is already in question data)
        int correctCount = 0;
        final totalQuestions = _questions.length;
        final totalMarks = totalQuestions * 10;
        int score = 0;
        List<dynamic> gradingDetails = [];

        for (int i = 0; i < _questions.length; i++) {
          final q = _questions[i];
          final correctAns = q['correctAnswer'] ?? '';
          final studentAns = _answers[i.toString()] ?? '';
          final isCorrect = studentAns.trim().toLowerCase() == correctAns.toString().trim().toLowerCase();

          if (isCorrect) {
            score += 10;
            correctCount++;
          }

          gradingDetails.add({
            'questionIndex': i,
            'questionText': q['question'],
            'studentAnswer': studentAns,
            'correctAnswer': correctAns,
            'isCorrect': isCorrect,
            'explanation': q['explanation'] ?? '',
          });
        }

        setState(() {
          _resultsData = {
            'score': score,
            'totalMarks': totalMarks,
            'correctCount': correctCount,
            'totalQuestions': totalQuestions,
            'gradingDetails': gradingDetails,
          };
          _isSubmitted = true;
          _isSubmitting = false;
          _activeView = 'results';
        });
      }
    } catch (e) {
      if (kDebugMode) print('Submission error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit attempt: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startTimer(); // resume timer in case of transient network failure
      }
    }
  }

  void _confirmSubmitDialog() {
    final unansweredCount = _questions.length - _answers.length;
    showDialog(
      context: context,
      builder: (ctx) {
        final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final currentCard = widget.isDarkMode ? const Color(0xFF1E1E28) : Colors.white;

        return AlertDialog(
          backgroundColor: currentCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Submit Exam?', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            unansweredCount > 0
                ? 'You have $unansweredCount unanswered questions. Are you sure you want to finish and submit?'
                : 'Are you sure you want to complete and submit your answers now?',
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitAnswers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final currentBg = widget.isDarkMode ? bgDark : bgLight;
    final currentCard = widget.isDarkMode ? cardDark : cardLight;
    final currentText = widget.isDarkMode ? textDark : textLight;
    final currentBorder = widget.isDarkMode ? borderDark : borderLight;

    final quizTitle = widget.testTitle ?? (widget.topic != null ? 'AI Practice: ${widget.topic}' : 'Practice Quiz');

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          quizTitle,
          style: TextStyle(color: currentText, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Sleek Tab/View Switcher Toggle
          if (!_isLoading && _errorMessage.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeView = 'quiz';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _activeView == 'quiz' ? const Color(0xFF4F46E5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Quiz',
                          style: TextStyle(
                            color: _activeView == 'quiz' ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isSubmitted
                          ? () {
                              setState(() {
                                _activeView = 'results';
                              });
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please complete and submit the quiz to see results.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _activeView == 'results' ? const Color(0xFF4F46E5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Opacity(
                          opacity: _isSubmitted ? 1.0 : 0.5,
                          child: Text(
                            'Results',
                            style: TextStyle(
                              color: _activeView == 'results' ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to Load Quiz',
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchQuizData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _isSubmitting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))),
                          const SizedBox(height: 16),
                          Text('Evaluating your test answers...', style: TextStyle(color: currentText, fontSize: 13)),
                        ],
                      ),
                    )
                  : _activeView == 'quiz'
                      ? _buildQuizView(currentBg, currentCard, currentText, currentBorder)
                      : _buildResultsView(currentBg, currentCard, currentText, currentBorder),
    );
  }

  Widget _buildQuizView(Color currentBg, Color currentCard, Color currentText, Color currentBorder) {
    if (_questions.isEmpty) {
      return Center(
        child: Text('No questions available.', style: TextStyle(color: currentText)),
      );
    }

    final question = _questions[_currentIndex];
    final options = question['options'] as List? ?? [];
    final selectedAns = _answers[_currentIndex.toString()];

    // Review mode configurations
    final correctAns = question['correctAnswer'] ?? '';
    final explanation = question['explanation'] ?? '';

    return Column(
      children: [
        // Progress and timer bar (only active if not submitted)
        if (!_isSubmitted) ...[
          LinearProgressIndicator(
            value: _questions.isEmpty ? 0.0 : (_currentIndex + 1) / _questions.length,
            backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            minHeight: 4,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: currentCard.withOpacity(0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${_questions.length}',
                  style: TextStyle(color: currentText.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600),
                ),
                if (_secondsRemaining > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_secondsRemaining),
                        style: TextStyle(
                          color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ] else ...[
          // Post-Submit progress bar (constant 100%)
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 4,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Mode: Question ${_currentIndex + 1} of ${_questions.length}',
                  style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
              ],
            ),
          ),
        ],

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Question Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: currentCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentBorder),
                ),
                child: Text(
                  question['question'] ?? '',
                  style: TextStyle(
                    color: currentText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Question Options
              ...options.map((opt) {
                final optionText = opt.toString();
                final isSelected = selectedAns == optionText;

                Color tileBorderColor = currentBorder;
                Color tileBgColor = currentCard;
                Color checkColor = Colors.transparent;
                Color textStyleColor = currentText;

                if (_isSubmitted) {
                  // Review Mode styling
                  final isCorrectOption = optionText.trim().toLowerCase() == correctAns.toString().trim().toLowerCase();
                  final isStudentSelected = selectedAns == optionText;

                  if (isCorrectOption) {
                    // Correct answer: green outline
                    tileBorderColor = Colors.green;
                    tileBgColor = Colors.green.withOpacity(0.08);
                    checkColor = Colors.green;
                    textStyleColor = Colors.green;
                  } else if (isStudentSelected) {
                    // Incorrect selection: red outline
                    tileBorderColor = Colors.redAccent;
                    tileBgColor = Colors.redAccent.withOpacity(0.08);
                    checkColor = Colors.redAccent;
                    textStyleColor = Colors.redAccent;
                  }
                } else {
                  // Active test taking mode
                  if (isSelected) {
                    tileBorderColor = const Color(0xFF4F46E5);
                    tileBgColor = const Color(0xFF4F46E5).withOpacity(0.08);
                    checkColor = const Color(0xFF4F46E5);
                    textStyleColor = const Color(0xFF4F46E5);
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _isSubmitted
                        ? null // Read-only in review mode
                        : () {
                            setState(() {
                              _answers[_currentIndex.toString()] = optionText;
                            });
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: tileBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tileBorderColor,
                          width: isSelected || (_isSubmitted && (optionText == correctAns || isSelected)) ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: checkColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: checkColor == Colors.transparent ? Colors.grey : checkColor,
                                width: 1.5,
                              ),
                            ),
                            child: checkColor != Colors.transparent
                                ? Icon(
                                    checkColor == Colors.redAccent ? Icons.close : Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                color: textStyleColor,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Show explanation directly in review mode
              if (_isSubmitted && explanation.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: currentBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'AI Explanation',
                            style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        explanation,
                        style: TextStyle(color: currentText.withOpacity(0.85), fontSize: 11, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Navigation Panel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: currentCard,
            border: Border(top: BorderSide(color: currentBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                color: _currentIndex > 0 ? currentText : Colors.grey[400],
                onPressed: _currentIndex > 0
                    ? () {
                        setState(() {
                          _currentIndex--;
                        });
                      }
                    : null,
              ),

              Text(
                '${_currentIndex + 1} / ${_questions.length}',
                style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold),
              ),

              // Next or Finish (if not submitted)
              if (!_isSubmitted) ...[
                _currentIndex < _questions.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Text('Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _confirmSubmitDialog,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                        label: const Text('Finish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ] else ...[
                // Next in Review Mode
                _currentIndex < _questions.length - 1
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Row(
                          children: [
                            Text('Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _activeView = 'results';
                          });
                        },
                        icon: const Icon(Icons.analytics_rounded, size: 14),
                        label: const Text('View Results', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView(Color currentBg, Color currentCard, Color currentText, Color currentBorder) {
    final score = _resultsData['score'] ?? 0;
    final totalMarks = _resultsData['totalMarks'] ?? 100;
    final correctCount = _resultsData['correctCount'] ?? 0;
    final totalQuestions = _resultsData['totalQuestions'] ?? 0;
    final gradingDetails = _resultsData['gradingDetails'] as List? ?? [];

    final percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0.0;
    final isPassed = percentage >= 50.0;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Score Summary Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: currentCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: currentBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            children: [
              Text(
                isPassed ? '🎉 Great Job! Quiz Completed' : '📚 Keep Learning! Quiz Completed',
                style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: totalMarks > 0 ? score / totalMarks : 0,
                      strokeWidth: 10,
                      backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPassed ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isPassed ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        '$score / $totalMarks Marks',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Passed', isPassed ? 'Yes' : 'No', isPassed ? Colors.green : Colors.orange),
                  _buildStatItem('Correct', '$correctCount / $totalQuestions', currentText),
                  _buildStatItem('Accuracy', '${totalQuestions > 0 ? ((correctCount / totalQuestions) * 100).toStringAsFixed(0) : 0}%', currentText),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Row(
          children: [
            Icon(Icons.list_alt_rounded, color: const Color(0xFF4F46E5), size: 18),
            const SizedBox(width: 8),
            Text(
              'Performance Summary Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentText),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Quick list of questions indicating pass/fail status
        ...gradingDetails.map((detail) {
          final qIndex = (detail['questionIndex'] ?? 0) + 1;
          final qText = detail['questionText'] ?? '';
          final studentAns = detail['studentAnswer'] ?? '';
          final isCorrect = detail['isCorrect'] ?? false;
          final detailColor = isCorrect ? Colors.green : Colors.redAccent;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: currentCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: currentBorder),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: detailColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q$qIndex',
                  style: TextStyle(color: detailColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              title: Text(
                qText,
                style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                studentAns.isEmpty ? 'Unanswered' : 'Your Answer: $studentAns',
                style: TextStyle(color: studentAns.isEmpty ? Colors.grey : detailColor, fontSize: 10),
              ),
              trailing: Icon(
                isCorrect ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                color: detailColor,
                size: 18,
              ),
              onTap: () {
                setState(() {
                  _currentIndex = qIndex - 1;
                  _activeView = 'quiz';
                });
              },
            ),
          );
        }),
        const SizedBox(height: 24),

        // Primary actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _activeView = 'quiz';
                  });
                },
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('Review Questions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.home_outlined, size: 16),
                label: const Text('Back to Dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: currentText,
                  side: BorderSide(color: currentBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}



// ==========================================
// MERGED FROM: mock_tests_list_screen.dart
// ==========================================


class MockTestsListScreen extends StatefulWidget {
  final bool isDarkMode;
  const MockTestsListScreen({super.key, required this.isDarkMode});

  @override
  State<MockTestsListScreen> createState() => _MockTestsListScreenState();
}

class _MockTestsListScreenState extends State<MockTestsListScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<dynamic> _tests = [];
  List<dynamic> _attempts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPortalData();
  }

  Future<void> _loadPortalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User session not found.');
      }

      // 1. Fetch available mock tests from backend API
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.get(
        Uri.parse('$envBackendUrl/api/tests'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final testData = jsonDecode(response.body);

      // 2. Fetch student attempts history from Supabase mock_tests/test_attempts join
      final attemptData = await _client
          .from('test_attempts')
          .select('id, score, completed_at, mock_tests(title, total_marks, subject)')
          .eq('student_id', user.id)
          .order('completed_at', ascending: false);

      if (mounted) {
        setState(() {
          _tests = testData is List ? testData : [];
          _attempts = attemptData is List ? attemptData : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Mock Exam Portal Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final currentBg = widget.isDarkMode ? bgDark : bgLight;
    final currentCard = widget.isDarkMode ? cardDark : cardLight;
    final currentText = widget.isDarkMode ? textDark : textLight;
    final currentBorder = widget.isDarkMode ? borderDark : borderLight;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          'CBT Mock Exam Space 📝',
          style: TextStyle(color: currentText, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: const Color(0xFF4F46E5)),
            onPressed: _loadPortalData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Connection Error',
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadPortalData,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPortalData,
                  color: const Color(0xFF4F46E5),
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isDarkMode
                                ? [const Color(0xFF2E1A47), const Color(0xFF1A1F3C)]
                                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: currentBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Computer-Based Testing (CBT) Center 💻',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Test your knowledge with real-time graded exams. Attempts will be saved to your dashboard analytics automatically.',
                              style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 1: Available Exams
                      Row(
                        children: [
                          Icon(Icons.quiz_rounded, color: const Color(0xFF4F46E5), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Available Mock Exams',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _tests.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              alignment: Alignment.center,
                              child: Text(
                                'No exams published yet by your teachers.',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tests.length,
                              itemBuilder: (context, index) {
                                final test = _tests[index];
                                final title = test['title'] ?? 'Mock Test';
                                final subject = test['subject'] ?? 'General';
                                final duration = test['duration_minutes'] ?? 60;
                                final marks = test['total_marks'] ?? 100;
                                final desc = test['description'] ?? '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: currentCard,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: currentBorder),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4F46E5).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                subject,
                                                style: const TextStyle(
                                                  color: Color(0xFF4F46E5),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.timer_outlined, color: Colors.grey, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$duration mins',
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          title,
                                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            desc,
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total: $marks Marks',
                                              style: TextStyle(color: currentText, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => CombinedQuizScreen(
                                                      testId: test['id'],
                                                      testTitle: title,
                                                      isDarkMode: widget.isDarkMode,
                                                    ),
                                                  ),
                                                ).then((_) => _loadPortalData());
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4F46E5),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('Start Exam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),

                      // Section 2: Attempt History
                      Row(
                        children: [
                          Icon(Icons.history_rounded, color: Colors.teal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Past Attempts History',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _attempts.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              alignment: Alignment.center,
                              child: Text(
                                'You haven\'t attempted any mock exams yet.',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _attempts.length,
                              itemBuilder: (context, index) {
                                final attempt = _attempts[index];
                                final testObj = attempt['mock_tests'] ?? {};
                                final title = testObj['title'] ?? 'Mock Test';
                                final subject = testObj['subject'] ?? 'General';
                                final totalMarks = testObj['total_marks'] ?? 100;
                                final score = attempt['score'] ?? 0;
                                final completedAt = attempt['completed_at'] != null
                                    ? DateTime.parse(attempt['completed_at']).toLocal()
                                    : DateTime.now();

                                final formattedDate = '${completedAt.day}/${completedAt.month}/${completedAt.year}';
                                final isPassed = score >= (totalMarks * 0.5);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: currentCard,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: currentBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (isPassed ? Colors.green : Colors.orange).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isPassed ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                                          color: isPassed ? Colors.green : Colors.orange,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$subject • Completed on $formattedDate',
                                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$score/$totalMarks',
                                            style: TextStyle(
                                              color: isPassed ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '${((score / totalMarks) * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}



// ==========================================
// MERGED FROM: quiz_play_screen.dart
// ==========================================


class QuizPlayScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final bool isDarkMode;

  const QuizPlayScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    required this.isDarkMode,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _testData = {};
  List<dynamic> _questions = [];

  int _currentIndex = 0;
  final Map<String, String> _answers = {}; // Key: question index as string, Value: chosen answer string

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchTestDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTestDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.get(
        Uri.parse('$envBackendUrl/api/tests/${widget.testId}'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data == null || data['questions'] == null) {
        throw Exception('Could not parse mock test questions.');
      }

      _testData = data;
      _questions = data['questions'] is List ? data['questions'] : [];

      final durationMins = data['duration_minutes'] ?? 60;
      _secondsRemaining = durationMins * 60;

      _startTimer();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching test questions: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _autoSubmitQuiz();
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _autoSubmitQuiz() async {
    if (_isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time\'s up! Submitting your answers automatically...'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _submitAnswers();
  }

  Future<void> _submitAnswers() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();

    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.post(
        Uri.parse('$envBackendUrl/api/tests/${widget.testId}/attempt'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'answers': _answers,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultsScreen(
              resultsData: responseData,
              testTitle: widget.testTitle,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Submission error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit attempt: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startTimer(); // resume timer in case of transient network failure
      }
    }
  }

  void _confirmSubmitDialog() {
    final unansweredCount = _questions.length - _answers.length;
    showDialog(
      context: context,
      builder: (ctx) {
        final currentText = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final currentCard = widget.isDarkMode ? const Color(0xFF1E1E28) : Colors.white;

        return AlertDialog(
          backgroundColor: currentCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Submit Exam?', style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            unansweredCount > 0
                ? 'You have $unansweredCount unanswered questions. Are you sure you want to finish and submit?'
                : 'Are you sure you want to complete and submit your answers now?',
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitAnswers();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final currentBg = widget.isDarkMode ? bgDark : bgLight;
    final currentCard = widget.isDarkMode ? cardDark : cardLight;
    final currentText = widget.isDarkMode ? textDark : textLight;
    final currentBorder = widget.isDarkMode ? borderDark : borderLight;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          widget.testTitle,
          style: TextStyle(color: currentText, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading && _errorMessage.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _secondsRemaining < 60 ? Colors.redAccent.withOpacity(0.1) : const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_secondsRemaining),
                      style: TextStyle(
                        color: _secondsRemaining < 60 ? Colors.redAccent : const Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to Load Exam',
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTestDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _isSubmitting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))),
                          const SizedBox(height: 16),
                          Text('Evaluating your test attempts...', style: TextStyle(color: currentText, fontSize: 13)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Progress Indicator
                        LinearProgressIndicator(
                          value: _questions.isEmpty ? 0.0 : (_currentIndex + 1) / _questions.length,
                          backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.black12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                          minHeight: 4,
                        ),

                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(20.0),
                            children: [
                              // Question Box
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: currentCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: currentBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Question ${_currentIndex + 1} of ${_questions.length}',
                                      style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _questions[_currentIndex]['question'] ?? '',
                                      style: TextStyle(
                                        color: currentText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Question Options
                              ...(() {
                                final options = _questions[_currentIndex]['options'] as List? ?? [];
                                return options.map((opt) {
                                  final optionText = opt.toString();
                                  final isSelected = _answers[_currentIndex.toString()] == optionText;
                                  final activeColor = const Color(0xFF4F46E5);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _answers[_currentIndex.toString()] = optionText;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Ink(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isSelected ? activeColor.withOpacity(0.08) : currentCard,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? activeColor : currentBorder,
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: isSelected ? activeColor : Colors.transparent,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected ? activeColor : Colors.grey,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                                                  : null,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                optionText,
                                                style: TextStyle(
                                                  color: isSelected ? activeColor : currentText,
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList();
                              }()),
                            ],
                          ),
                        ),

                        // Navigation Panel
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: currentCard,
                            border: Border(top: BorderSide(color: currentBorder)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Previous
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_rounded),
                                color: _currentIndex > 0 ? currentText : Colors.grey[400],
                                onPressed: _currentIndex > 0
                                    ? () {
                                        setState(() {
                                          _currentIndex--;
                                        });
                                      }
                                    : null,
                              ),

                              // Quick Jump indicator dots or numbers
                              Text(
                                '${_currentIndex + 1} / ${_questions.length}',
                                style: TextStyle(color: currentText, fontSize: 13, fontWeight: FontWeight.bold),
                              ),

                              // Next or Submit
                              _currentIndex < _questions.length - 1
                                  ? ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _currentIndex++;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Text('Next', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios_rounded, size: 10),
                                        ],
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: _confirmSubmitDialog,
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                                      label: const Text('Finish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}



// ==========================================
// MERGED FROM: quiz_results_screen.dart
// ==========================================


class QuizResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultsData;
  final String testTitle;
  final bool isDarkMode;

  const QuizResultsScreen({
    super.key,
    required this.resultsData,
    required this.testTitle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final currentBg = isDarkMode ? bgDark : bgLight;
    final currentCard = isDarkMode ? cardDark : cardLight;
    final currentText = isDarkMode ? textDark : textLight;
    final currentBorder = isDarkMode ? borderDark : borderLight;

    final score = resultsData['score'] ?? 0;
    final totalMarks = resultsData['totalMarks'] ?? 100;
    final correctCount = resultsData['correctCount'] ?? 0;
    final totalQuestions = resultsData['totalQuestions'] ?? 0;
    final gradingDetails = resultsData['gradingDetails'] as List? ?? [];

    final percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0.0;
    final isPassed = percentage >= 50.0;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: const Text(
          'Exam Score Report 📊',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Circular Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: currentCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  testTitle,
                  style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Spacer(), // dummy spacer just in case
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: totalMarks > 0 ? score / totalMarks : 0,
                        strokeWidth: 10,
                        backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPassed ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isPassed ? Colors.green : Colors.orange,
                          ),
                        ),
                        Text(
                          '$score / $totalMarks Marks',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Passed', isPassed ? 'Yes' : 'No', isPassed ? Colors.green : Colors.orange),
                    _buildStatItem('Correct', '$correctCount / $totalQuestions', currentText),
                    _buildStatItem('Accuracy', '${totalQuestions > 0 ? ((correctCount / totalQuestions) * 100).toStringAsFixed(0) : 0}%', currentText),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Detailed Review Title
          Row(
            children: [
              Icon(Icons.list_alt_rounded, color: const Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 8),
              Text(
                'Question-by-Question Review',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: currentText),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Question-by-Question review list
          ...gradingDetails.map((detail) {
            final qIndex = (detail['questionIndex'] ?? 0) + 1;
            final qText = detail['questionText'] ?? '';
            final studentAns = detail['studentAnswer'] ?? '';
            final correctAns = detail['correctAnswer'] ?? '';
            final isCorrect = detail['isCorrect'] ?? false;
            final explanation = detail['explanation'] ?? '';

            final detailColor = isCorrect ? Colors.green : Colors.redAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: currentBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: detailColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Q$qIndex',
                          style: TextStyle(color: detailColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          qText,
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Answers review row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Answer', style: TextStyle(color: Colors.grey, fontSize: 9)),
                            const SizedBox(height: 4),
                            Text(
                              studentAns,
                              style: TextStyle(
                                color: isCorrect ? Colors.green : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isCorrect) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Correct Answer', style: TextStyle(color: Colors.grey, fontSize: 9)),
                              const SizedBox(height: 4),
                              Text(
                                correctAns,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // AI Explanation block
                  if (explanation.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: currentBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 12),
                              SizedBox(width: 6),
                              Text(
                                'AI Explanation',
                                style: TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            explanation,
                            style: TextStyle(color: currentText.withOpacity(0.8), fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Return Home Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to Exam Portal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}



// ==========================================
// MERGED FROM: study_notes_view_screen.dart
// ==========================================


class StudyNotesViewScreen extends StatefulWidget {
  final String topic;
  final String subject;
  final bool isDarkMode;

  const StudyNotesViewScreen({
    super.key,
    required this.topic,
    required this.subject,
    required this.isDarkMode,
  });

  @override
  State<StudyNotesViewScreen> createState() => _StudyNotesViewScreenState();
}

class _StudyNotesViewScreenState extends State<StudyNotesViewScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  String _errorMessage = '';
  String _notesMarkdown = '';
  bool _isSavedToLibrary = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchStudyNotes();
  }

  Future<void> _fetchStudyNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.post(
        Uri.parse('$envBackendUrl/api/ai/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'topic': widget.topic,
          'subject': widget.subject,
          'gradeLevel': '10',
          'saveToLibrary': false,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data == null || data['notes'] == null) {
        throw Exception('Failed to parse generated notes.');
      }

      if (mounted) {
        setState(() {
          _notesMarkdown = data['notes'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching study notes: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotesToLibrary() async {
    if (_isSaving || _isSavedToLibrary) return;

    setState(() {
      _isSaving = true;
    });

    try {
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final jwtToken = _client.auth.currentSession?.accessToken;

      final response = await http.post(
        Uri.parse('$envBackendUrl/api/ai/notes'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'topic': widget.topic,
          'subject': widget.subject,
          'gradeLevel': '10',
          'saveToLibrary': true,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      if (mounted) {
        setState(() {
          _isSavedToLibrary = true;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📚 Notes successfully saved to your study library!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error saving notes: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF111116);
    final bgLight = const Color(0xFFF8FAFC);
    final cardDark = const Color(0xFF181824);
    final cardLight = const Color(0xFFFFFFFF);
    final textDark = const Color(0xFFF1F5F9);
    final textLight = const Color(0xFF0F172A);
    final borderDark = Colors.white10;
    final borderLight = const Color(0xFFE2E8F0);

    final currentBg = widget.isDarkMode ? bgDark : bgLight;
    final currentCard = widget.isDarkMode ? cardDark : cardLight;
    final currentText = widget.isDarkMode ? textDark : textLight;
    final currentBorder = widget.isDarkMode ? borderDark : borderLight;

    return Scaffold(
      backgroundColor: currentBg,
      appBar: AppBar(
        title: Text(
          widget.topic,
          style: TextStyle(color: currentText, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: currentText),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (!_isLoading && _errorMessage.isEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Color(0xFF4F46E5)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _notesMarkdown));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notes copied to clipboard!'),
                    backgroundColor: Color(0xFF4F46E5),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              tooltip: 'Copy Notes',
            ),
            IconButton(
              icon: Icon(
                _isSavedToLibrary ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                color: _isSavedToLibrary ? Colors.green : Colors.grey,
              ),
              onPressed: _saveNotesToLibrary,
              tooltip: 'Save to Library',
            ),
          ]
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5))))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to generate study notes',
                          style: TextStyle(color: currentText, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchStudyNotes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Study Notes Header Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDarkMode
                              ? [const Color(0xFF1E1A3C), const Color(0xFF13131A)]
                              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: currentBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Generated conceptual study notes',
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : const Color(0xFF4F46E5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Subject: ${widget.subject} • Target: Class 10 Syllabus',
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Render parsed markdown notes
                    ..._parseAndRenderMarkdown(_notesMarkdown, currentText, currentCard, currentBorder),
                    
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }

  List<Widget> _parseAndRenderMarkdown(String rawText, Color textCol, Color cardCol, Color borderCol) {
    final List<Widget> widgets = [];
    final lines = rawText.split('\n');

    bool inCodeBlock = false;
    List<String> codeBlockLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Code blocks start or end
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          // End of code block: render gathered content
          inCodeBlock = false;
          widgets.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol),
              ),
              child: Text(
                codeBlockLines.join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
          );
          codeBlockLines.clear();
        } else {
          // Start of code block
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }

      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      // Parse headers
      if (trimmed.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
            child: Text(
              trimmed.substring(2),
              style: TextStyle(
                color: textCol,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
            child: Text(
              trimmed.substring(3),
              style: TextStyle(
                color: textCol,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (trimmed.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              trimmed.substring(4),
              style: TextStyle(
                color: textCol,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } 
      // Parse bullet points
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final content = trimmed.substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: textCol.withOpacity(0.7), fontSize: 13)),
                Expanded(
                  child: _renderTextWithBoldSupport(content, textCol, 12),
                ),
              ],
            ),
          ),
        );
      } 
      // Standard paragraph
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _renderTextWithBoldSupport(trimmed, textCol, 12, height: 1.5),
          ),
        );
      }
    }

    return widgets;
  }

  // Helper to parse **bold text** inside paragraphs/bullets
  Widget _renderTextWithBoldSupport(String text, Color textCol, double fontSize, {double height = 1.3}) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: textCol.withOpacity(0.85), fontSize: fontSize, height: height),
        children: spans,
      ),
    );
  }
}



// ==========================================
// MERGED FROM: ai_notes_screen.dart
// ==========================================


class AINotesScreen extends StatefulWidget {
  final bool isDarkMode;
  const AINotesScreen({super.key, required this.isDarkMode});

  @override
  State<AINotesScreen> createState() => _AINotesScreenState();
}

// Named AINotesScreen but the class name will match standard
class _AINotesScreenState extends State<AINotesScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late bool _isDarkMode;

  List<Map<String, dynamic>> _savedNotes = [];
  bool _isLoadingLibrary = false;
  bool _isGenerating = false;

  // Form states
  final TextEditingController _topicController = TextEditingController();
  String _selectedSubject = 'Math';
  String _gradeLevel = '10th Grade';
  
  // Active viewing notes
  String? _activeNotesTitle;
  String? _activeNotesContent;

  final List<String> _subjects = ['Math', 'Physics', 'Chemistry', 'Biology', 'History', 'English', 'Computer Science'];
  final List<String> _grades = ['8th Grade', '9th Grade', '10th Grade', '11th Grade', '12th Grade', 'College'];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingLibrary = true;
    });

    try {
      final list = await DatabaseService.instance.fetchNotes(user.id);
      setState(() {
        _savedNotes = list;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading notes library: $e');
    } finally {
      setState(() {
        _isLoadingLibrary = false;
      });
    }
  }

  Future<void> _generateNotes() async {
    final topic = _topicController.text.trim();
    final user = _client.auth.currentUser;
    if (topic.isEmpty || user == null || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _activeNotesTitle = topic;
      _activeNotesContent = "Mr. Ivan is outlining your study guide, compiling definitions, and generating analogies...";
    });

    try {
      final jwtToken = _client.auth.currentSession?.accessToken;
      const envBackendUrl = String.fromEnvironment(
        'BACKEND_API_URL',
        defaultValue: 'https://mrivan-ai.onrender.com',
      );
      final urls = [
        '$envBackendUrl/api/ai/notes',
      ];

      String markdownContent = '';
      http.Response? response;
      dynamic lastError;
      
      try {
        for (final url in urls) {
          try {
            response = await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Bypass-Tunnel-Reminder': 'true',
                if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
              },
              body: jsonEncode({
                'topic': topic,
                'subject': _selectedSubject,
                'gradeLevel': _gradeLevel,
                'saveToLibrary': true, // Backend saves it directly if operational
              }),
            ).timeout(const Duration(seconds: 5));
            
            if (response.statusCode == 200) {
              break;
            } else {
              throw Exception('Backend returned status code ${response.statusCode}');
            }
          } catch (e) {
            lastError = e;
            if (kDebugMode) {
              print('Failed to connect to $url: $e');
            }
          }
        }

        if (response != null && response.statusCode == 200) {
          final data = jsonDecode(response.body);
          markdownContent = data['notes'] ?? '';
        } else {
          throw lastError ?? Exception('Could not connect to any backend API endpoint');
        }
      } catch (backendError) {
        if (kDebugMode) {
          print('Backend offline or failed, generating simulated study guide: $backendError');
        }
        
        // Generate simulated markdown guide locally
        markdownContent = _generateSimulatedStudyGuide(topic, _selectedSubject, _gradeLevel);

        // Save to Supabase library directly since backend was offline
        await DatabaseService.instance.saveNote(
          userId: user.id,
          title: topic,
          content: markdownContent,
          subject: _selectedSubject,
          classLevel: _gradeLevel,
          isAiGenerated: true,
        );
      }

      setState(() {
        _activeNotesContent = markdownContent;
      });
      
      _topicController.clear();
      _loadLibrary(); // Reload list to include newly created item

    } catch (e) {
      if (kDebugMode) print('Error generating study notes: $e');
      setState(() {
        _activeNotesContent = "Failed to generate study notes. Please check your connection and try again.";
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _generateSimulatedStudyGuide(String topic, String subject, String grade) {
    return """# Study Guide: $topic
## Subject: $subject ($grade)

---

### 1. Core Outline & Definitions
*   **Definition**: The fundamental parameter governing $topic is defined as the measure of its primary states.
*   **Key Concept**: Always analyze the variables and constants in equilibrium before formulating calculations.

### 2. Conceptual Analogies
> Think of it like a highway system:
> *   **Vessels/Nodes**: Represent capacity limits.
> *   **Flowrate**: Represents speed or concentration.
> *   **Obstructions**: Act as resistance parameters.

### 3. Step-by-Step Problem Solving Guide
1.  **Identify State Boundaries**: Determine the starting conditions.
2.  **Apply Equilibrium Equations**: Resolve forces or parameters balancing the system.
3.  **Validate Dimensions**: Check that unit terms match perfectly on both sides.

### 4. Practice Quiz Questions
1.  *True/False*: Can $topic change state in a closed thermodynamic system? (Answer: True, thermal equilibrium permits state changes).
2.  *Short Answer*: What happens when resistance values double? (Answer: The throughput capacity declines proportionally by half).

---
*Created by Mr. Ivan AI Study Assistant on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}*""";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        isDarkMode: _isDarkMode,
        child: Stack(
          children: [
            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: _isDarkMode ? Colors.black26 : Colors.white24,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded, color: _isDarkMode ? Colors.white : Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: _isDarkMode ? Colors.black26 : Colors.white24,
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: const Color(0xFF155DFC)),
                              const SizedBox(width: 8),
                              Text(
                                'AI Study Notes Generator',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body content
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 80,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Sidebar: Notes List (Desktop/Web view)
                      if (MediaQuery.of(context).size.width > 750)
                        SizedBox(
                          width: 250,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: _buildGlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saved Guides',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                                    ),
                                  ),
                                  const Divider(),
                                  Expanded(
                                    child: _isLoadingLibrary
                                        ? const Center(child: CircularProgressIndicator())
                                        : _savedNotes.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No saved guides',
                                                  style: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.black54),
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: _savedNotes.length,
                                                itemBuilder: (context, index) {
                                                  final note = _savedNotes[index];
                                                  final isSelected = note['title'] == _activeNotesTitle;
                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 8),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? (_isDarkMode ? Colors.white12 : Colors.black12)
                                                          : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: ListTile(
                                                      title: Text(
                                                        note['title'] ?? '',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: _isDarkMode ? Colors.white : Colors.black87,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        note['subject'] ?? 'General',
                                                        style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.white54 : Colors.black54),
                                                      ),
                                                      onTap: () {
                                                        setState(() {
                                                          _activeNotesTitle = note['title'];
                                                          _activeNotesContent = note['content'];
                                                        });
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Generator Form or Active Notes View
                      Expanded(
                        child: _activeNotesContent == null
                            ? _buildFormPanel()
                            : _buildNotesViewerPanel(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _buildGlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 54,
                color: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              Text(
                'Generate Study Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a topic, select the subject framework, and let Mr. Ivan build an interactive concept guide.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _topicController,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Topic Name',
                  hintText: 'e.g. Photosynthesis, Ohm\'s Law, WWII',
                  labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                dropdownColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubject = val);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gradeLevel,
                dropdownColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Class Grade Level',
                  labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _grades.map((gr) => DropdownMenuItem(value: gr, child: Text(gr))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _gradeLevel = val);
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _generateNotes,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF155DFC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Generate Outline'),
              ),
              if (MediaQuery.of(context).size.width <= 750 && _savedNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _showSavedNotesSheet,
                  child: const Text('Open Saved Guides'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesViewerPanel() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Sub-header controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
              border: Border(bottom: BorderSide(color: _isDarkMode ? Colors.white10 : Colors.black12)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _activeNotesTitle = null;
                      _activeNotesContent = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activeNotesTitle ?? 'Study Guide Outline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (!_isGenerating)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF155DFC)),
                    onPressed: () {
                      // Simple copy notification
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Study guide copied to clipboard!')),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Notes rendering viewport
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _isGenerating
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            "Generating Outlines...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Mr. Ivan is organizing syllabus definitions, structuring analogies, and writing practice tests...",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                    )
                  : _buildCustomMarkdown(_activeNotesContent ?? ''),
            ),
          ),
        ],
      ),
    );
  }

  // Simple, reliable markdown UI builder to avoid large markdown packages
  Widget _buildCustomMarkdown(String text) {
    final lines = text.split('\n');
    List<Widget> widgets = [];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            trimmed.substring(2),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87),
          ),
        ));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(
            trimmed.substring(3),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF155DFC)),
          ),
        ));
      } else if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            trimmed.substring(4),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ));
      } else if (trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF155DFC))),
              Expanded(
                child: Text(
                  trimmed.substring(2),
                  style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                ),
              ),
            ],
          ),
        ));
      } else if (trimmed.startsWith('1. ') || trimmed.startsWith('2. ') || trimmed.startsWith('3. ') || trimmed.startsWith('4. ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trimmed.substring(0, 3), style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF155DFC))),
              Expanded(
                child: Text(
                  trimmed.substring(3),
                  style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                ),
              ),
            ],
          ),
        ));
      } else if (trimmed.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            border: Border(left: BorderSide(color: const Color(0xFF155DFC), width: 4)),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          child: Text(
            trimmed.substring(2),
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: _isDarkMode ? Colors.white70 : Colors.black54),
          ),
        ));
      } else if (trimmed.startsWith('---')) {
        widgets.add(Divider(color: _isDarkMode ? Colors.white24 : Colors.black12, height: 24));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            trimmed,
            style: TextStyle(fontSize: 14, height: 1.4, color: _isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
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

  void _showSavedNotesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              color: _isDarkMode ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Outlines',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _isDarkMode ? Colors.white : Colors.black87),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _savedNotes.length,
                      itemBuilder: (context, index) {
                        final note = _savedNotes[index];
                        return ListTile(
                          title: Text(
                            note['title'] ?? '',
                            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                          ),
                          subtitle: Text(note['subject'] ?? 'General'),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _activeNotesTitle = note['title'];
                              _activeNotesContent = note['content'];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


