import 'package:dio/dio.dart';
import 'package:test_project/globals.dart';


class Client {
  
  static final Client _instance = Client._();

  final Dio _dio;

  Client._() : _dio = Dio(
    BaseOptions(
      baseUrl: domain,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  factory Client() => _instance;

  Dio get dio => _dio;

  void setHeadersContentTypeJson() {
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  void clearAuthorizationHeader() {
    _dio.options.headers.remove('Authorization');
  }
  
}