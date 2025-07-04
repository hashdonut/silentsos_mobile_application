// lib/routes/routes.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'route_names.dart';
import '../screens/auth_gate.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/change_pin_screen.dart';
import '../screens/enterpinscreen.dart';
import '../screens/forgot_pin_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/calculator_disguise.dart';
import '../screens/verify_email_screen.dart';
import '../screens/helper_home_screen.dart';
import '../screens/helper_profile_screen.dart';
import '../screens/helper_settings_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? routeName = settings.name;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // Public routes
    switch (routeName) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case RouteNames.enterPin:
        return MaterialPageRoute(builder: (_) => const EnterPinScreen());
      case RouteNames.forgotPin:
        return MaterialPageRoute(builder: (_) => const ForgotPinScreen());
      case RouteNames.authGate:
        return MaterialPageRoute(builder: (_) => const AuthGate());
      case RouteNames.calculatorDisguise:
        return MaterialPageRoute(builder: (_) => const CalculatorDisguise());
      case RouteNames.verify:
        return MaterialPageRoute(builder: (_) => const VerifyEmailScreen());
    }

    // Protected routes
    if (_isProtectedRoute(routeName)) {
      if (!isLoggedIn) {
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      }
      return _buildProtectedRoute(routeName!);
    }

    // Fallback 404
    return _unknownRoute(routeName);
  }

  static bool _isProtectedRoute(String? name) {
    return [
      RouteNames.home,
      RouteNames.settings,
      RouteNames.changePin,
      RouteNames.faq,
      RouteNames.helperHome,
      RouteNames.helperProfile,
      RouteNames.helperSettings,
    ].contains(name);
  }

  static Route<dynamic> _buildProtectedRoute(String name) {
    switch (name) {
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case RouteNames.changePin:
        return MaterialPageRoute(builder: (_) => const ChangePinScreen());
      case RouteNames.faq:
        return MaterialPageRoute(builder: (_) => const FAQScreen());
      case RouteNames.helperHome:
        return MaterialPageRoute(builder: (_) => const HelperHomeScreen());
      case RouteNames.helperProfile:
        return MaterialPageRoute(builder: (_) => const HelperProfileScreen());
      case RouteNames.helperSettings:
        return MaterialPageRoute(builder: (_) => const HelperSettingsScreen());
      default:
        return _unknownRoute(name);
    }
  }

  static Route<dynamic> _unknownRoute(String? name) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("404: Not Found")),
        body: Center(
          child: Text(
            '⚠️ No route defined for "$name"',
            style: const TextStyle(fontSize: 16, color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
