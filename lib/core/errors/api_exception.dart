import 'app_exception.dart';

class ApiException extends AppException {
  final int? statusCode;

  const ApiException(super.message, {this.statusCode, super.code});

  factory ApiException.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ApiException(message ?? 'Bad request', statusCode: statusCode, code: 'bad_request');
      case 401:
        return ApiException(message ?? 'Unauthorized', statusCode: statusCode, code: 'unauthorized');
      case 403:
        return ApiException(message ?? 'Forbidden', statusCode: statusCode, code: 'forbidden');
      case 404:
        return ApiException(message ?? 'Not found', statusCode: statusCode, code: 'not_found');
      case 409:
        return ApiException(message ?? 'Conflict', statusCode: statusCode, code: 'conflict');
      case 500:
        return ApiException(message ?? 'Server error', statusCode: statusCode, code: 'server_error');
      default:
        return ApiException(message ?? 'Unknown error', statusCode: statusCode);
    }
  }
}
