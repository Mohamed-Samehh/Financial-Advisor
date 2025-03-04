import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool showForgotPassword = false;
  String forgotPasswordEmail = '';
  String loginError = '';
  String forgotPasswordMessage = '';
  String forgotPasswordError = '';
  bool loading = false;
  bool loadingForgotPassword = false;
  bool showPassword = false;

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
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        final result = await authService.login({
          'email': email,
          'password': password,
        });
        if (result['token'] != null) {
          setState(() => loginError = '');
          context.go('/dashboard');
        }
      } catch (e) {
        setState(() {
          loginError = 'Invalid email or password. Please try again.';
          loading = false;
        });
      }
    }
  }

  void _forgotPassword() async {
    if (forgotPasswordEmail.isEmpty) {
      setState(() {
        forgotPasswordError = 'Please enter a valid email.';
        forgotPasswordMessage = '';
      });
      return;
    }
    setState(() => loadingForgotPassword = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.forgotPassword(forgotPasswordEmail);
      setState(() {
        forgotPasswordMessage = 'A new password has been sent to your email.';
        forgotPasswordError = '';
        loadingForgotPassword = false;
      });
    } catch (e) {
      setState(() {
        forgotPasswordError = e.toString();
        forgotPasswordMessage = '';
        loadingForgotPassword = false;
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
                        ),
                      ),
                      child: Icon(
                        showForgotPassword ? Icons.lock_open : Icons.login,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      showForgotPassword ? 'Reset Password' : 'Welcome Back',
                      style: const TextStyle(fontSize: 32, color: Colors.blue),
                    ),
                    Text(
                      showForgotPassword
                          ? 'Enter your email to reset your password'
                          : 'Please login to your account',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (loginError.isNotEmpty && !loading)
                      AlertMessage(message: loginError, isError: true),
                    if (!showForgotPassword) ...[
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Email is required'
                                          : null,
                              onChanged: (value) => email = value,
                            ),
                            const SizedBox(height: 16),
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
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Password is required'
                                          : null,
                              onChanged: (value) => password = value,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child:
                                  loading
                                      ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Logging in...'),
                                        ],
                                      )
                                      : const Text('Login to Your Account'),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  child: const Text('Create Account'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (showForgotPassword) ...[
                      if (forgotPasswordMessage.isNotEmpty)
                        AlertMessage(
                          message: forgotPasswordMessage,
                          isError: false,
                        ),
                      if (forgotPasswordError.isNotEmpty)
                        AlertMessage(
                          message: forgotPasswordError,
                          isError: true,
                        ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email, color: Colors.blue),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => forgotPasswordEmail = value,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            loadingForgotPassword ? null : _forgotPassword,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child:
                            loadingForgotPassword
                                ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Sending...'),
                                  ],
                                )
                                : const Text('Reset Password'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed:
                          () => setState(
                            () => showForgotPassword = !showForgotPassword,
                          ),
                      child: Text(
                        showForgotPassword
                            ? 'Back to Login'
                            : 'Forgot Password?',
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
