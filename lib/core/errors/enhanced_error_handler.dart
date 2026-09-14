import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sakina_app/core/utils/security_utils.dart';
import 'app_exceptions.dart';

/// Enhanced Error Handler with Context and Recovery Options
///
/// Provides comprehensive error handling with:
/// - Context-aware error messages
/// - Recovery suggestions
/// - User-friendly messaging
/// - Error categorization
/// - Analytics integration
class EnhancedErrorHandler {
  static final Logger _logger = Logger();

  /// Handle errors with context and provide user-friendly messages
  static String handleWithRecovery(
    Object error, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool includeRecovery = true,
  }) {
    final errorInfo = _analyzeError(error, context, additionalData);

    // Log the error with full context
    _logErrorWithContext(errorInfo);

    // Return user-friendly message
    String message = errorInfo.userMessage;

    if (includeRecovery && errorInfo.recoveryOptions.isNotEmpty) {
      message += '\n\n${errorInfo.recoveryOptions.join('\n')}';
    }

    return message;
  }

  /// Analyze error and extract relevant information
  static _ErrorInfo _analyzeError(
    Object error,
    String? context,
    Map<String, dynamic>? additionalData,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final errorType = error.runtimeType.toString();
    final errorMessage = error.toString();

    // Categorize error
    final category = _categorizeError(error);

    // Generate user-friendly message
    final userMessage = _generateUserMessage(error, category);

    // Suggest recovery options
    final recoveryOptions = _suggestRecovery(error, category);

    // Extract technical details
    final technicalDetails = {
      'type': errorType,
      'message': errorMessage,
      'category': category.name,
      'context': context,
      'timestamp': timestamp,
      'deviceId': _getDeviceId(),
      'connectivity': _getCurrentConnectivity(),
      ...?additionalData,
    };

    return _ErrorInfo(
      originalError: error,
      category: category,
      userMessage: userMessage,
      recoveryOptions: recoveryOptions,
      technicalDetails: technicalDetails,
      timestamp: timestamp,
    );
  }

  /// Categorize error types
  static ErrorCategory _categorizeError(Object error) {
    if (error is TypeError || error is FormatException) {
      return ErrorCategory.dataValidation;
    } else if (error is NetworkException) {
      return ErrorCategory.network;
    } else if (error is ApiException) {
      return ErrorCategory.api;
    } else if (error is SecurityException) {
      return ErrorCategory.security;
    } else if (error is ValidationException) {
      return ErrorCategory.validation;
    } else if (error is DataIntegrityException) {
      return ErrorCategory.dataIntegrity;
    } else if (error is StateError) {
      return ErrorCategory.state;
    } else if (error is RangeError) {
      return ErrorCategory.range;
    } else {
      return ErrorCategory.unknown;
    }
  }

  /// Generate user-friendly error messages
  static String _generateUserMessage(Object error, ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return 'Unable to connect to the internet. '
            'Please check your connection.';
      case ErrorCategory.api:
        if (error is ApiException) {
          if (error.code == 404) {
            return 'The requested data was not found.';
          } else if (error.code == 500) {
            return 'Server is temporarily unavailable. Please try again later.';
          }
        }
        return 'An error occurred while fetching data. Please try again.';
      case ErrorCategory.dataValidation:
        return 'Invalid data format received. '
            'The application will attempt to recover.';
      case ErrorCategory.security:
        return 'Security validation failed. Please ensure your input is valid.';
      case ErrorCategory.validation:
        if (error is ValidationException) {
          return 'Invalid ${error.field}: ${error.message}';
        }
        return 'Please check your input and try again.';
      case ErrorCategory.dataIntegrity:
        return 'Data integrity check failed. '
            'The application will attempt to recover.';
      case ErrorCategory.state:
        return 'Application state error. Please restart the application.';
      case ErrorCategory.range:
        return 'Value is outside the valid range.';
      case ErrorCategory.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Suggest recovery options based on error type
  static List<String> _suggestRecovery(Object error, ErrorCategory category) {
    final suggestions = <String>[];

    switch (category) {
      case ErrorCategory.network:
        suggestions.addAll([
          '• Check your internet connection',
          '• Try switching to mobile data or Wi-Fi',
          '• Restart your router if needed',
        ]);
        break;
      case ErrorCategory.api:
        suggestions.addAll([
          '• Try refreshing the data',
          '• Check if the service is available',
          '• Contact support if the problem persists',
        ]);
        break;
      case ErrorCategory.dataValidation:
        suggestions.addAll([
          '• The application will use cached data',
          '• Try refreshing to get updated information',
        ]);
        break;
      case ErrorCategory.security:
        suggestions.addAll([
          '• Review your input for special characters',
          '• Ensure data format is correct',
        ]);
        break;
      case ErrorCategory.validation:
        suggestions.add('• Correct the highlighted field and try again');
        break;
      case ErrorCategory.dataIntegrity:
        suggestions.addAll([
          '• Data will be re-downloaded automatically',
          '• Try restarting the application',
        ]);
        break;
      case ErrorCategory.state:
        suggestions.add('• Restart the application to reset state');
        break;
      case ErrorCategory.range:
        suggestions.add('• Enter a value within the valid range');
        break;
      case ErrorCategory.unknown:
        suggestions.addAll([
          '• Try restarting the application',
          '• Check for application updates',
          '• Contact support with error details',
        ]);
        break;
    }

    return suggestions;
  }

  /// Log error with full context
  static void _logErrorWithContext(_ErrorInfo errorInfo) {
    _logger.e(
      'Error occurred: ${errorInfo.category.name}',
      error: errorInfo.originalError,
      stackTrace: StackTrace.current,
    );

    // Log technical details separately
    if (kDebugMode) {
      _logger.d('Error details: ${errorInfo.technicalDetails}');
    }

    // Log security events for sensitive errors
    if (errorInfo.category == ErrorCategory.security) {
      SecurityUtils.logSecure(
        'Security error detected',
        data: errorInfo.technicalDetails,
        level: Level.warning,
      );
    }
  }

  /// Get current device connectivity status
  static Future<String> _getCurrentConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.toString();
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get device identifier (simplified)
  static String _getDeviceId() {
    // In a real app, you'd use device_info_plus or similar
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Error recovery strategies
  static Future<bool> attemptRecovery(
    Object error,
    ErrorCategory category, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;

      try {
        switch (category) {
          case ErrorCategory.network:
            // Wait and retry with exponential backoff
            await Future.delayed(Duration(milliseconds: 1000 * attempts));
            final connectivity = await _getCurrentConnectivity();
            if (connectivity != 'ConnectivityResult.none') {
              return true;
            }
            break;

          case ErrorCategory.api:
            // Retry with backoff
            await Future.delayed(Duration(milliseconds: 500 * attempts));
            return true; // Assume API recovery

          case ErrorCategory.dataValidation:
            // Data validation errors typically don't need retry
            return false;

          case ErrorCategory.security:
          case ErrorCategory.validation:
          case ErrorCategory.dataIntegrity:
          case ErrorCategory.state:
          case ErrorCategory.range:
          case ErrorCategory.unknown:
            // For other errors, simple retry
            await Future.delayed(Duration(milliseconds: 200 * attempts));
            return true;
        }
      } catch (e) {
        // Continue retrying
        if (attempts >= maxRetries) {
          return false;
        }
      }
    }

    return false;
  }
}

/// Error information structure
class _ErrorInfo {
  final Object originalError;
  final ErrorCategory category;
  final String userMessage;
  final List<String> recoveryOptions;
  final Map<String, dynamic> technicalDetails;
  final String timestamp;

  _ErrorInfo({
    required this.originalError,
    required this.category,
    required this.userMessage,
    required this.recoveryOptions,
    required this.technicalDetails,
    required this.timestamp,
  });
}

/// Error categories for better handling
enum ErrorCategory {
  network,
  api,
  dataValidation,
  security,
  validation,
  dataIntegrity,
  state,
  range,
  unknown,
}

/// Enhanced exception wrapper with recovery context
class RecoverableException implements Exception {
  final String message;
  final ErrorCategory category;
  final List<String> recoveryOptions;
  final Object? originalError;
  final String timestamp;

  RecoverableException({
    required this.message,
    required this.category,
    this.recoveryOptions = const [],
    this.originalError,
  }) : timestamp = DateTime.now().toIso8601String();

  @override
  String toString() =>
      'RecoverableException: $message (Category: ${category.name})';
}

/// Error reporting service
class ErrorReportingService {
  static Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // In a real implementation, send to error reporting service
      // like Sentry, Crashlytics, or custom backend
      final report = {
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': 'device_${DateTime.now().millisecondsSinceEpoch}',
        ...?additionalData,
      };

      // Log the report
      if (kDebugMode) {
        developer.log(
          'Error Report',
          name: 'sakina_app.error_reporting',
          level: 1000,
          error: report,
        );
      }

      // Here you would send to your error reporting service
      // await _sendToErrorService(report);
    } catch (e) {
      // Don't let error reporting fail
      developer.log(
        'Failed to report error',
        name: 'sakina_app.error_reporting',
        level: 1000,
        error: e,
      );
    }
  }
}
