import 'package:dio/dio.dart';
import 'package:rasht/src/rasht_config.dart';
import 'package:rasht/src/rasht_log_entry.dart';
import 'package:rasht/src/rasht_store.dart';

class RashtInterceptor extends Interceptor {
  RashtInterceptor(this.store, {this.enabled});

  final RashtStore store;

  /// When null, uses [Rasht.enabled].
  final bool? enabled;

  static const _logIdKey = 'rasht_log_id';
  int _counter = 0;

  bool get _isActive => enabled ?? Rasht.enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isActive) {
      handler.next(options);
      return;
    }

    final id = '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
    options.extra[_logIdKey] = id;

    store.addEntry(
      RashtLogEntry(
        id: id,
        startedAt: DateTime.now(),
        method: options.method.toUpperCase(),
        url: options.uri.toString(),
        queryParameters: options.queryParameters.isEmpty
            ? null
            : Map<String, dynamic>.from(options.queryParameters),
        requestBody: options.data,
        requestHeaders: options.headers.isEmpty
            ? null
            : Map<String, dynamic>.from(options.headers),
      ),
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!_isActive) {
      handler.next(response);
      return;
    }

    final id = response.requestOptions.extra[_logIdKey]?.toString();
    if (id != null) {
      store.completeEntry(
        id: id,
        statusCode: response.statusCode,
        responseBody: response.data,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_isActive) {
      handler.next(err);
      return;
    }

    final id = err.requestOptions.extra[_logIdKey]?.toString();
    if (id != null) {
      store.failEntry(
        id: id,
        statusCode: err.response?.statusCode,
        responseBody: err.response?.data,
        errorMessage: err.message ?? err.type.name,
      );
    }
    handler.next(err);
  }
}
