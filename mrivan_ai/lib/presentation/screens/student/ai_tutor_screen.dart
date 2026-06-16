import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';
import '../../../data/services/database_service.dart';

class AITutorScreen extends StatefulWidget {
  final bool isDarkMode;
  const AITutorScreen({super.key, required this.isDarkMode});

  @override
  State<AITutorScreen> createState() => _AITutorScreenState();
}

class _AITutorScreenState extends State<AITutorScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  late bool _isDarkMode;

  List<Map<String, dynamic>> _sessions = [];
  String? _selectedSessionId;
  String? _selectedSubject = 'Math';
  String _gradeLevel = '10th Grade';
  List<Map<String, dynamic>> _messages = [];

  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _subjects = ['Math', 'Physics', 'Chemistry', 'Biology', 'History', 'English', 'Computer Science'];
  final List<String> _grades = ['8th Grade', '9th Grade', '10th Grade', '11th Grade', '12th Grade', 'College'];

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _loadSessions();
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
      setState(() {
        _isLoadingSessions = false;
      });
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
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _createNewSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final sessionTitle = 'Tutor: $_selectedSubject - ${DateTime.now().day}/${DateTime.now().month}';
      final newSession = await DatabaseService.instance.createAIChatSession(
        user.id,
        sessionTitle,
        _selectedSubject ?? 'General',
      );

      setState(() {
        _selectedSessionId = newSession['id'];
        _sessions.insert(0, newSession);
        _messages = [];
      });

      // Insert welcoming message
      final welcomeMsg = 'Hello! I am Mr. Ivan, your AI $_selectedSubject tutor for $_gradeLevel. How can I help you learn today?';
      await DatabaseService.instance.insertChatMessage(
        newSession['id'],
        'ai',
        welcomeMsg,
      );

      // Refresh local messages
      final messages = await DatabaseService.instance.fetchAIChatMessages(newSession['id']);
      setState(() {
        _messages = messages;
      });
      
    } catch (e) {
      if (kDebugMode) print('Error creating session: $e');
    } finally {
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedSessionId == null || _isSending) return;

    _messageController.clear();

    setState(() {
      _isSending = true;
      // Optimistically insert user message locally
      _messages.add({
        'sender': 'user',
        'content': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    try {
      // 1. Insert user message in Database
      await DatabaseService.instance.insertChatMessage(
        _selectedSessionId!,
        'user',
        text,
      );

      // 2. Call backend (with simulated offline fallback)
      String aiResponseText = '';
      try {
        final session = _sessions.firstWhere((s) => s['id'] == _selectedSessionId);
        final subjectStr = session['subject'] ?? 'General';
        
        // Retrieve JWT token to authorize with backend
        final jwtToken = _client.auth.currentSession?.accessToken;

        // Try calling localhost/backend API
        final backendUrl = kIsWeb 
            ? 'http://localhost:3000/api/ai/tutor/chat'
            : 'http://10.0.2.2:3000/api/ai/tutor/chat'; // Android emulator route

        final response = await http.post(
          Uri.parse(backendUrl),
          headers: {
            'Content-Type': 'application/json',
            if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'message': text,
            'sessionId': _selectedSessionId,
            'subject': subjectStr,
            'gradeLevel': _gradeLevel,
          }),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          aiResponseText = data['response'] ?? '';
        } else {
          throw Exception('Backend returned status code ${response.statusCode}');
        }
      } catch (backendError) {
        if (kDebugMode) {
          print('Backend offline or failed, using simulated response: $backendError');
        }
        // Fallback: Generate smart simulated pedagogical response
        aiResponseText = _generateSimulatedResponse(text);
        
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
      setState(() {
        _isSending = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        isDarkMode: _isDarkMode,
        child: Stack(
          children: [
            // 1. Header Area
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
                              Icon(Icons.chat_bubble_outline_rounded, color: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple),
                              const SizedBox(width: 8),
                              Text(
                                'AI Tutor - Mr. Ivan',
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

            // 2. Main Body Grid / Columns
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 80,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar: Sessions History (hidden on small screens)
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'History',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: _isDarkMode ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_comment_rounded, color: Colors.purpleAccent),
                                        onPressed: _showStartSessionDialog,
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Expanded(
                                    child: _isLoadingSessions
                                        ? const Center(child: CircularProgressIndicator())
                                        : _sessions.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No past chats',
                                                  style: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.black54),
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: _sessions.length,
                                                itemBuilder: (context, index) {
                                                  final session = _sessions[index];
                                                  final isSelected = session['id'] == _selectedSessionId;
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
                                                        session['title'] ?? 'Chat Session',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                          color: _isDarkMode ? Colors.white : Colors.black87,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        session['subject'] ?? 'General',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                                                        ),
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
                          ),
                        ),

                      // Chat Area
                      Expanded(
                        child: _selectedSessionId == null
                            ? _buildCreateSessionPanel()
                            : _buildChatPanel(),
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

  Widget _buildCreateSessionPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: _buildGlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 50,
                color: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              Text(
                'Start a New Learning Session',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select your subject and grade level to begin personalized tutoring.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              // Subject Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(labelText: 'Subject'),
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
              // Grade Dropdown
              DropdownButtonFormField<String>(
                value: _gradeLevel,
                decoration: const InputDecoration(labelText: 'Grade Level'),
                items: _grades.map((gr) {
                  return DropdownMenuItem(value: gr, child: Text(gr));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _gradeLevel = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _createNewSession,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: _isDarkMode ? Colors.purpleAccent.shade400 : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Chatting'),
              ),
              if (MediaQuery.of(context).size.width <= 750 && _sessions.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _showHistorySheet,
                  child: const Text('View Chat History'),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Active chat sub-header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
              border: Border(bottom: BorderSide(color: _isDarkMode ? Colors.white10 : Colors.black12)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() {
                      _selectedSessionId = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sessions.firstWhere((s) => s['id'] == _selectedSessionId)['title'] ?? 'AI Tutor Chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
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
                          style: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.black54),
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
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isAI
                                    ? (_isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.5))
                                    : (_isDarkMode ? Colors.purpleAccent.withValues(alpha: 0.2) : Colors.deepPurple.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isAI ? Radius.zero : const Radius.circular(16),
                                  bottomRight: isAI ? const Radius.circular(16) : Radius.zero,
                                ),
                                border: Border.all(
                                  color: isAI
                                      ? (_isDarkMode ? Colors.white10 : Colors.black12)
                                      : (_isDarkMode ? Colors.purpleAccent.withValues(alpha: 0.4) : Colors.deepPurple.withValues(alpha: 0.3)),
                                ),
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Loading/Sending Indicator
          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(
                    height: 12,
                    width: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mr. Ivan is thinking...',
                    style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            ),

          // Input Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Ask a learning question...',
                            hintStyle: TextStyle(color: _isDarkMode ? Colors.white38 : Colors.black38),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _showStartSessionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? localSubject = _selectedSubject;
        return AlertDialog(
          title: const Text('Start New Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: localSubject,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: _subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                onChanged: (val) => localSubject = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSubject = localSubject;
                });
                Navigator.pop(context);
                _createNewSession();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showHistorySheet() {
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
                    'Chat Sessions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _isDarkMode ? Colors.white : Colors.black87,
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
                            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
                          ),
                          subtitle: Text(session['subject'] ?? 'General'),
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
          ),
        );
      },
    );
  }
}
