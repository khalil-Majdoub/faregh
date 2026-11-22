import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_account.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/society/society_dashboard_screen.dart';
import 'screens/user/user_shell_screen.dart';
import 'services/auth_provider.dart';
import 'services/queue_provider.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QueueTimeApp());
}

class QueueTimeApp extends StatelessWidget {
  const QueueTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<QueueProvider>(
          create: (_) => QueueProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Feregh',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 18),
              const CircularProgressIndicator(color: AppColors.navyDark),
            ],
          ),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const AuthScreen();
    }

    if (auth.currentUser!.role == UserRole.society) {
      return const SocietyDashboardScreen();
    }

    return const UserShellScreen();
  }
}
