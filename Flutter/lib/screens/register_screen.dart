import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String message = '';
  bool isLoading = false;

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
      setState(() {
        isLoading = true;
        message = '';
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        await authService.register({'name': name, 'email': email});
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Registration Successful'),
                content: const Text(
                  'A password has been sent to your email. Please check your inbox and log in to continue.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/login');
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } catch (e) {
        if (!mounted) return;
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
                        Icons.person_add,
                        size: 80,
                        color: Colors.white.withAlpha(230),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Create an Account',
                        style: TextStyle(
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
                      const Text(
                        'Join us to manage your finances effortlessly!',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
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
                          if (message.isNotEmpty && !isLoading)
                            AlertMessage(message: message),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    labelStyle: const TextStyle(
                                      color: Colors.blueGrey,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person,
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
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Email',
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
                                      r'^[^@]+@[^@]+\.[^@]+',
                                    ).hasMatch(value)) {
                                      return 'Invalid email address';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => email = value,
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.blue, Colors.blueAccent],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child:
                                        isLoading
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Text(
                                              'Register',
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
                                      'Already have an account?',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 2.0),
                                    TextButton(
                                      onPressed: () => context.go('/login'),
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
                                        'Login here',
                                        style: TextStyle(color: Colors.blue),
                                      ),
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

  const AlertMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
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
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
