import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String passwordConfirmation = '';
  String message = '';
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token != null && await authService.checkTokenExpiry()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already logged in. Redirecting...')),
      );
      context.go('/dashboard');
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && password == passwordConfirmation) {
      setState(() {
        isLoading = true;
        message = '';
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        final result = await authService.register({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        });
        if (result['token'] != null) {
          context.go('/dashboard');
        }
      } catch (e) {
        setState(() {
          isLoading = false;
          message =
              e.toString().contains('email is already registered')
                  ? 'This email is already registered. Please use a different one.'
                  : 'Error occurred during registration. Please try again.';
        });
      }
    } else {
      setState(() {
        message = 'Please fill out the form correctly.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Create an Account',
                      style: TextStyle(fontSize: 32, color: Colors.blue),
                    ),
                    const Text(
                      'Please fill in the details below',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (message.isNotEmpty && !isLoading)
                      AlertMessage(message: message, isError: true),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name Field
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters long';
                              }
                              return null;
                            },
                            onChanged: (value) => name = value,
                          ),
                          const SizedBox(height: 16),
                          // Email Field
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email, color: Colors.blue),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value)) {
                                return 'Invalid email address';
                              }
                              return null;
                            },
                            onChanged: (value) => email = value,
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.blue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed:
                                    () => setState(
                                      () => showPassword = !showPassword,
                                    ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: !showPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters long';
                              }
                              return null;
                            },
                            onChanged: (value) => password = value,
                          ),
                          const SizedBox(height: 16),
                          // Confirm Password Field
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.blue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          showConfirmPassword =
                                              !showConfirmPassword,
                                    ),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: !showConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password confirmation is required';
                              }
                              if (value != password) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            onChanged: (value) => passwordConfirmation = value,
                          ),
                          const SizedBox(height: 24),
                          // Submit Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child:
                                isLoading
                                    ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Processing...'),
                                      ],
                                    )
                                    : const Text('Register'),
                          ),
                          const SizedBox(height: 16),
                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Login here'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AlertMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const AlertMessage({super.key, required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red : Colors.green,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red[900] : Colors.green[900],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
