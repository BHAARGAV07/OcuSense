import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, [this.body]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers, Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    if (kDebugMode) {
      print('🌐 [GET] $uri');
    }

    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(extraHeaders: headers))
          .timeout(ApiConfig.timeoutDuration);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Request failed: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final payload = body != null ? jsonEncode(body) : null;

    if (kDebugMode) {
      print('🌐 [POST] $uri | Body: $payload');
    }

    try {
      final response = await _client
          .post(uri, headers: _buildHeaders(extraHeaders: headers), body: payload)
          .timeout(ApiConfig.timeoutDuration);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Request failed: $e');
    }
  }

  Future<dynamic> patch(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final payload = body != null ? jsonEncode(body) : null;

    if (kDebugMode) {
      print('🌐 [PATCH] $uri | Body: $payload');
    }

    try {
      final response = await _client
          .patch(uri, headers: _buildHeaders(extraHeaders: headers), body: payload)
          .timeout(ApiConfig.timeoutDuration);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Request failed: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    if (kDebugMode) {
      print('🌐 [DELETE] $uri');
    }

    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders(extraHeaders: headers))
          .timeout(ApiConfig.timeoutDuration);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Request failed: $e');
    }
  }

  Future<dynamic> uploadMultipart(
    String endpoint, {
    required String fileField,
    required List<int> fileBytes,
    required String filename,
    String? mediaType,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    if (_authToken != null && _authToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename,
      ),
    );

    if (kDebugMode) {
      print('🌐 [MULTIPART POST] $uri | File: $filename (${fileBytes.length} bytes)');
    }

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Multipart upload failed: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (kDebugMode) {
      print('📥 Status [${response.statusCode}] | Response: ${response.body}');
    }

    dynamic responseData;
    try {
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body);
      }
    } catch (_) {
      responseData = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      String msg = 'An unexpected server error occurred (${response.statusCode})';
      if (responseData is Map && responseData.containsKey('detail')) {
        final detail = responseData['detail'];
        if (detail is String) {
          msg = detail;
        } else if (detail is List) {
          msg = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
      }
      throw ApiException(response.statusCode, msg, responseData);
    }
  }
}
