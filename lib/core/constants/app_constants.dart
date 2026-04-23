// lib/core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  // ── API ──────────────────────────────────────────────────────────────
  // static const String baseUrl = 'http://10.0.2.2:8001/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8001/api'; // iOS Simulator
  static const String baseUrl = 'http://16.171.77.217/api'; // Production Server


  static const int connectTimeout = 60000;
  static const int receiveTimeout = 120000;

  // ── Razorpay ─────────────────────────────────────────────────────────
  static const String razorpayKeyId = 'rzp_test_SefhzMBQhj3WsM'; // REPLACE THIS WITH YOUR REAL KEY
  static const String razorpayKeySecret = ''; // Never store in app!
  static const int semesterPrice = 7500; // in paise (₹75)
  static const String currency = 'INR';
  static const String companyName = 'YD APP';

  // ── Subscription ─────────────────────────────────────────────────────
  static const int subscriptionMonths = 6;
  static const int pdfPreviewPages = 3; // free preview page count

  // ── Secure Storage Keys ──────────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUser = 'user_data';
  static const String keySelectedUniversity = 'selected_university';
  static const String keySelectedLanguage = 'selected_language';

  // ── SharedPrefs Keys ─────────────────────────────────────────────────
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefLanguage = 'app_language';
  static const String prefTheme = 'app_theme';

  // ── Languages ────────────────────────────────────────────────────────
  static const String langEnglish = 'en';
  static const String langGujarati = 'gu';

  // ── Links ─────────────────────────────────────────────────────────────
  static const String _webBaseUrl = 'http://10.0.2.2:8001'; 

  static const String privacyPolicyUrl = '$_webBaseUrl/privacy-policy';
  static const String termsConditionsUrl = '$_webBaseUrl/terms-and-conditions';
  static const String helpSupportUrl = '$_webBaseUrl/support';
  static const String supportEmail = 'support@ydapp.in';

  // ── Regex ─────────────────────────────────────────────────────────────
  static final RegExp emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp phoneRegex = RegExp(r'^[6-9]\d{9}$');
  static final RegExp passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
}
