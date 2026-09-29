import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import '../../../../../core/api/api_constants.dart';
import '../../../../../core/api/base_api_service.dart';
import '../../../../../core/api/api_logger.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/errors/network_exception.dart';
import '../models/prayer_times_response.dart';

/// Prayer Times API Service
///
/// Handles all Prayer Times-related API operations for the application.
/// This service fetches prayer times from the AlAdhan API
/// based on location and date.
class PrayerTimesApiService extends BaseApiService {
  static const String _timingsEndpoint = '/timings';

  /// Get prayer times for a specific date and location
  ///
  /// Parameters:
  /// - date: The date to get prayer times for (formatted as DD-MM-YYYY)
  /// - [latitude]: User's latitude
  /// - [longitude]: User's longitude
  /// - [calculationMethod]: Calculation method
  ///   (default Egyptian General Authority of Survey)
  ///
  /// Returns: Future<PrayerTimesResponse>
  /// Throws: NetworkException, ApiException
  Future<PrayerTimesResponse> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
  }) async {
    try {
      // Format the date as DD-MM-YYYY
      final formattedDate =
          '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';

      // Build query parameters
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'method': calculationMethod.toString(),
      };

      // Build the complete URL for logging
      final url =
          '${ApiConstants.prayerTimesBaseUrl}$_timingsEndpoint/$formattedDate';

      // Log the API request
      ApiLogger.logRequest(method: 'GET', url: url);

      // Make the API call with a base URL override.
      // This endpoint lives on a different host.
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await get(
        uri.toString(),
        headers: {'Accept': 'application/json'},
      );

      // Log the successful response
      ApiLogger.logResponse(
        statusCode: 200,
        url: url,
        // Response metadata contains precise coordinates; do not log it.
      );

      // Parse the response - the base service already decodes JSON
      return PrayerTimesResponse.fromJson(response);
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      // Log the error
      ApiLogger.logError(
        error: e,
        url: '${ApiConstants.prayerTimesBaseUrl}$_timingsEndpoint',
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }
}
