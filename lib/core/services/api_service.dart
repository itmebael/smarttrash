import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl =
      'https://api.smarttrashcan-ssu.com'; // Replace with actual API URL
  static const Duration timeout = Duration(seconds: 30);

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Initialize API service
  static void initialize() {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ),
    );
  }

  // Generic HTTP methods
  static Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  static Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error handling
  static Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception(
          'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.sendTimeout:
        return Exception('Send timeout. Please try again.');
      case DioExceptionType.receiveTimeout:
        return Exception('Receive timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'An error occurred';
        return Exception('HTTP $statusCode: $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.connectionError:
        return Exception(
          'Connection error. Please check your internet connection.',
        );
      default:
        return Exception('An unexpected error occurred');
    }
  }

  // Authentication methods
  static Future<Response> login(String email, String password) async {
    return await post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
  }

  static Future<Response> register(Map<String, dynamic> userData) async {
    return await post('/auth/register', data: userData);
  }

  static Future<Response> logout(String token) async {
    return await post(
      '/auth/logout',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> refreshToken(String refreshToken) async {
    return await post('/auth/refresh', data: {'refresh_token': refreshToken});
  }

  // Trashcan methods
  static Future<Response> getAllTrashcans(String token) async {
    return await get('/trashcans', headers: {'Authorization': 'Bearer $token'});
  }

  static Future<Response> getTrashcanById(String id, String token) async {
    return await get(
      '/trashcans/$id',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> updateTrashcanStatus(
    String id,
    Map<String, dynamic> statusData,
    String token,
  ) async {
    return await put(
      '/trashcans/$id/status',
      data: statusData,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> assignStaffToTrashcan(
    String trashcanId,
    String staffId,
    String token,
  ) async {
    return await post(
      '/trashcans/$trashcanId/assign',
      data: {'staffId': staffId},
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Task methods
  static Future<Response> getAllTasks(String token) async {
    return await get('/tasks', headers: {'Authorization': 'Bearer $token'});
  }

  static Future<Response> getTasksByStaff(String staffId, String token) async {
    return await get(
      '/tasks/staff/$staffId',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> createTask(
    Map<String, dynamic> taskData,
    String token,
  ) async {
    return await post(
      '/tasks',
      data: taskData,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> updateTaskStatus(
    String taskId,
    Map<String, dynamic> statusData,
    String token,
  ) async {
    return await put(
      '/tasks/$taskId/status',
      data: statusData,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> completeTask(
    String taskId,
    Map<String, dynamic> completionData,
    String token,
  ) async {
    return await put(
      '/tasks/$taskId/complete',
      data: completionData,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Notification methods
  static Future<Response> getNotifications(String userId, String token) async {
    return await get(
      '/notifications/user/$userId',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> markNotificationAsRead(
    String notificationId,
    String token,
  ) async {
    return await put(
      '/notifications/$notificationId/read',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> sendNotification(
    Map<String, dynamic> notificationData,
    String token,
  ) async {
    return await post(
      '/notifications/send',
      data: notificationData,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Report methods
  static Future<Response> getTrashcanReports(
    String token, {
    String? startDate,
    String? endDate,
    String? trashcanId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (trashcanId != null) queryParams['trashcanId'] = trashcanId;

    return await get(
      '/reports/trashcans',
      queryParameters: queryParams,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> getTaskReports(
    String token, {
    String? startDate,
    String? endDate,
    String? staffId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (staffId != null) queryParams['staffId'] = staffId;

    return await get(
      '/reports/tasks',
      queryParameters: queryParams,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Analytics methods
  static Future<Response> getAnalytics(String token, {String? period}) async {
    final queryParams = <String, dynamic>{};
    if (period != null) queryParams['period'] = period;

    return await get(
      '/analytics',
      queryParameters: queryParams,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // QR Code methods
  static Future<Response> generateQRCode(
    String trashcanId,
    String token,
  ) async {
    return await post(
      '/trashcans/$trashcanId/qr-code',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  static Future<Response> scanQRCode(String qrData, String token) async {
    return await post(
      '/qr-code/scan',
      data: {'qrData': qrData},
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

