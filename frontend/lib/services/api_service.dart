import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration aiTimeout = Duration(seconds: 90);

  static String? _customBaseUrl;

  /// Dynamically configure backend URL (e.g. Render live URL)
  static void setCustomBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      String clean = url.trim();
      if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
      if (!clean.endsWith('/api')) clean = '$clean/api';
      _customBaseUrl = clean;
    } else {
      _customBaseUrl = null;
    }
  }

  /// Persist custom backend URL in SharedPreferences
  static Future<void> saveCustomBaseUrl(String? url) async {
    setCustomBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.trim().isNotEmpty) {
      await prefs.setString('custom_api_base_url', _customBaseUrl!);
    } else {
      await prefs.remove('custom_api_base_url');
    }
  }

  /// Load custom backend URL if saved
  static Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('custom_api_base_url');
    if (saved != null && saved.isNotEmpty) {
      _customBaseUrl = saved;
    }
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://localhost:5000/api';
    }
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _buildHeaders({bool isJson = true}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }

    final token = await getSavedToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Map<String, dynamic> _safeDecode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    if (response.statusCode == 404) {
      return {
        'success': false,
        'message': 'API endpoint not found (404). Please restart your backend server so new routes are loaded.',
      };
    }

    return {
      'success': false,
      'message': 'Server error (${response.statusCode}): ${response.reasonPhrase ?? 'Unknown'}',
    };
  }

  // REGISTER API
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(defaultTimeout);

      return _safeDecode(response);
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your network and try again.');
    } catch (e) {
      throw Exception('Unable to connect to backend ($baseUrl). Please check if backend is running.');
    }
  }

  // LOGIN API
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(defaultTimeout);

      return _safeDecode(response);
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your network and try again.');
    } catch (e) {
      throw Exception('Unable to connect to backend ($baseUrl). Please check if backend is running.');
    }
  }

  // SEND OTP API
  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    String? type,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email.trim().toLowerCase(),
      };
      if (type != null) {
        payload['type'] = type;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(defaultTimeout);

      return _safeDecode(response);
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your network and try again.');
    } catch (e) {
      throw Exception('Unable to connect to backend ($baseUrl). Please check if backend is running.');
    }
  }

  // VERIFY OTP API
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String? name,
    String? password,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      };
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(defaultTimeout);

      return _safeDecode(response);
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your network and try again.');
    } catch (e) {
      throw Exception('Unable to connect to backend ($baseUrl). Please check if backend is running.');
    }
  }

  // GET PROFILE API
  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(defaultTimeout);

      return _safeDecode(response);
    } on TimeoutException {
      throw Exception('Connection timed out while fetching profile.');
    } catch (e) {
      throw Exception('Unable to connect to backend ($baseUrl). Please check if backend is running.');
    }
  }

  // RESUME ANALYZER API
  static Future<Map<String, dynamic>> analyzeResume({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/resume/analyze'),
      );

      final token = await getSavedToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'resume',
          fileBytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final streamedResponse = await request.send().timeout(aiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      final data = _safeDecode(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ?? 'Resume analysis failed',
        );
      }

      return data;
    } on TimeoutException {
      throw Exception('Resume analysis timed out. Gemini AI is taking longer than expected, please try again.');
    }
  }

  // JOB MATCHER API
  static Future<Map<String, dynamic>> matchResumeWithJob({
    required Uint8List fileBytes,
    required String fileName,
    required String jobDescription,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/resume/match'),
      );

      final token = await getSavedToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['jobDescription'] = jobDescription;

      request.files.add(
        http.MultipartFile.fromBytes(
          'resume',
          fileBytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final streamedResponse = await request.send().timeout(aiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      final data = _safeDecode(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['message'] ?? 'Job matching failed');
      }

      return data;
    } on TimeoutException {
      throw Exception('Job matching timed out. Please try again.');
    }
  }

  // MOCK INTERVIEW API
  static Future<Map<String, dynamic>> startInterview({
    required String jobRole,
    required List<Map<String, String>> previousAnswers,
  }) async {
    try {
      final headers = await _buildHeaders(isJson: true);

      final response = await http
          .post(
            Uri.parse('$baseUrl/interview/start'),
            headers: headers,
            body: jsonEncode({
              'jobRole': jobRole.trim(),
              'previousAnswers': previousAnswers,
            }),
          )
          .timeout(aiTimeout);

      final data = _safeDecode(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ?? 'Failed to start interview',
        );
      }

      return data;
    } on TimeoutException {
      throw Exception('Interview evaluation timed out. Please try again.');
    }
  }

  // AI LEARNING ROADMAP API
  static Future<Map<String, dynamic>> generateLearningRoadmap({
    required String jobRole,
    required String skillLevel,
    required int dailyStudyHours,
  }) async {
    try {
      final headers = await _buildHeaders(isJson: true);

      final response = await http
          .post(
            Uri.parse('$baseUrl/roadmap/generate'),
            headers: headers,
            body: jsonEncode({
              'jobRole': jobRole.trim(),
              'skillLevel': skillLevel,
              'dailyStudyHours': dailyStudyHours,
            }),
          )
          .timeout(aiTimeout);

      final data = _safeDecode(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          data['message'] ?? 'Failed to generate learning roadmap',
        );
      }

      return data;
    } on TimeoutException {
      throw Exception('Learning roadmap generation timed out. Please try again.');
    }
  }
}
