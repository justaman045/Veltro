import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/db_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'providers/providers.dart';
import 'screens/unified_screen.dart';
import 'screens/auth_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  
  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final dbService = DbService();
  await dbService.init();

  await NotificationService().init();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        dbServiceProvider.overrideWithValue(dbService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the current theme mode from the settings provider
    final settings = ref.watch(settingsServiceProvider);
    final currentThemeMode = settings.themeMode;
    // Define a modern, soft color scheme
    final lightColor = ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF), // Apple System Blue
      primary: const Color(0xFF007AFF),
      secondary: const Color(0xFF8E8E93), // Apple System Gray
      tertiary: const Color(0xFFFF2D55), // Apple Pink
      surface: Colors.white,
      onSurface: Colors.black,
      brightness: Brightness.light,
    );

    final darkColor = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A84FF), // iOS Dark Mode Blue
      primary: const Color(0xFF0A84FF),
      secondary: const Color(0xFF8E8E93), // System Gray
      tertiary: const Color(0xFFFF375F), // Pink
      surface: Colors.black, // True OLED black
      onSurface: Colors.white,
      brightness: Brightness.dark,
    );

    return GetMaterialApp(
      title: 'Agentic Todo',
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      theme: ThemeData(
        colorScheme: lightColor,
        useMaterial3: true,
        scaffoldBackgroundColor: lightColor.surface,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColor.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            color: lightColor.onSurface,
            fontSize: 34, // Large iOS Header
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
          iconTheme: IconThemeData(color: lightColor.onSurface),
        ),
        cardTheme: CardThemeData(
          elevation: 12,
          shadowColor: Colors.black.withValues(
            alpha: 0.15,
          ), // Soft floating shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ), // Soft cupertino corners
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: lightColor.primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: lightColor.primary);
            }
            return IconThemeData(color: Colors.grey.shade400);
          }),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColor,
        useMaterial3: true,
        scaffoldBackgroundColor: darkColor.surface,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: darkColor.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            color: darkColor.onSurface,
            fontSize: 34, // Large iOS Header
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
          iconTheme: IconThemeData(color: darkColor.onSurface),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ), // Soft cupertino corners
          color: const Color(
            0xFF1C1C1E,
          ), // Deep gray for iOS cards on black background
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: darkColor.primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: darkColor.primary);
            }
            return IconThemeData(color: Colors.grey.shade600);
          }),
        ),
      ),
      themeMode: currentThemeMode,
      home: Consumer(
        builder: (context, ref, child) {
          final authStateAsync = ref.watch(authStateProvider);

          return authStateAsync.when(
            data: (user) {
              final db = ref.read(dbServiceProvider);
              if (user != null) {
                // Instantly sync cloud tasks to local isar database upon successful login
                db.startCloudSync(user);
                return const UnifiedScreen();
              } else {
                db.stopCloudSync();
                return const AuthView();
              }
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) =>
                Scaffold(body: Center(child: Text('Auth Error: $e'))),
          );
        },
      ),
    );
  }
}
