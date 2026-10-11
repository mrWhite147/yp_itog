import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override String toString() => message;
}

class NetworkException extends ApiException { const NetworkException([super.m = 'Сервер недоступен. Проверьте соединение.']); }
class UnauthorizedException extends ApiException { const UnauthorizedException([super.m = 'Требуется вход в систему.']); }
class ForbiddenException extends ApiException { const ForbiddenException([super.m = 'Недостаточно прав.']); }
class NotFoundException extends ApiException { const NotFoundException([super.m = 'Запись не найдена.']); }
class ConflictException extends ApiException { const ConflictException(super.m); }
class ServerException extends ApiException { const ServerException([super.m = 'Ошибка сервера. Попробуйте позже.']); }

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

ApiException mapHttpError(int status, dynamic body) {
  final msg = (body is Map && body['message'] is String) ? body['message'] as String : null;

  if (status == 400 && body is Map && body['data'] is Map) {
    final errs = (body['data'] as Map).map((k, v) {
      final fieldMsg = (v is Map && v['message'] != null) ? v['message'].toString() : v.toString();
      return MapEntry('$k', fieldMsg);
    });
    return ValidationException('Ошибка валидации', errs);
  }

  return switch (status) {
    400 => ValidationException(msg ?? 'Некорректные данные', const {}),
    401 => UnauthorizedException(msg ?? 'Требуется авторизация.'),
    403 => ForbiddenException(msg ?? 'Недостаточно прав для выполнения действия.'),
    404 => NotFoundException(msg ?? 'Запись не найдена.'),
    409 => ConflictException(msg ?? 'Конфликт данных. Операция невозможна.'),
    422 => ValidationException('Ошибка валидации', const {}), 
    _ => ServerException(msg ?? 'Неизвестная ошибка сервера (Код $status).'),
  };
}

ApiException mapDioError(DioException e) {
  final existing = e.error;
  if (existing is ApiException) return existing;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException('Сервер не ответил вовремя. Таймаут.'),
    DioExceptionType.connectionError => const NetworkException('Не удалось соединиться с сервером. Возможно, ошибка CORS или сервер выключен.'),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}