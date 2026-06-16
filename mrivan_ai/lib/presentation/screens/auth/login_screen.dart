import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/animated_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String webClientId = '524472321619-ft3dc0catvgplebulv2bqrpakdi8uo18.apps.googleusercontent.com';
  // Android client ID registered with Package name com.ash.mrivan_ai
  static const String androidClientId = '524472321619-06jghr6deij7ig11u2smbk2gts6scn1k.apps.googleusercontent.com';
  static const String iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final StreamSubscription<AuthState> _authSubscription;
  
  bool _isLoading = false;
  bool? _isDarkModeState; // Toggle state
  bool get _isDarkMode => _isDarkModeState ?? false;

  // Animation Controller for Login Card
  late final AnimationController _cardFadeController;

  @override
  void initState() {
    super.initState();

    _cardFadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    // Listen to Supabase auth state changes
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
    _cardFadeController.dispose();
    super.dispose();
  }

  // Native Google ID Token authentication (Mobile) or OAuth Redirect (Web)
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // For Web, use Supabase's native OAuth flow to bypass google_sign_in package limitations
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kDebugMode ? 'http://localhost:5000' : Uri.base.origin,
        );
        return;
      }

      // Mobile (Android / iOS) flows
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        // Do not pass clientId for Android as it overrides and breaks returning the ID token.
        clientId: defaultTargetPlatform == TargetPlatform.iOS ? LoginScreen.iosClientId : null,
        serverClientId: LoginScreen.webClientId,
      );

      await googleSignIn.signOut().catchError((_) {}); // Ignore sign-out errors

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (kDebugMode) {
        print('Google Sign-In Account Info:');
        print(' - Email: ${googleUser.email}');
        print(' - ID Token: ${idToken != null ? "FOUND (Length: ${idToken.length})" : "NULL"}');
        print(' - Access Token: ${accessToken != null ? "FOUND (Length: ${accessToken.length})" : "NULL"}');
      }

      if (idToken == null) {
        throw Exception(
          "Google did not return an ID token.\n\n"
          "To fix this, please verify:\n"
          "1. You have registered your Android SHA-1 fingerprint in the Google Cloud Console under your Android Client ID.\n"
          "2. The 'serverClientId' in code matches the Web Client ID from your Google Cloud Console.\n"
          "3. The OAuth Consent Screen is configured and published in Google Cloud Console."
        );
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session == null) {
        throw Exception("Supabase login failed");
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('ApiException: 10')) {
        errorMessage = "Google Sign-In Developer Error (ApiException 10).\n\n"
            "This typically means your Android SHA-1 certificate fingerprint is not registered "
            "in the Google Cloud Console under your Android Client ID, or the package name "
            "com.ash.mrivan_ai does not match the registration.";
      } else if (errorMessage.contains('ApiException: 12500')) {
        errorMessage = "Google Sign-In Error (ApiException 12500).\n\n"
            "This typically indicates a mismatch in the OAuth Consent Screen configuration, "
            "or the Google Cloud project configuration is incomplete.";
      }
      
      if (kDebugMode) {
        print('Google Sign-In Error Details: $e');
      }
      
      if (mounted) {
        _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = _isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 28),
              const SizedBox(width: 12),
              Text(
                'Authentication Error',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
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
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF155DFC),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkModeState ??= MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        isDarkMode: _isDarkMode,
        child: Stack(
          children: [
            // 1. Light / Dark Mode Toggle Button (Top Right)
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
                            ? const Icon(Icons.lightbulb_rounded, key: ValueKey('light'), color: Colors.amber)
                            : const Icon(Icons.school_rounded, key: ValueKey('dark'), color: Color(0xFF155DFC)),
                      ),
                      onPressed: () {
                        setState(() {
                          _isDarkModeState = !_isDarkMode;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),

            // 2. Central Login Card
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
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF155DFC)),
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
      ),
    );
  }
}
