import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String _apiUrl = 'http://localhost:8000/api';

  // 'http://10.0.2.2:8000/api' Android emulator and make sure to run "php artisan serve --host=0.0.0.0 --port=8000"
  // 'http://localhost:8000/api' Web or other platforms

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Helper method to handle responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Send chat message to chatbot
  Future<dynamic> sendChatMessage(String message) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_apiUrl/chatbot'),
      headers: headers,
      body: jsonEncode({'message': message}),
    );
    return _handleResponse(response);
  }

  // Budget
  Future<dynamic> getAllBudgets() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/budget/all'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> getBudget() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/budget'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> addBudget(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_apiUrl/budget'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateBudget(Map<String, dynamic> data, int budgetId) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/budget/$budgetId'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> deleteBudget(int budgetId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_apiUrl/budget/$budgetId'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Goals
  Future<dynamic> getAllGoals() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/goal/all'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> getGoal() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/goal'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> addGoal(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_apiUrl/goal'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateGoal(Map<String, dynamic> data, int goalId) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/goal/$goalId'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> deleteGoal(int goalId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_apiUrl/goal/$goalId'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Expenses
  Future<dynamic> getAllExpenses({int page = 1, int perPage = 1}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/expenses/all?page=$page&per_page=$perPage'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> getExpenses() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/expenses'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> addExpense(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_apiUrl/expenses'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateExpense(Map<String, dynamic> data, int id) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/expenses/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> deleteExpense(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_apiUrl/expenses/$id'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> analyzeExpenses() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/analyze-expenses'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Categories
  Future<dynamic> getCategories() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/categories'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> addCategory(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_apiUrl/categories'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> updateCategory(Map<String, dynamic> data, int id) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/categories/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> deleteCategory(int id, String newCategory) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_apiUrl/categories/$id'),
      headers: headers,
      body: jsonEncode({'new_category': newCategory}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> getCategorySuggestions() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/categories/suggest'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> getCategoryLabels() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/categories/label'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Stocks
  Future<dynamic> getEgyptStocks() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/stocks/egypt'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> getStockDetails(String symbol) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/stocks/details/$symbol'),
      headers: headers,
    );
    return _handleResponse(response);
  }
}
