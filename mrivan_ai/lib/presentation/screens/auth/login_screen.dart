import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
          print('User ID: ${session.user.id}');
          print('User Email: ${session.user.email}');
        }
        // Show success snackbar
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
    super.dispose();
  }

  // TODO: Paste your actual Client IDs from Google Cloud Console here
  // Web Client ID is mandatory for Android & Web to request the ID Token
  static const String _webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  // iOS Client ID is required for iOS native sign-in
  static const String _iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Initialize GoogleSignIn with client IDs.
      // - clientId is required for iOS.
      // - serverClientId is the Web Client ID, required on Android to fetch the idToken.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? null : _iosClientId,
        serverClientId: _webClientId,
      );

      // 2. Trigger native account chooser (opens native sheet inside the app)
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 3. Obtain authentication details
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('No ID Token found from Google authentication.');
      }

      // 4. Authenticate with Supabase using the ID Token
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade900,
              Colors.indigo.shade800,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: Colors.white.withValues(alpha: 0.1), // Glassmorphic effect
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Logo / Title
                      const Icon(
                        Icons.school_outlined,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mrivan AI',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'School CRM & AI Tutor Platform',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Google Sign In Button
                      if (_isLoading)
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.login,
                              color: Colors.white,
                            ),
                          ),
                          label: const Text(
                            'Sign In with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Terms and conditions disclaimer
                      Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
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
    );
  }
}
