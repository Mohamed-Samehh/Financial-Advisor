import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
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
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token != null && await authService.checkTokenExpiry()) {
      if (!mounted) return;
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
        if (!mounted) return;
        if (result['token'] != null) {
          setState(() => loginError = '');
          context.go('/dashboard');
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          loginError =
              e.toString().contains('Invalid credentials')
                  ? 'Incorrect email or password.'
                  : 'An error occurred during login. Please try again.';
          loading = false;
        });
      }
    }
  }

  void _forgotPassword() async {
    if (forgotPasswordEmail.isEmpty) {
      setState(() {
        forgotPasswordError = 'Please enter a valid email address.';
        forgotPasswordMessage = '';
      });
      return;
    }
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(forgotPasswordEmail)) {
      setState(() {
        forgotPasswordError = 'Please enter a valid email address.';
        forgotPasswordMessage = '';
      });
      return;
    }

    setState(() => loadingForgotPassword = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.forgotPassword(forgotPasswordEmail);
      if (!mounted) return;
      setState(() {
        forgotPasswordMessage = 'A new password has been sent to your email.';
        forgotPasswordError = '';
        loadingForgotPassword = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        forgotPasswordError =
            e.toString().contains('email is not registered')
                ? 'The email is not registered.'
                : 'Error during password reset. Please try again.';
        forgotPasswordMessage = '';
        loadingForgotPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF8F9FA), Color(0xFFE2E8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        showForgotPassword ? Icons.lock_open : Icons.login,
                        size: 80,
                        color: Colors.white.withAlpha(230),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        showForgotPassword ? 'Reset Password' : 'Welcome Back',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        showForgotPassword
                            ? 'Enter your email to reset your password'
                            : 'Login to manage your finances seamlessly',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFF8F9FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (loginError.isNotEmpty && !loading)
                            AlertMessage(message: loginError, isError: true),
                          if (!showForgotPassword) ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: const TextStyle(
                                        color: Colors.blueGrey,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.email,
                                        color: Colors.blue,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.blue,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Color.fromRGBO(
                                        33,
                                        150,
                                        243,
                                        0.05,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(value)) {
                                        return 'Invalid email address';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) => email = value,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: const TextStyle(
                                        color: Colors.blueGrey,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock,
                                        color: Colors.blue,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          showPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.blueGrey,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  showPassword = !showPassword,
                                            ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.blue,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Color.fromRGBO(
                                        33,
                                        150,
                                        243,
                                        0.05,
                                      ),
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
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.blue,
                                          Colors.blueAccent,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(
                                          double.infinity,
                                          50,
                                        ),
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child:
                                          loading
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : const Text(
                                                'Login to Your Account',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Don't have an account?",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 2.0),
                                      TextButton(
                                        onPressed:
                                            () => context.go('/register'),
                                        style: ButtonStyle(
                                          foregroundColor:
                                              WidgetStateProperty.all(
                                                Colors.blue,
                                              ),
                                          overlayColor: WidgetStateProperty.all(
                                            Colors.transparent,
                                          ),
                                          splashFactory: NoSplash.splashFactory,
                                        ),
                                        child: const Text(
                                          'Create Account',
                                          style: TextStyle(color: Colors.blue),
                                        ),
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
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: const TextStyle(
                                  color: Colors.blueGrey,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.blue,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blueAccent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Color.fromRGBO(33, 150, 243, 0.05),
                              ),
                              onChanged: (value) => forgotPasswordEmail = value,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.blue, Colors.blueAccent],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed:
                                    loadingForgotPassword
                                        ? null
                                        : _forgotPassword,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    loadingForgotPassword
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Reset Password',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed:
                                () => setState(() {
                                  showForgotPassword = !showForgotPassword;
                                  if (showForgotPassword) {
                                    loginError = '';
                                    email = '';
                                    password = '';
                                  } else {
                                    forgotPasswordError = '';
                                    forgotPasswordMessage = '';
                                    forgotPasswordEmail = '';
                                  }
                                }),
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.all(
                                Colors.blue,
                              ),
                              overlayColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                              splashFactory: NoSplash.splashFactory,
                            ),
                            child: Text(
                              showForgotPassword
                                  ? 'Back to Login'
                                  : 'Forgot Password?',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
            color: Colors.black.withAlpha(25),
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
