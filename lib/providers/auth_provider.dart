import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../core/constants.dart';
import '../core/error_handler.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  late Dio _dio;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  Future<void>? _initFuture;
  bool _rememberMe = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Dio get dio => _dio;
  bool get rememberMe => _rememberMe;

  AuthProvider() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      validateStatus: (status) => status! < 500,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          await _clearAuthState();
        }
        return handler.next(e);
      },
    ));

    _initFuture = _loadAuthState();
  }

  Future<void> _clearAuthState() async {
    // bool isLoading = true; // NEW
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true; // Set class property instead of local variable
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool('remember_me') ?? false;

      final savedToken = prefs.getString(_tokenKey);
      final savedUserJson = prefs.getString(_userKey);

      if (savedToken != null && savedUserJson != null) {
        try {
          final response = await _dio.get(
            '/auth/check-token',
            options: Options(
              headers: {'Authorization': 'Bearer $savedToken'},
            ),
          );

          if (response.statusCode == 200) {
            _token = savedToken;
            _user = User.fromJson(json.decode(savedUserJson));
          } else {
            await _clearAuthState();
          }
        } catch (e) {
          await _clearAuthState();
        }
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      await _clearAuthState();
    } finally {
      _isLoading = false; // Set class property
      notifyListeners(); // Trigger UI update
    }
  }

  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null && _user != null) {
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_userKey, json.encode(_user!.toJson()));
        await prefs.setBool('remember_me', _rememberMe);
      } else {
        await prefs.remove(_tokenKey);
        await prefs.remove(_userKey);
        await prefs.remove('remember_me');
      }
    } catch (e) {
      debugPrint('Error saving auth state: $e');
    }
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Attempting login for email: $email');
      debugPrint('Base URL: ${_dio.options.baseUrl}');
      debugPrint('Full login URL: ${_dio.options.baseUrl}/auth/login');

      // Don't await _initFuture here as it might cause a deadlock
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response data: ${response.data}');
      debugPrint('Login response headers: ${response.headers}');

      if (response.statusCode == 200) {
        _token = response.data['token'];
        _user = User.fromJson(response.data['user']);
        debugPrint('Login successful, token received');

        // Handle state saving asynchronously
        if (_rememberMe) {
          await _saveAuthState(); // Await this to ensure state is saved
          debugPrint('Auth state saved to preferences');
        } else {
          // Clear any existing saved state
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_tokenKey);
          await prefs.remove(_userKey);
          await prefs.remove('remember_me');
          debugPrint('Auth state cleared from preferences');
        }

        notifyListeners();
        return true;
      }

      if (response.statusCode == 401) {
        _error = response.data['message'] ?? 'Invalid credentials. Please try again.';
        debugPrint('Login failed with 401: $_error');
        return false;
      } else {
        _error = response.data['message'] ?? 'Login failed';
        debugPrint('Login failed: $_error');
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (e is DioException) {
        debugPrint('Dio error type: ${e.type}');
        debugPrint('Dio error message: ${e.message}');
        debugPrint('Dio error response: ${e.response?.data}');
        debugPrint('Dio error status code: ${e.response?.statusCode}');
      }
      _handleError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Wait for initialization to complete if needed
      if (_initFuture != null) {
        await _initFuture;
      }

      if (_token == null) {
        _error = 'Authentication required. Please login first.';
        debugPrint('Token is null during admin registration');
        return false;
      }

      final response = await _dio.post(
        '/admin',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      debugPrint('Register admin response status: ${response.statusCode}');
      debugPrint('Register admin response data: ${response.data}');

      if (response.statusCode == 403) {
        _error = "You don't have the access. Contact superadmin";
        debugPrint('Register admin failed with 403: $_error');
        return false;
      }
      if (response.statusCode == 409) {
        _error = "Admin with this email already exists";
        debugPrint('Register admin failed with 409: $_error');
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _error = null;
        return true;
      }

      _error = response.data['message'] ?? 'Failed to register admin';
      debugPrint('Register admin failed with ${response.statusCode}: $_error');
      return false;
    } catch (e) {
      debugPrint('Error during admin registration: $e');
      if (e is DioException) {
        debugPrint('Dio error type: ${e.type}');
        debugPrint('Dio error message: ${e.message}');
        debugPrint('Dio error response: ${e.response?.data}');
        debugPrint('Dio error status code: ${e.response?.statusCode}');
        
        // Check for specific status codes in the error response
        if (e.response?.statusCode == 409) {
          _error = "Admin with this email already exists";
          return false;
        }
      }
      _handleError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_initFuture != null) {
        await _initFuture;
      }
      final response = await _dio.post(
        '/auth/password-reset',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to send reset token';
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(
      String email, String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_initFuture != null) {
        await _initFuture;
      }
      // First validate the token
      final validateResponse = await _dio.post(
        '/auth/validate-token',
        data: {'email': email},
        queryParameters: {'token': token},
      );

      if (validateResponse.statusCode != 200) {
        _error = validateResponse.data['message'] ?? 'Invalid reset token';
        return false;
      }

      // If token is valid, proceed with password reset
      final resetResponse = await _dio.post(
        '/auth/reset-confirm',
        data: {
          'email': email,
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (resetResponse.statusCode == 200) {
        return true;
      } else {
        _error = resetResponse.data['message'] ?? 'Failed to reset password';
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() async {
    _user = null;
    _token = null;
    _error = null;
    await _saveAuthState();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> sendOtp(String email) async {
    try {
      if (_initFuture != null) {
        await _initFuture;
      }

      debugPrint('Sending OTP to email: $email');

      final response = await _dio.post(
        '/auth/send-otp',
        data: {'email': email},
      );

      debugPrint('Send OTP response status: ${response.statusCode}');
      debugPrint('Send OTP response data: ${response.data}');

      if (response.statusCode == 200) {
        _error = null;
        return true;
      }

      // Don't treat 500 as success
      if (response.statusCode == 500) {
        _error = response.data['message'] ?? 'Server error while sending OTP';
        debugPrint('Server error: $_error');
        return false;
      }

      _error = response.data['message'] ?? 'Failed to send OTP';
      debugPrint('Failed to send OTP: $_error');
      return false;
    } catch (e) {
      debugPrint('Exception sending OTP: $e');
      if (e is DioException && e.response?.data != null) {
        // Check for validation errors
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('validationErrors')) {
          final validationErrors = responseData['validationErrors'] as List;
          if (validationErrors.isNotEmpty) {
            final firstError = validationErrors[0];
            _error = '${firstError['field']}: ${firstError['message']}';
          } else {
            _error = responseData['message'] ?? 'Validation error';
          }
        } else {
          _handleError(e);
        }
      } else {
        _handleError(e);
      }
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      if (_initFuture != null) {
        await _initFuture;
      }

      debugPrint('Verifying OTP for email: $email, OTP: $otp');

      // Ensure OTP is properly formatted (6 digits)
      if (otp.length != 6 || int.tryParse(otp) == null) {
        _error = 'Invalid OTP format';
        debugPrint('Invalid OTP format: $otp');
        return false;
      }

      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      debugPrint('OTP verification response status: ${response.statusCode}');
      debugPrint('OTP verification response data: ${response.data}');

      if (response.statusCode == 200) {
        _error = null;
        debugPrint('OTP verification successful');
        return true;
      } else if (response.statusCode == 400) {
        _error = response.data['message'] ?? 'Invalid OTP';
        debugPrint('OTP verification failed with 400: $_error');
        return false;
      } else if (response.statusCode == 410) {
        _error = 'OTP has expired. Please request a new one.';
        debugPrint('OTP verification failed with 410: $_error');
        return false;
      } else {
        _error = response.data['message'] ?? 'Failed to verify OTP';
        debugPrint(
            'OTP verification failed with ${response.statusCode}: $_error');
        return false;
      }
    } catch (e) {
      debugPrint('Error during OTP verification: $e');
      if (e is DioException) {
        debugPrint('Dio error type: ${e.type}');
        debugPrint('Dio error message: ${e.message}');
        debugPrint('Dio error response: ${e.response?.data}');
        debugPrint('Dio error status code: ${e.response?.statusCode}');
        
        // Check for validation errors
        if (e.response?.data != null) {
          final responseData = e.response?.data;
          if (responseData is Map && responseData.containsKey('validationErrors')) {
            final validationErrors = responseData['validationErrors'] as List;
            if (validationErrors.isNotEmpty) {
              final firstError = validationErrors[0];
              _error = '${firstError['field']}: ${firstError['message']}';
              return false;
            }
          }
        }
      }
      _handleError(e);
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      if (_initFuture != null) {
        await _initFuture;
      }

      debugPrint('Resending OTP to email: $email');

      final response = await _dio.post(
        '/auth/resend-otp',
        data: {'email': email},
      );

      debugPrint('Resend OTP response status: ${response.statusCode}');
      debugPrint('Resend OTP response data: ${response.data}');

      if (response.statusCode == 200) {
        _error = null;
        debugPrint('OTP resent successfully');
        return true;
      }

      // Don't treat 500 as success
      if (response.statusCode == 500) {
        _error = response.data['message'] ?? 'Server error while resending OTP';
        debugPrint('Server error: $_error');
        return false;
      }

      _error = response.data['message'] ?? 'Failed to resend OTP';
      debugPrint('Failed to resend OTP: $_error');
      return false;
    } catch (e) {
      debugPrint('Exception resending OTP: $e');
      if (e is DioException && e.response?.data != null) {
        // Check for validation errors
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('validationErrors')) {
          final validationErrors = responseData['validationErrors'] as List;
          if (validationErrors.isNotEmpty) {
            final firstError = validationErrors[0];
            _error = '${firstError['field']}: ${firstError['message']}';
          } else {
            _error = responseData['message'] ?? 'Validation error';
          }
        } else {
          _handleError(e);
        }
      } else {
        _handleError(e);
      }
      return false;
    }
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_initFuture != null) {
        await _initFuture;
      }

      debugPrint('Registering user with email: $email');
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      debugPrint('Registration response status: ${response.statusCode}');
      debugPrint('Registration response data: ${response.data}');

      if (response.statusCode == 201) {
        // Don't set user or token here since we need OTP verification first
        _error = null;
        return true;
      } else {
        _error = response.data['message'] ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      debugPrint('Error during user registration: $e');
      if (e is DioException) {
        debugPrint('Dio error type: ${e.type}');
        debugPrint('Dio error message: ${e.message}');
        debugPrint('Dio error response: ${e.response?.data}');
        debugPrint('Dio error status code: ${e.response?.statusCode}');
        
        // Check for specific status codes in the error response
        if (e.response?.statusCode == 409) {
          _error = "User with this email already exists";
          return false;
        }
      }
      _handleError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response?.statusCode == 403) {
        _error = "You don't have the access. Contact superadmin";
      } else if (e.response?.statusCode == 401) {
        _error = "Invalid credentials. Please try again.";
      } else if (e.type == DioExceptionType.connectionTimeout) {
        _error = "Connection timeout. Please check your internet connection.";
      } else if (e.type == DioExceptionType.receiveTimeout) {
        _error = "Server response timeout. Please try again.";
      } else if (e.type == DioExceptionType.sendTimeout) {
        _error = "Request timeout. Please try again.";
      } else if (e.type == DioExceptionType.badResponse) {
        _error = "Server error. Please try again later.";
      } else if (e.type == DioExceptionType.cancel) {
        _error = "Request cancelled. Please try again.";
      } else if (e.type == DioExceptionType.unknown) {
        _error = "Network error. Please check your connection.";
      } else {
        _error = e.response?.data?['message'] ??
            e.message ??
            'An unexpected error occurred';
      }
    } else {
      _error = ErrorHandler.getErrorMessage(e);
    }
    debugPrint('Error: $_error');
  }
}
