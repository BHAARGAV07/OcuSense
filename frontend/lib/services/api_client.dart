import 'dart:async';
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

typedef TokenRefreshCallback = Future<String?> Function();
typedef OnUnauthenticatedCallback = void Function();

class ApiClient {
  final http.Client _client;
  String? _authToken;
  TokenRefreshCallback? _onRefreshToken;
  OnUnauthenticatedCallback? _onUnauthenticated;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setAuthHandlers({
    TokenRefreshCallback? onRefreshToken,
    OnUnauthenticatedCallback? onUnauthenticated,
  }) {
    _onRefreshToken = onRefreshToken;
    _onUnauthenticated = onUnauthenticated;
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

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool isAuthEndpoint = false,
    bool isRetry = false,
  }) async {
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
      return await _processResponse(
        response,
        onRetry: isRetry || isAuthEndpoint || _authToken == null || _authToken!.isEmpty
            ? null
            : () => get(endpoint, headers: headers, queryParams: queryParams, isAuthEndpoint: isAuthEndpoint, isRetry: true),
      );
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } on TimeoutException {
      throw ApiException(0, 'Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Request failed: $e');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool isAuthEndpoint = false,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final payload = body != null ? jsonEncode(body) : null;

    if (kDebugMode) {
      print('🌐 [POST] $uri | Body: $payload');
    }

    try {
      final response = await _client
          .post(uri, headers: _buildHeaders(extraHeaders: headers), body: payload)
          .timeout(ApiConfig.timeoutDuration);
      return await _processResponse(
        response,
        onRetry: isRetry || isAuthEndpoint || _authToken == null || _authToken!.isEmpty
            ? null
            : () => post(endpoint, body: body, headers: headers, isAuthEndpoint: isAuthEndpoint, isRetry: true),
      );
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } on TimeoutException {
      throw ApiException(0, 'Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Request failed: $e');
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    bool isAuthEndpoint = false,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final payload = body != null ? jsonEncode(body) : null;

    if (kDebugMode) {
      print('🌐 [PATCH] $uri | Body: $payload');
    }

    try {
      final response = await _client
          .patch(uri, headers: _buildHeaders(extraHeaders: headers), body: payload)
          .timeout(ApiConfig.timeoutDuration);
      return await _processResponse(
        response,
        onRetry: isRetry || isAuthEndpoint || _authToken == null || _authToken!.isEmpty
            ? null
            : () => patch(endpoint, body: body, headers: headers, isAuthEndpoint: isAuthEndpoint, isRetry: true),
      );
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } on TimeoutException {
      throw ApiException(0, 'Request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Request failed: $e');
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool isAuthEndpoint = false,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    if (kDebugMode) {
      print('🌐 [DELETE] $uri');
    }

    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders(extraHeaders: headers))
          .timeout(ApiConfig.timeoutDuration);
      return await _processResponse(
        response,
        onRetry: isRetry || isAuthEndpoint || _authToken == null || _authToken!.isEmpty
            ? null
            : () => delete(endpoint, headers: headers, isAuthEndpoint: isAuthEndpoint, isRetry: true),
      );
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } on TimeoutException {
      throw ApiException(0, 'Request timed out. Please try again.');
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
    bool isRetry = false,
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
      return await _processResponse(
        response,
        onRetry: isRetry
            ? null
            : () => uploadMultipart(
                  endpoint,
                  fileField: fileField,
                  fileBytes: fileBytes,
                  filename: filename,
                  mediaType: mediaType,
                  isRetry: true,
                ),
      );
    } on SocketException {
      throw ApiException(0, 'Network connection failure. Please check your network.');
    } on TimeoutException {
      throw ApiException(0, 'Upload timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Multipart upload failed: $e');
    }
  }

  Future<dynamic> _processResponse(
    http.Response response, {
    Future<dynamic> Function()? onRetry,
  }) async {
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
    }

    // Handle 401 Unauthorized with token refresh retry
    if (response.statusCode == 401 && onRetry != null && _onRefreshToken != null) {
      if (kDebugMode) {
        print('🔄 [401 Unauthorized] Attempting token refresh...');
      }
      final newToken = await _onRefreshToken!();
      if (newToken != null && newToken.isNotEmpty) {
        _authToken = newToken;
        return await onRetry();
      } else {
        _authToken = null;
        _onUnauthenticated?.call();
      }
    }

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
