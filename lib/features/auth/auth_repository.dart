// lib/features/auth/auth_repository.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_service.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiServiceProvider),
    ref.watch(storageProvider),
  );
});

class AuthRepository {
  final ApiService _api;
  final FlutterSecureStorage _storage;

  AuthRepository(this._api, this._storage);

  Future<void> sendOtp({String? mobile, required String email}) async {
    await _api.sendOtp(mobile: mobile, email: email);
  }

  Future<void> resendOtp({required String email}) async {
    await _api.resendOtp(email: email);
  }

  Future<String> verifyOtp({required String email, required String otp}) async {
    final res = await _api.verifyOtp(email: email, otp: otp);
    final token = res['verify_token'] ?? res['token'];
    if (token == null) {
      throw const ApiException(message: 'Invalid OTP or missing verification token');
    }
    return token as String;
  }

  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final res = await _api.login(identifier: identifier, password: password);
    
    // Support both {user: ...} and {data: {user: ...}} or just {token: ..., user: ...}
    final data = res.containsKey('data') ? res['data'] as Map<String, dynamic> : res;
    
    final accessToken = data['access_token'] ?? res['access_token'];
    final refreshToken = data['refresh_token'] ?? res['refresh_token'];
    
    if (accessToken == null) {
      throw const ApiException(message: 'Invalid response from server: missing access token');
    }

    await _saveTokens(
      accessToken: accessToken as String,
      refreshToken: refreshToken as String?,
    );

    final userMap = (data['user'] ?? res['user']) as Map<String, dynamic>?;
    if (userMap == null) {
      throw const ApiException(message: 'Invalid response from server: missing user data');
    }

    final user = UserModel.fromJson(userMap);
    await _saveUser(user);
    return user;
  }

  Future<UserModel> register({
    required String name,
    required String mobile,
    required String verifyToken,
    required String password,
    required String passwordConfirmation,
    String? email,
    String? deviceId,
    String? deviceName,
  }) async {
    final res = await _api.register(
      name: name,
      mobile: mobile,
      verifyToken: verifyToken,
      password: password,
      passwordConfirmation: passwordConfirmation,
      email: email,
      deviceId: deviceId,
      deviceName: deviceName,
    );
    
    // Support the specific response structure from the Laravel snippet
    final accessToken = res['access_token'] ?? res['token'] ?? res['server_token'];
    
    await _saveTokens(
      accessToken: accessToken as String,
      refreshToken: res['refresh_token'] as String?,
    );
    
    final userMap = res['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userMap);
    await _saveUser(user);
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _storage.deleteAll();
  }

  // ── Forgot Password ───────────────────────────────────────────────────
  Future<void> sendForgotPasswordOtp(String email) async {
    await _api.sendForgotPasswordOtp(email);
  }

  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _api.verifyForgotPasswordOtp(email: email, otp: otp);
    final token = res['verify_token'];
    if (token == null) {
      throw const ApiException(message: 'Verification token missing');
    }
    return token as String;
  }

  Future<void> resetPassword({
    required String email,
    required String verifyToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _api.resetPassword(
      email: email,
      verifyToken: verifyToken,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  Future<UserModel?> getStoredUser() async {
    final json = await _storage.read(key: AppConstants.keyUser);
    if (json == null) return null;
    try {
      return UserModel.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token =
        await _storage.read(key: AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(
      {required String accessToken, String? refreshToken}) async {
    await _storage.write(
        key: AppConstants.keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(
          key: AppConstants.keyRefreshToken, value: refreshToken);
    }
  }

  Future<void> _saveUser(UserModel user) async {
    await _storage.write(
        key: AppConstants.keyUser, value: jsonEncode(user.toJson()));
  }
}

// ── Auth State ────────────────────────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated, authenticating }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> init() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final loggedIn = await repo.isLoggedIn();
      if (loggedIn) {
        final user = await repo.getStoredUser();
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      // If storage fails, we assume unauthenticated
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> sendOtp({String? mobile, required String email}) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating, error: null);
      await ref.read(authRepositoryProvider).sendOtp(mobile: mobile, email: email);
      state = state.copyWith(status: AuthStatus.unauthenticated); // Back to base state after success
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
      rethrow;
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating, error: null);
      await ref.read(authRepositoryProvider).resendOtp(email: email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
      rethrow;
    }
  }

  Future<String?> verifyOtp({required String email, required String otp}) async {
    try {
      state = state.copyWith(status: AuthStatus.authenticating, error: null);
      final token = await ref.read(authRepositoryProvider).verifyOtp(email: email, otp: otp);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return token;
    } on ApiException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
      return null;
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      print('DEBUG: Starting login for $identifier');
      state = state.copyWith(status: AuthStatus.authenticating, error: null);
      
      final res = await repo.login(identifier: identifier, password: password);
      print('DEBUG: API Response received: $res');

      state = AuthState(status: AuthStatus.authenticated, user: res);
      print('DEBUG: State updated to authenticated');
      return true;
    } catch (e, stack) {
      print('DEBUG: Login Error: $e');
      print('DEBUG: StackTrace: $stack');
      
      String message = 'Login failed';
      if (e is ApiException) {
        message = e.message;
      } else {
        message = e.toString();
      }
      
      state = AuthState(status: AuthStatus.unauthenticated, error: message);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String mobile,
    required String verifyToken,
    required String password,
    required String passwordConfirmation,
    String? email,
    String? deviceId,
    String? deviceName,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      state = state.copyWith(status: AuthStatus.authenticating, error: null);
      final user = await repo.register(
        name: name,
        mobile: mobile,
        verifyToken: verifyToken,
        password: password,
        passwordConfirmation: passwordConfirmation,
        email: email,
        deviceId: deviceId,
        deviceName: deviceName,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on ApiException catch (e) {
      state = AuthState(
          status: AuthStatus.unauthenticated, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    // 1. Update state immediately to trigger UI transitions
    state = const AuthState(status: AuthStatus.unauthenticated);
    
    // 2. Perform cleanup in background/parallel
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.logout();
    } catch (e) {
      print('Logout cleanup error: $e');
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
