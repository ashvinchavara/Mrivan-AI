import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/landing_page.dart';
import 'presentation/screens/dashboard/dashboard_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hajwgwskgtwdmviviysq.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhhandnd3NrZ3R3ZG12aXZpeXNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1NDc2MTIsImV4cCI6MjA5NzEyMzYxMn0.sxr1yCql0VWtBDk9qJvrjgpKLeEZx0PpQjh8svYCGFE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mrivan AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF155DFC)),
        useMaterial3: true,
      ),
      home: const AuthStateRouter(),
    );
  }
}

class AuthStateRouter extends StatelessWidget {
  const AuthStateRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const DashboardRouter();
        } else {
          return const LandingPageScreen();
        }
      },
    );
  }
}
