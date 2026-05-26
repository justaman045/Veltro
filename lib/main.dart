import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'services/db_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/subscription_service.dart';
import 'services/ai_service.dart';
import 'providers/providers.dart';
import 'screens/unified_screen.dart';
import 'screens/login_view.dart';
import 'screens/signup_view.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_view.dart';

final appReady = Completer<void>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase init failed: $e — running without Firebase/Crashlytics');
  }

  final prefs = await SharedPreferences.getInstance();

  DbService? dbService;
  SubscriptionService? subService;
  AiService? aiService;

  try {
    dbService = DbService();
    await dbService.init();

    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('Notification init failed: $e — running without notifications');
    }

    const rcApiKey = String.fromEnvironment('REVENUECAT_API_KEY');
    const openRouterKey = String.fromEnvironment('OPENROUTER_API_KEY');

    if (rcApiKey.isEmpty || openRouterKey.isEmpty) {
      debugPrint(
        'Missing --dart-define arguments: REVENUECAT_API_KEY, OPENROUTER_API_KEY — '
        'running without purchase/AI support',
      );
    } else {
      subService = SubscriptionService();
      try {
        final user = FirebaseAuth.instance.currentUser;
        await subService.init(apiKey: rcApiKey, appUserId: user?.uid);
      } catch (e) {
        debugPrint('RevenueCat init failed: $e — running without purchase support');
      }

      final savedModel = prefs.getString('openRouterModel') ?? 'openai/gpt-oss-120b:free';
      aiService = AiService(openRouterKey, model: savedModel);
    }
  } catch (e) {
    debugPrint('Startup error: $e — running in degraded mode');
  } finally {
    appReady.complete();
  }

  runApp(
    ProviderScope(
      overrides: [
        if (dbService != null) dbServiceProvider.overrideWithValue(dbService),
        if (aiService != null) aiServiceProvider.overrideWithValue(aiService),
        if (subService != null) subscriptionServiceProvider.overrideWithValue(subService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

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
      home: _AuthGate(prefs: prefs),
    );
  }
}

class _AuthGate extends StatefulWidget {
  final SharedPreferences prefs;

  const _AuthGate({required this.prefs});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _showSignUp = false;
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _onboardingComplete = widget.prefs.getBool('onboarding_complete') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: appReady.future,
      builder: (context, readySnapshot) {
        if (readySnapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        if (_onboardingComplete == false) {
          return OnboardingView(onComplete: () {
            setState(() => _onboardingComplete = true);
          });
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _onboardingComplete == null) {
              return const SplashScreen();
            }
            final user = snapshot.data;
            if (user != null) {
              return const UnifiedScreen();
            }
            if (_showSignUp) {
              return SignUpView(onSignIn: () => setState(() => _showSignUp = false));
            }
            return LoginView(onSignUp: () => setState(() => _showSignUp = true));
          },
        );
      },
    );
  }
}
