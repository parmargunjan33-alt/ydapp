// lib/core/api/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'api_exception.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

class ApiService {
  final Dio _dio;
  ApiService(this._dio);

  // ── Auth ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp({
    String? mobile,
    required String email,
  }) =>
      post('/auth/send-otp', data: {
        if (mobile != null) 'mobile': mobile,
        'email': email,
      });

  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) =>
      post('/auth/send-otp', data: {
        'email': email,
      });

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) =>
      post('/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });

  Future<Map<String, dynamic>> login({
    required String identifier, // email or phone
    required String password,
    String? deviceId,
    String? deviceName,
  }) {
    // Determine the key based on the input format
    final bool isEmail = identifier.contains('@');
    final Map<String, dynamic> loginData = {
      isEmail ? 'email' : 'mobile': identifier,
      'password': password,
      'device_id': deviceId ?? 'unknown_device',
      'device_name': deviceName ?? 'Android Device',
    };

    return post('/auth/login', data: loginData);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    required String verifyToken,
    required String password,
    required String passwordConfirmation,
    String? email,
    String? deviceId,
    String? deviceName,
  }) =>
      post('/auth/register', data: {
        'name': name,
        'mobile': mobile,
        'verify_token': verifyToken,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_id': deviceId,
        'device_name': deviceName,
      });

  Future<void> logout() => post('/auth/logout', data: {});

  Future<Map<String, dynamic>> getProfile() => get('/auth/profile');

  // ── Forgot Password ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) =>
      post('/forgot-password/send-otp', data: {'email': email});

  Future<Map<String, dynamic>> verifyForgotPasswordOtp(
          {required String email, required String otp}) =>
      post('/forgot-password/verify-otp', data: {'email': email, 'otp': otp});

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String verifyToken,
    required String password,
    required String passwordConfirmation,
  }) =>
      post('/forgot-password/reset', data: {
        'email': email,
        'verify_token': verifyToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

  Future<Map<String, dynamic>> getContactInfo() => get('/contact-info');

  // ── Universities ──────────────────────────────────────────────────────
  Future<List<dynamic>> getUniversities() async {
    final res = await get('/universities');
    final data = res['data'] ?? res['universities'] ?? res;
    return data is List ? data : [];
  }

  // ── Courses ───────────────────────────────────────────────────────────
  Future<List<dynamic>> getCourses(int universityId) async {
    final res = await get('/courses/$universityId');
    final data = res['data'] ?? res['courses'] ?? res;
    return data is List ? data : [];
  }

  // ── Semesters ─────────────────────────────────────────────────────────
  Future<List<dynamic>> getSemesters(int courseId) async {
    final res = await get('/semesters/$courseId');
    final data = res['data'] ?? res['semesters'] ?? res;
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getSemesterDetail(int semesterId) async {
    try {
      final res = await _dio.get('/semesters/$semesterId');
      // If the response is a List, wrap it or take first element
      // But standard detail route should be a Map.
      if (res.data is List) {
        if ((res.data as List).isNotEmpty) {
          return (res.data as List).first as Map<String, dynamic>;
        }
        return {};
      }
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Subjects ──────────────────────────────────────────────────────────
  Future<List<dynamic>> getSubjects(int semesterId) async {
    final res = await get('/subjects/$semesterId');
    final data = res['data'] ?? res['subjects'] ?? res;
    return data is List ? data : [];
  }

  Future<List<dynamic>> getPdfsBySubject({
    required int semesterId,
    required int subjectId,
  }) async {
    final res = await get('/pdfs/$semesterId/$subjectId');
    final data = res['data'] ?? res['pdfs'] ?? res;
    if (data is List) return data;
    return [];
  }

  // ── Old Papers ────────────────────────────────────────────────────────
  Future<List<dynamic>> getOldPapers(int semesterId) async {
    final res = await get('/papers/$semesterId');
    final data = res['data'] ?? res['papers'] ?? res;
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getPaperViewUrl(int paperId) =>
      get('/pdf/$paperId/url');

  // ── Subscriptions ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkSubscription(int semesterId) =>
      get('/subscription/$semesterId');

  Future<Map<String, dynamic>> getSubscriptionPrice() =>
      get('/payment/subscription-price');

  Future<Map<String, dynamic>> createOrder(int semesterId) =>
      post('/payment/create-order', data: {'semester_id': semesterId});

  Future<Map<String, dynamic>> verifyPayment({
    required int semesterId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) =>
      post('/payment/verify', data: {
        'semester_id': semesterId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      });

  Future<List<dynamic>> getMySubscriptions() async {
    final res = await get('/subscriptions/my');
    return res['data'] as List<dynamic>;
  }

  // ── Internals ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParams}) async {
    try {
      print('🌐 API GET: $path'); // Added this line
      final res = await _dio.get(path, queryParameters: queryParams);
      if (res.data is List) {
        return {'data': res.data};
      }
      if (res.data == null) return {};
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> post(String path,
      {required Map<String, dynamic> data}) async {
    try {
      final res = await _dio.post(path, data: data);
      if (res.data is List) {
        return {'data': res.data};
      }
      if (res.data == null) return {};
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      return {};
    }
  }
}
