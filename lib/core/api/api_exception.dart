// lib/core/api/api_exception.dart
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
            message: 'Connection timed out. Please try again.',
            statusCode: 408);
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        String msg = 'Something went wrong';
        
        if (code == 401) {
          msg = 'Your session has expired. Please login again.';
        } else if (data is Map<String, dynamic>) {
          msg = data['message'] as String? ?? msg;
        }
        
        return ApiException(message: msg, statusCode: code, errors: data is Map ? data['errors'] : null);
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      case DioExceptionType.connectionError:
        return const ApiException(
            message: 'No internet connection.', statusCode: 0);
      default:
        return ApiException(
            message: e.message ?? 'Unexpected error occurred.');
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
