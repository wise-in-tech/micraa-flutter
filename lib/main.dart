import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/classes_screen.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'config/app_config.dart';

void main() {
  // livekit_client (and our own services) log via package:logging, which is
  // silent unless something listens. Wiring it to debugPrint makes those
  // messages show up in `adb logcat` (device logs, incl. release builds
  // installed via `adb install`), which is essential for diagnosing a stuck
  // "connecting to the audio session" state in the field.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final error = record.error != null ? ' | error: ${record.error}' : '';
    debugPrint('[${record.level.name}] ${record.loggerName}: ${record.message}$error');
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MicraaApp(),
    ),
  );
}

class MicraaApp extends StatefulWidget {
  const MicraaApp({super.key});

  @override
  State<MicraaApp> createState() => _MicraaAppState();
}

class _MicraaAppState extends State<MicraaApp> {
  late Future<UserModel?> _initialUser;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initialUser = _checkLoginStatus();
  }

  /// Vérifie si un JWT valide est stocké et récupère l'utilisateur associé.
  /// Injecte directement l'utilisateur dans AppState : chaque compte
  /// n'accède qu'à son propre espace (pas de sélecteur de profil).
  Future<UserModel?> _checkLoginStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) return null;

    final userData = await _authService.getUserData();
    if (userData == null) return null;

    final user = UserModel(
      id: userData['userId'],
      name: userData['name'],
      email: userData['email'],
      role: userData['role'],
    );

    if (mounted) {
      context.read<AppState>().selectUser(user);
    }
    return user;
  }

  void _handleAuthSuccess(UserModel user) {
    context.read<AppState>().selectUser(user);
    setState(() {
      _initialUser = Future.value(user);
    });
  }

  void _handleLogout() {
    _authService.logout();
    context.read<AppState>().logout();
    setState(() {
      _initialUser = Future.value(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مقرأة',
      debugShowCheckedModeBanner: false,
      // Arabic UI, RTL layout throughout (matches ticket: full Arabic + RTL).
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(kPrimaryColor),
          brightness: Brightness.dark,
          surface: const Color(kSurfaceColor),
        ),
        scaffoldBackgroundColor: const Color(kBackgroundColor),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: const Color(kSurfaceColor),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(kPrimaryColor),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(kSurfaceColor),
          foregroundColor: Color(kTextPrimaryColor),
          elevation: 0,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: const Color(kTextPrimaryColor),
              displayColor: const Color(kTextPrimaryColor),
            ),
      ),
      home: FutureBuilder<UserModel?>(
        future: _initialUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // Utilisateur authentifié → directement dans son espace
            return ClassesScreen(onLogout: _handleLogout);
          } else {
            // Pas de session valide → écran d'authentification
            return AuthScreen(onAuthSuccess: _handleAuthSuccess);
          }
        },
      ),
    );
  }
}
