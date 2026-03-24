import 'dart:developer' as dev;
import 'package:dio/dio.dart';

/// Maps exceptions to user-friendly messages. Logs full details to console.
String mapErrorToMessage(Object error) {
  dev.log('Error: $error', name: 'ErrorMapper');

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'Unable to connect to server. Check your internet connection.';
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        // Try to extract server message
        if (data is Map<String, dynamic> && data['message'] != null) {
          return data['message'] as String;
        }
        return switch (statusCode) {
          400 => 'Invalid request. Please check your input.',
          401 => 'Invalid credentials.',
          403 => 'Access denied.',
          404 => 'Not found.',
          409 => 'This phone number is already registered.',
          500 => 'Server error. Please try again later.',
          _ => 'Something went wrong. Please try again.',
        };
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Security error. Please try again later.';
      case DioExceptionType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  return 'Something went wrong. Please try again.';
}
