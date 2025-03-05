import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static final String _apiUrl = 'http://localhost:8000/api';

  // 'http://10.0.2.2:8000/api' Android emulator and make sure to run "php artisan serve --host=0.0.0.0 --port=8000"
  // 'http://localhost:8000/api' Web or other platforms

  bool _sessionExpired = false;

  bool get sessionExpired => _sessionExpired;

  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(Map<String, String> data) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final result = _handleResponse(response);
    if (result['token'] != null) {
      await setToken(result['token']);
    }
    return result;
  }

  Future<void> deleteAccount(String password) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$_apiUrl/delete-account'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'password': password}),
    );
    _handleResponse(response);
    await clearToken();
  }

  Future<void> updateProfile(String name, String email) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$_apiUrl/update-profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$_apiUrl/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _handleResponse(response);
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$_apiUrl/update-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    _handleResponse(response);
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    _handleResponse(response);
  }

  Future<bool> checkTokenExpiry() async {
    final token = await getToken();
    if (token == null) {
      await clearToken();
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/check-token-expiry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
      final data = jsonDecode(response.body);
      if (data['expired'] == true) {
        await clearToken();
        _sessionExpired = true;
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      await clearToken();
      _sessionExpired = true;
      notifyListeners();
      return false;
    }
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    notifyListeners();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }
}
