import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freeli/connect/AllFlagged/AllFlaggedMessage.dart';
import 'package:freeli/connect/All_Notification/All_Notification.dart';
import 'package:freeli/connect/ChangePassword/ChangePassword.dart';
import 'package:freeli/connect/ReplyScreen.dart';
import 'package:freeli/connect/archiveroom/archiveroom.dart';
import 'package:freeli/connect/filehubs/filehubs.dart';
import 'package:freeli/connect/filehubs_Room/RoomFilehubs.dart';
import 'package:freeli/connect/swichAccount/SwitchAccount.dart';
import 'package:freeli/theme/themeList.dart';
import 'package:freeli/theme/ThemeCubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CompanyListScreen.dart';
import 'LoginScreen.dart';
import 'OtpScreen.dart';
import 'HomePage.dart';
import 'controller/api/api_service.dart';
import 'controller/stateBloc/message/chat_bloc.dart';
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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoginBloc()),
        BlocProvider(create: (_) => ChatBloc()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeModel>(
        builder: (context, appTheme) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashPage(),
              '/login': (context) => const LoginScreen(),
              '/otp': (context) => const OtpScreen(),
              '/company': (context) => const CompanyListScreen(),
              '/home': (context) => const HomePage(),
              '/chat': (context) => const ChatScreen(),
              '/filehuball': (context) => const Filehubs(),
              '/filehubRoom': (context) => const RoomFilehubs(),
              '/archiveroom': (context) => const ArchiveRoom(),
              '/changepassword': (context) => const ChangePassword(),
              '/allFlaggedMessage': (context) =>
                  AllFlaggedMessage(isDark: true, onThemeChange: (val) {}),
              '/switchAccount': (context) => const SwitchAccount(),
              '/replyScreen': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map?;
                return ReplyScreen(
                  messageid: args?['messageid'] ?? "",
                  msg: args?['msg'] ?? {},
                  companyId: args?['company_id'],
                  participants: args?['participants'],
                );
              },
              '/allnotification': (context) =>
                  AllNotificationPage(isDark: true, onThemeChange: (val) {}),
            },
          );
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
    return BlocBuilder<ThemeCubit, AppThemeModel>(
      builder: (context, appTheme) {
        return Scaffold(
          backgroundColor: appTheme.backgroundColor,
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  appTheme.accentColor.withOpacity(0.8),
                  appTheme.backgroundColor,
                ],
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
      },
    );
  }
}
