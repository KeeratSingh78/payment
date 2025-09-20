import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'config/supabase_config.dart';
import 'services/voice_service.dart';
import 'services/fraud_detection_service.dart';
import 'providers/app_providers.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/send_money_screen.dart';
import 'screens/receive_money_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // Request permissions
  await _requestPermissions();
  
  // Initialize services
  await VoiceService.initialize();
  await FraudDetectionService.initialize();
  
  runApp(
    const ProviderScope(
      child: SurakshaPayApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  await [
    Permission.microphone,
    Permission.camera,
    Permission.storage,
    Permission.notification,
  ].request();
}

class SurakshaPayApp extends ConsumerWidget {
  const SurakshaPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScreen = ref.watch(navigationProvider);
    
    return MaterialApp(
      title: 'SurakshaPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: _getScreenForRoute(currentScreen),
    );
  }

  Widget _getScreenForRoute(String route) {
    switch (route) {
      case 'splash':
        return const SplashScreen();
      case 'login':
        return const LoginScreen();
      case 'registration':
        return const RegistrationScreen();
      case 'home':
        return const HomeDashboard();
      case 'send-money':
        return const SendMoneyScreen();
      case 'receive-money':
        return const ReceiveMoneyScreen();
      case 'history':
        return const TransactionHistoryScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const SplashScreen();
    }
  }
}
