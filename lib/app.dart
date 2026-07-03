import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'services/supabase_config.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class RemindMDApp extends StatelessWidget {
  const RemindMDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RemindMD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SupabaseConfig.isConfigured ? const _AuthGate() : const _NotConfiguredScreen(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}

/// Shown when the app is launched without SUPABASE_URL / SUPABASE_ANON_KEY
/// dart-defines, so a missing config reads as a clear message rather than a
/// crash on first Supabase.instance access.
class _NotConfiguredScreen extends StatelessWidget {
  const _NotConfiguredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RemindMD', style: AppFonts.header(size: 24)),
              const SizedBox(height: 12),
              Text(
                'Supabase isn\'t configured yet. Run with:\n\n'
                'flutter run \\\n'
                '  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \\\n'
                '  --dart-define=SUPABASE_ANON_KEY=your-anon-key',
                textAlign: TextAlign.center,
                style: AppFonts.mono(size: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
