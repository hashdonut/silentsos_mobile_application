// lib/routes/route_names.dart

class RouteNames {
  // ✅ Public
  static const String login = '/login';
  static const String signup = '/signup';
  static const String settings = '/settings';
  static const String faq = '/faq';
  static const String changePin = '/change-pin';
  static const verify = '/verify';
  static const authGate = '/'; // ✅ Needed for initial route
  static const String enterPin = '/enter-pin';
  static const forgotPin = '/forgot-pin';
  static const calculatorDisguise = '/calculator-disguise';
  static const String helperSettings = '/helperSettings';

  // 🔐 Protected
  static const String home = '/home';
  static const String profile = '/profile';
  static const String donate = '/donate';
  static const String alerts = '/alerts';
  static const String helperHome = '/helper-home';
  static const String helperProfile = '/helper-profile';
}
