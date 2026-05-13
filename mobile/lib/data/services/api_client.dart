import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = path.startsWith('http')
        ? path
        : '${ApiConfig.apiUrl}${path.startsWith('/') ? path : '/$path'}';
    final uri = Uri.parse(base);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .get(_uri(path, query), headers: _headers(json: false))
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on SocketException catch (e) {
      throw ApiException('Connexion impossible: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Délai dépassé');
    }
  }

  Future<dynamic> post(String path, {Object? body}) async {
    try {
      final res = await http
          .post(
            _uri(path),
            headers: _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on SocketException catch (e) {
      throw ApiException('Connexion impossible: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Délai dépassé');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await http
          .delete(_uri(path), headers: _headers(json: false))
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on SocketException catch (e) {
      throw ApiException('Connexion impossible: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Délai dépassé');
    }
  }

  Future<dynamic> uploadFile(
    String path, {
    required String filePath,
    required String filename,
    required Map<String, String> fields,
    String fileField = 'file',
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri(path));
      request.headers.addAll(_headers(json: false));
      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath(fileField, filePath, filename: filename),
      );
      final streamed = await request.send().timeout(ApiConfig.uploadTimeout);
      final res = await http.Response.fromStream(streamed);
      return _decode(res);
    } on SocketException catch (e) {
      throw ApiException('Connexion impossible: ${e.message}');
    } on TimeoutException {
      throw const ApiException('Délai dépassé pendant le téléversement');
    }
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        body = res.body;
      }
    }
    if (!ok) {
      final detail = body is Map && body['detail'] != null
          ? body['detail'].toString()
          : (body?.toString() ?? 'Erreur HTTP ${res.statusCode}');
      throw ApiException(detail, statusCode: res.statusCode);
    }
    return body;
  }

  Future<bool> isHealthy() async {
    try {
      final data = await get('/health');
      return data is Map && data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }
}
