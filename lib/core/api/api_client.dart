// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';

final storageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // On some Xiaomi devices, KeyStore can be slow/unreliable.
      // Resetting on error can prevent the app from being stuck.
      resetOnError: true,
    ),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(dio, ref.read(storageProvider)),
    LoggingInterceptor(),
  ]);

  return dio;
});

// ── Auth Interceptor ──────────────────────────────────────────────────────
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt token refresh
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final token =
              await _storage.read(key: AppConstants.keyAccessToken);
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {}
      // Refresh failed – clear tokens
      await _storage.deleteAll();
      handler.next(err);
    } else {
      handler.next(err);
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refresh =
          await _storage.read(key: AppConstants.keyRefreshToken);
      if (refresh == null) return false;
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = response.data as Map<String, dynamic>;
      await _storage.write(
          key: AppConstants.keyAccessToken, value: data['access_token']);
      if (data['refresh_token'] != null) {
        await _storage.write(
            key: AppConstants.keyRefreshToken, value: data['refresh_token']);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ── Logging Interceptor (dev only) ───────────────────────────────────────
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('→ [${options.method}] ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('← [${response.statusCode}] ${response.requestOptions.path}');
      return true;
    }());
    handler.next(response);
  }
}
