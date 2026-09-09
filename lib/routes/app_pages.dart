import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/dashboard/dasboard_page.dart';
import 'package:flutter_application_2/screens/auth/register_page.dart';
import 'package:go_router/go_router.dart';
import '../splash/splash_screen.dart';
import '../screens/auth/login_page.dart';

import 'app_routes.dart';

class AppPages {
  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      )
    ],
  );
}
