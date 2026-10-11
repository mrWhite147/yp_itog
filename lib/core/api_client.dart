import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_exceptions.dart';
import '../state/auth_notifier.dart';

Dio buildDio({required AuthNotifier Function() getAuth}) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => status != null && status < 500,
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (opts, handler) {
      final token = getAuth().token;
      if (token != null) {
        opts.headers['Authorization'] = 'Bearer $token';
      }
      if (kDebugMode) debugPrint('[API REQ] ${opts.method} ${opts.uri}');
      return handler.next(opts);
    },
    onResponse: (res, handler) {
      if (kDebugMode) debugPrint('[API RES] ${res.statusCode} ${res.requestOptions.uri}');
      final status = res.statusCode ?? 0;
      
      if (status >= 400) {
        return handler.reject(
          DioException(
            requestOptions: res.requestOptions, 
            response: res,
            type: DioExceptionType.badResponse, 
            error: mapHttpError(status, res.data),
          ), 
          true
        );
      }
      return handler.next(res);
    },
    onError: (err, handler) async {
      if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth-with-password')) {
        try {
          final auth = getAuth();
          await auth.refreshTokens();
          err.requestOptions.headers['Authorization'] = 'Bearer ${auth.token}';
          final cloneReq = await dio.fetch(err.requestOptions);
          return handler.resolve(cloneReq);
        } catch (_) {
          await getAuth().logout();
        }
      }

      if (err.requestOptions.method == 'GET' && err.type != DioExceptionType.cancel && err.response == null) {
        int retries = err.requestOptions.extra['retries'] ?? 0;
        if (retries < 3) {
          if (kDebugMode) debugPrint('[API RETRY] Попытка ${retries + 1} для ${err.requestOptions.uri}');
          await Future.delayed(Duration(milliseconds: 500 * (retries + 1)));
          err.requestOptions.extra['retries'] = retries + 1;
          try {
            final res = await dio.fetch(err.requestOptions);
            return handler.resolve(res);
          } catch (_) {}
        }
      }
      
      if (kDebugMode) debugPrint('[API ERR] ${err.type} - ${err.message}');
      return handler.next(err);
    },
  ));

  return dio;
}