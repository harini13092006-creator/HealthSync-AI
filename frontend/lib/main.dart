import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/task_provider.dart';
import 'providers/health_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize storage & network configs
  await StorageService.loadCustomBaseUrl();
  await NotificationService.initialize();

  runApp(const HealthSyncApp());
}

class HealthSyncApp extends StatelessWidget {
  const HealthSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'HealthSync AI',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
