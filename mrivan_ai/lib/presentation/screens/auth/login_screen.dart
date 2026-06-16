import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late final StreamSubscription<AuthState> _authSubscription;
  
  // Text Editing Controllers for Email Form
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscure = true;
  bool _isDarkMode = false; // Toggle for Cloud/Rain Cloud backgrounds

  // Animation Controllers for Background
  late final AnimationController _cloudsController;
  late final AnimationController _rainController;
  late final AnimationController _cardFadeController;

  // Google OAuth Credentials Config
  static const String _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  static const String _iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  // Rain Drops and Cloud configuration lists
  late final List<RainDrop> _rainDrops;
  late final List<FloatingCloud> _clouds;

  @override
  void initState() {
    super.initState();

    // 1. Initialize background animations
    _cloudsController = AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    )..repeat();

    _rainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _cardFadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    // 2. Initialize rain and cloud arrays
    final rand = math.Random();
    _rainDrops = List.generate(80, (index) {
      return RainDrop(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        speed: 10 + rand.nextDouble() * 15,
        length: 8 + rand.nextDouble() * 12,
        weight: 0.8 + rand.nextDouble() * 1.5,
      );
    });

    _clouds = [
      FloatingCloud(xOffset: -0.2, yOffset: 0.12, speed: 0.015, scale: 1.3, opacity: 0.7),
      FloatingCloud(xOffset: 0.25, yOffset: 0.35, speed: 0.01, scale: 0.9, opacity: 0.5),
      FloatingCloud(xOffset: 0.65, yOffset: 0.18, speed: 0.02, scale: 1.1, opacity: 0.65),
      FloatingCloud(xOffset: 1.05, yOffset: 0.42, speed: 0.008, scale: 1.5, opacity: 0.8),
    ];

    // 3. Listen to Supabase auth state changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      final AuthChangeEvent event = data.event;

      if (kDebugMode) {
        print('Supabase Auth Event: $event');
      }

      if (event == AuthChangeEvent.signedIn && session != null) {
        if (kDebugMode) {
          print('SUCCESS: User successfully logged in!');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully logged in as ${session.user.email}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _cloudsController.dispose();
    _rainController.dispose();
    _cardFadeController.dispose();
    super.dispose();
  }

  // Native Google ID Token authentication
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? null : _iosClientId,
        serverClientId: _webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('No ID Token found from Google authentication.');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${error.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Supabase Email / Password login
  Future<void> _handleEmailPasswordSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both email and password.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${error.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Sky Background (Light Sky vs Dark Rain Clouds)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_cloudsController, _rainController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: SkyPainter(
                    isDarkMode: _isDarkMode,
                    cloudsAnimation: _cloudsController.value,
                    rainAnimation: _rainController.value,
                    clouds: _clouds,
                    rainDrops: _rainDrops,
                  ),
                );
              },
            ),
          ),

          // 2. Light / Dark Mode Toggle Button (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: _isDarkMode ? Colors.black26 : Colors.white24,
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: child.key == const ValueKey('dark')
                            ? Tween<double>(begin: 0.75, end: 1.0).animate(anim)
                            : Tween<double>(begin: 0.25, end: 0.5).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _isDarkMode
                          ? const Icon(Icons.wb_sunny_rounded, key: ValueKey('light'), color: Colors.amber)
                          : const Icon(Icons.nights_stay_rounded, key: ValueKey('dark'), color: Colors.indigo),
                    ),
                    onPressed: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          // 3. Central Login Card
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: FadeTransition(
                      opacity: _cardFadeController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _cardFadeController,
                          curve: Curves.easeOutBack,
                        )),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.black.withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: _isDarkMode
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.white.withValues(alpha: 0.45),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.05),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Top Icon (Rounded square container)
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: _isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.login_rounded,
                                          size: 26,
                                          color: _isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // Sign in header
                                      Text(
                                        'Sign in with email',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: _isDarkMode ? Colors.white : Colors.black87,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Make a new doc to bring your words, data, and teams together. For free',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 28),

                                      // Email Field
                                      _buildTextField(
                                        controller: _emailController,
                                        hintText: 'Email',
                                        icon: Icons.mail_outline_rounded,
                                        isDark: _isDarkMode,
                                      ),
                                      const SizedBox(height: 16),

                                      // Password Field
                                      _buildTextField(
                                        controller: _passwordController,
                                        hintText: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        isDark: _isDarkMode,
                                        obscureText: _isObscure,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            size: 20,
                                            color: _isDarkMode ? Colors.white54 : Colors.black45,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isObscure = !_isObscure;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Forgot Password link
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            // Handle forgot password logic
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            'Forgot password?',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Submit Button (Get Started)
                                      if (_isLoading)
                                        const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: _handleEmailPasswordSignIn,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E1E2C),
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(double.infinity, 48),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Get Started',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 24),

                                      // Social Divider
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: _isDarkMode ? Colors.white10 : Colors.black12,
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: Text(
                                              'Or sign in with',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _isDarkMode ? Colors.white38 : Colors.black38,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: _isDarkMode ? Colors.white10 : Colors.black12,
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // Social Sign-in Cards (Google, Facebook, Apple)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildSocialButton(
                                            child: Image.network(
                                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                                              height: 20,
                                            ),
                                            onTap: _handleGoogleSignIn,
                                            isDark: _isDarkMode,
                                          ),
                                          _buildSocialButton(
                                            child: Icon(
                                              Icons.facebook,
                                              color: Colors.blue.shade700,
                                              size: 24,
                                            ),
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Facebook login in development.')),
                                              );
                                            },
                                            isDark: _isDarkMode,
                                          ),
                                          _buildSocialButton(
                                            child: Icon(
                                              Icons.apple,
                                              color: _isDarkMode ? Colors.white : Colors.black,
                                              size: 24,
                                            ),
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Apple login in development.')),
                                              );
                                            },
                                            isDark: _isDarkMode,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  // Frosted text input helper
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black45,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.deepPurple.shade300,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // Frosted social sign-in card helper
  Widget _buildSocialButton({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// Helper Model for Rain Drops
class RainDrop {
  double x;
  double y;
  double speed;
  double length;
  double weight;

  RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.weight,
  });
}

// Helper Model for Floating Clouds
class FloatingCloud {
  double xOffset;
  final double yOffset;
  final double speed;
  final double scale;
  final double opacity;

  FloatingCloud({
    required this.xOffset,
    required this.yOffset,
    required this.speed,
    required this.scale,
    required this.opacity,
  });
}

// Background Custom Painter for Animations
class SkyPainter extends CustomPainter {
  final bool isDarkMode;
  final double cloudsAnimation;
  final double rainAnimation;
  final List<FloatingCloud> clouds;
  final List<RainDrop> rainDrops;

  SkyPainter({
    required this.isDarkMode,
    required this.cloudsAnimation,
    required this.rainAnimation,
    required this.clouds,
    required this.rainDrops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint backgroundPaint = Paint();
    
    // Background gradient setup
    if (!isDarkMode) {
      backgroundPaint.shader = const LinearGradient(
        colors: [
          Color(0xFFD4ECFF), // Soft sky blue gradient
          Color(0xFFEBF6FF),
          Color(0xFFFFFFFF),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    } else {
      backgroundPaint.shader = const LinearGradient(
        colors: [
          Color(0xFF0F172A), // Slate dark mode gradient
          Color(0xFF1E1B4B), // indigo shade
          Color(0xFF0C0A20), // deep midnight
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    }
    canvas.drawRect(rect, backgroundPaint);

    // Arch lines drawn in background (matches concentric circle lines from Ebolt UI design)
    final Paint archPaint = Paint()
      ..color = (isDarkMode ? Colors.white12 : const Color(0xFFCBE3FE)).withValues(alpha: isDarkMode ? 0.05 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.55, archPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.75, archPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.95, archPaint);

    // Floating Clouds rendering
    for (var cloud in clouds) {
      // Calculate current horizontal shift
      final double x = ((cloud.xOffset + cloudsAnimation * cloud.speed * 10) % 1.5 - 0.35) * size.width;
      final double y = cloud.yOffset * size.height;
      _drawCloudShape(canvas, Offset(x, y), cloud.scale, cloud.opacity, isDarkMode);
    }

    // Rain drop lines (drawn only in Dark Mode/Storm clouds)
    if (isDarkMode) {
      final Paint rainPaint = Paint()
        ..color = const Color(0xFF93C5FD).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke;

      for (var drop in rainDrops) {
        final double rx = drop.x * size.width;
        // Animates moving down and wrapping around the screen
        final double ry = (drop.y * size.height + rainAnimation * drop.speed * 300) % size.height;
        
        rainPaint.strokeWidth = drop.weight;
        canvas.drawLine(Offset(rx, ry), Offset(rx, ry + drop.length), rainPaint);
      }
    }
  }

  // Draw soft cloud shapes combining circles
  void _drawCloudShape(Canvas canvas, Offset center, double scale, double opacity, bool isDark) {
    final Paint cloudPaint = Paint()
      ..color = (isDark ? const Color(0xFF334155) : Colors.white).withValues(alpha: opacity * (isDark ? 0.5 : 0.85))
      ..style = PaintingStyle.fill;
    
    cloudPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, (isDark ? 16.0 : 12.0) * scale);

    final double baseRadius = 35 * scale;
    canvas.drawCircle(center, baseRadius, cloudPaint);
    canvas.drawCircle(center + Offset(-baseRadius * 0.85, baseRadius * 0.15), baseRadius * 0.7, cloudPaint);
    canvas.drawCircle(center + Offset(baseRadius * 0.85, baseRadius * 0.2), baseRadius * 0.65, cloudPaint);
    canvas.drawCircle(center + Offset(-baseRadius * 0.35, -baseRadius * 0.55), baseRadius * 0.85, cloudPaint);
    canvas.drawCircle(center + Offset(baseRadius * 0.45, -baseRadius * 0.45), baseRadius * 0.78, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant SkyPainter oldDelegate) => true;
}
