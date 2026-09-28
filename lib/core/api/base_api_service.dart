import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'api_constants.dart';
import '../errors/api_exception.dart';
import '../errors/network_exception.dart';

/// Base API Service
///
/// Provides common functionality for all API services including
/// HTTP client setup, request execution, error handling, and logging.
class BaseApiService {
  final http.Client _httpClient;
  final Logger _logger;
  final Connectivity _connectivity;

  BaseApiService({
    http.Client? httpClient,
    Logger? logger,
    Connectivity? connectivity,
  }) : _httpClient = httpClient ?? http.Client(),
       _logger = logger ?? Logger(),
       _connectivity = connectivity ?? Connectivity();

  /// Executes an HTTP GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    return _executeRequest(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
    );
  }

  /// Executes an HTTP POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
  }) async {
    return _executeRequest(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      body: body,
    );
  }

  /// Executes an HTTP PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
  }) async {
    return _executeRequest(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      body: body,
    );
  }

  /// Executes an HTTP DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    return _executeRequest(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
    );
  }

  /// Executes the HTTP request with proper error handling
  Future<Map<String, dynamic>> _executeRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
  }) async {
    // Check network connectivity
    await _checkConnectivity();

    // Build the complete URL
    final uri = _buildUri(endpoint, queryParams);

    // Log the final resolved URL for debugging
    final logUri = uri.replace(query: '', fragment: '');
    _logger.d('Final resolved URL: $logUri');

    // Merge headers
    final requestHeaders = {
      ...ApiConstants.defaultHeaders,
      if (headers != null) ...headers,
    };

    // Log the request
    _logger.i('[$method] $logUri');
    if (body != null) {
      _logger.d('Request Body: ${jsonEncode(body)}');
    }

    try {
      http.Response response;

      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await _httpClient.put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: requestHeaders);
          break;
        default:
          throw ApiException(
            message: 'Unsupported HTTP method: $method',
            code: 0,
          );
      }

      // Log the response
      _logger.d('Response Status: ${response.statusCode}');
      // Responses may contain location or other private data.

      // Handle the response
      return _handleResponse(response);
    } on SocketException catch (e) {
      _logger.e('SocketException occurred: $e');
      // More specific error handling based on exception type
      if (e.osError?.errorCode == 110) {
        // ETIMEDOUT
        throw const NetworkException.timeout();
      } else {
        throw const NetworkException.noInternet();
      }
    } on HandshakeException {
      _logger.e('SSL/TLS HandshakeException occurred');
      throw const NetworkException.sslError();
    } on FormatException {
      _logger.e('FormatException: Invalid JSON response');
      throw ApiException(message: 'Invalid response format', code: 0);
    } on TimeoutException {
      _logger.e('TimeoutException: Request timed out');
      throw const NetworkException.timeout();
    } catch (e) {
      _logger.e('API Request failed: $e');
      rethrow;
    }
  }

  /// Builds the complete URI with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final uri = Uri.parse(
      endpoint.startsWith('http')
          ? endpoint
          : '${ApiConstants.baseUrl}$endpoint',
    );

    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: uri.path,
      queryParameters: queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  /// Handles the HTTP response and converts it to a Map
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return {};
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw ApiException(message: 'Invalid JSON response', code: 0);
      }
    } else {
      throw ApiException.fromResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  /// Checks network connectivity
  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _logger.d('Connectivity status: $result');

    if (result == ConnectivityResult.none) {
      _logger.e('No network connectivity detected');
      throw const NetworkException.noInternet();
    }

    // Also check for mobile/cellular data if needed
    if ([ConnectivityResult.mobile, ConnectivityResult.wifi].contains(result)) {
      _logger.d('Valid network connection available');
    } else {
      _logger.w('Limited connectivity: $result');
    }
  }

  /// Closes the HTTP client
  void close() {
    _httpClient.close();
  }
}
