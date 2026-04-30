import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CompanyListScreen.dart';
import 'AppColors.dart';
import 'LoginScreen.dart';
import 'OtpScreen.dart';
import 'TrastedScreen.dart';
import 'HomePage.dart';
import 'controller/api/api_service.dart';
import 'connect/ChatScreen.dart';
import 'controller/stateBloc/LoginBloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = true;

  void toggleTheme(bool value) {
    setState(() {
      isDark = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => LoginBloc())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/login': (context) =>
              LoginScreen(isDark: isDark, onThemeChange: toggleTheme),
          '/otp': (context) =>
              OtpScreen(isDark: isDark, onThemeChange: toggleTheme),
          '/company': (context) =>
              CompanyListScreen(isDark: isDark, onThemeChange: toggleTheme),
          '/home': (context) =>
              HomePage(isDark: isDark, onThemeChange: toggleTheme),
          '/chat': (context) => ChatScreen(isDark: isDark),
        },
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    ApiServer.init(); // Initialize ApiServer to load token
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigate(); // Call navigate after ApiServer init
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('islogin') ?? false;

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isLoggedIn && ApiServer.token != null) {
      // Check both SharedPreferences flag and ApiServer's token
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030915),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF052874), Color(0xFF030915)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            FadeTransition(
              opacity: _animation,
              child: Image.asset('assets/logo.webp', width: 220),
            ),
            const Spacer(),
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
