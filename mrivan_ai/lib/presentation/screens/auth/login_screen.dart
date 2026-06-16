import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String webClientId = '524472321619-ft3dc0catvgplebulv2bqrpakdi8uo18.apps.googleusercontent.com';
  // Android client ID registered with Package name com.ash.mrivan_ai
  static const String androidClientId = '524472321619-06jghr6deij7ig11u2smbk2gts6scn1k.apps.googleusercontent.com';
  static const String iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late final StreamSubscription<AuthState> _authSubscription;
  
  bool _isLoading = false;
  bool _isDarkMode = false; // Toggle state

  // Animation Controllers for Background
  late final AnimationController _cloudsController;
  late final AnimationController _themeTransitionController; // Smooth transition controller
  late final AnimationController _cardFadeController;

  // Cloud configuration list
  late final List<FloatingCloud> _clouds;

  @override
  void initState() {
    super.initState();

    // 1. Initialize background animations
    _cloudsController = AnimationController(
      duration: const Duration(seconds: 45),
      vsync: this,
    )..repeat();

    // Controller to smoothly lerp values between Light and Dark mode
    _themeTransitionController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _cardFadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    // 2. Initialize cloud coordinates
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
    _cloudsController.dispose();
    _themeTransitionController.dispose();
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
        clientId: kIsWeb ? LoginScreen.webClientId : null,
        serverClientId: LoginScreen.webClientId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Smoothly Transitioning Sky Background (Gradients & Clouds dynamically interpolate)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_cloudsController, _themeTransitionController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: SkyPainter(
                    themeTransition: _themeTransitionController.value,
                    cloudsAnimation: _cloudsController.value,
                    clouds: _clouds,
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
                        if (_isDarkMode) {
                          _themeTransitionController.forward();
                        } else {
                          _themeTransitionController.reverse();
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          // 3. Central Login Card (Constrained & simplified to Google-only)
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
                          constraints: const BoxConstraints(maxWidth: 380),
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
                                        'Sign in to Mrivan AI',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: _isDarkMode ? Colors.white : Colors.black87,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Access your CRM dashboard and subjects tutor instantly.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 32),

                                      // Google Sign-In Card Button
                                      if (_isLoading)
                                        const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                        )
                                      else
                                        InkWell(
                                          onTap: _handleGoogleSignIn,
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            width: double.infinity,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: _isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _isDarkMode
                                                    ? Colors.white.withValues(alpha: 0.1)
                                                    : Colors.black.withValues(alpha: 0.06),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.02),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.network(
                                                  'https://developers.google.com/identity/images/g-logo.png',
                                                  height: 20,
                                                  errorBuilder: (context, error, stackTrace) => Icon(
                                                    Icons.g_mobiledata_rounded,
                                                    color: _isDarkMode ? Colors.white70 : Colors.blue,
                                                    size: 26,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Continue with Google',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: _isDarkMode ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 32),

                                      // Terms and conditions disclaimer
                                      Text(
                                        'By continuing, you agree to our Terms of Service and Privacy Policy.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isDarkMode ? Colors.white30 : Colors.black38,
                                        ),
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

// Background Custom Painter for Transitions (Linear Interpolations)
class SkyPainter extends CustomPainter {
  final double themeTransition; // 0.0 = Light Mode, 1.0 = Dark Mode
  final double cloudsAnimation;
  final List<FloatingCloud> clouds;

  SkyPainter({
    required this.themeTransition,
    required this.cloudsAnimation,
    required this.clouds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint backgroundPaint = Paint();
    
    // 1. Smoothly interpolate background gradient top/bottom colors
    final Color topColor = Color.lerp(
      const Color(0xFFD4ECFF), // Light top (soft blue)
      const Color(0xFF0F172A), // Dark top (stormy navy slate)
      themeTransition
    )!;
    final Color bottomColor = Color.lerp(
      const Color(0xFFFFFFFF), // Light bottom (white)
      const Color(0xFF070512), // Dark bottom (deep night black)
      themeTransition
    )!;

    backgroundPaint.shader = LinearGradient(
      colors: [topColor, bottomColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    // 2. Smoothly interpolate background arch colors
    final Color archColor = Color.lerp(
      const Color(0xFFCBE3FE).withValues(alpha: 0.4),
      Colors.white.withValues(alpha: 0.05),
      themeTransition
    )!;
    
    final Paint archPaint = Paint()
      ..color = archColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.55, archPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.75, archPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 1.05), size.height * 0.95, archPaint);

    // 3. Render drifting clouds with interpolated styles
    for (var cloud in clouds) {
      final double x = ((cloud.xOffset + cloudsAnimation * cloud.speed * 10) % 1.5 - 0.35) * size.width;
      final double y = cloud.yOffset * size.height;
      _drawCloudShape(canvas, Offset(x, y), cloud.scale, cloud.opacity);
    }
  }

  // Draw soft cloud shapes by combining overlapping circular shapes
  void _drawCloudShape(Canvas canvas, Offset center, double scale, double opacity) {
    // Interpolate cloud body color (white to dark slate-grey)
    final Color cloudColor = Color.lerp(
      Colors.white.withValues(alpha: opacity * 0.85),
      const Color(0xFF2E384D).withValues(alpha: opacity * 0.55),
      themeTransition
    )!;

    final Paint cloudPaint = Paint()
      ..color = cloudColor
      ..style = PaintingStyle.fill;
    
    // Interpolate cloud blur radius (fuzzy light clouds vs highly blurred night storm clouds)
    final double blurSigma = lerpDouble(12.0, 18.0, themeTransition)!;
    cloudPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma * scale);

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
