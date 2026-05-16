import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin_screen.dart';
import 'services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

// ─── ثابت لكل الـ AppBars ───
const kStatusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Color(0xFF0B2C6B),
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
);

const kStatusBarStyleDark = SystemUiOverlayStyle(
  statusBarColor: Color(0xFF0D0D0D),
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: Color(0xFF1E1E2E),
  systemNavigationBarIconBrightness: Brightness.light,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(kStatusBarStyle);

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(isDark ? kStatusBarStyleDark : kStatusBarStyle);

        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              locale: locale,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('ar')],
              theme: ThemeData(
                brightness: Brightness.light,
                primaryColor: const Color(0xFF0B2C6B),
                scaffoldBackgroundColor: const Color(0xFFF5F8FD),
                cardColor: Colors.white,
                textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
                appBarTheme: const AppBarTheme(
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Color(0xFF0B2C6B),
                  foregroundColor: Colors.white,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Color(0xFF0B2C6B),
                    statusBarIconBrightness: Brightness.light,
                    systemNavigationBarColor: Colors.white,
                    systemNavigationBarIconBrightness: Brightness.dark,
                  ),
                ),
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF0B2C6B),
                  secondary: Color(0xFF16A34A),
                  surface: Colors.white,
                  background: Color(0xFFF5F8FD),
                ),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: Colors.white,
                  selectedItemColor: Color(0xFF0B2C6B),
                  unselectedItemColor: Colors.black38,
                  elevation: 8,
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primaryColor: const Color(0xFF4A7FD4),
                scaffoldBackgroundColor: const Color(0xFF0D0D0D),
                cardColor: const Color(0xFF1E1E2E),
                textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
                appBarTheme: const AppBarTheme(
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Color(0xFF0D0D0D),
                  foregroundColor: Colors.white,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Color(0xFF0D0D0D),
                    statusBarIconBrightness: Brightness.light,
                    systemNavigationBarColor: Color(0xFF1E1E2E),
                    systemNavigationBarIconBrightness: Brightness.light,
                  ),
                ),
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF4A7FD4),
                  secondary: Color(0xFF22C55E),
                  surface: Color(0xFF1E1E2E),
                  background: Color(0xFF0D0D0D),
                ),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: Color(0xFF1E1E2E),
                  selectedItemColor: Color(0xFF4A7FD4),
                  unselectedItemColor: Colors.white38,
                  elevation: 8,
                ),
              ),
              home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _SplashScreen(isAr: locale.languageCode == 'ar');
                  }
                  if (snapshot.hasData) {
                    NotificationService.startListeningToNotifications();
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('admins')
                          .doc(snapshot.data!.email)
                          .get(),
                      builder: (context, adminSnap) {
                        if (adminSnap.connectionState == ConnectionState.waiting) {
                          return _SplashScreen(isAr: locale.languageCode == 'ar');
                        }
                        if (adminSnap.hasData && adminSnap.data!.exists) {
                          return AdminScreen();
                        }
                        return const MainScreen();
                      },
                    );
                  }
                  NotificationService.stopListening();
                  return LoginScreen();
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  final bool isAr;
  const _SplashScreen({this.isAr = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kStatusBarStyle,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFF0B2C6B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 130, height: 130,
                errorBuilder: (_, __, ___) => Container(
                  height: 100, width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 24),
              Text('KEEP IT CLEAN',
                  style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(isAr ? 'نظام إدارة المتطوعين' : 'Volunteer Management System',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 48),
              SizedBox(width: 28, height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white.withOpacity(0.8))),
            ],
          ),
        ),
      ),
    );
  }
}