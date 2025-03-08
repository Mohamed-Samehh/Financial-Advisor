import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'router.dart';

void main() {
  runApp(
    DevicePreview(
      // Wrap the app with DevicePreview for device previewing
      enabled:
          !kReleaseMode, // Ensure DevicePreview is only enabled in development mode
      builder:
          (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthService()),
              Provider(create: (_) => ApiService()),
            ],
            child: const MyApp(),
          ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Financial Advisor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        // Apply Poppins font globally
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          displaySmall: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
          headlineLarge: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
          labelLarge: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          labelMedium: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelSmall: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Widget child; // Content from routed screens

  const HomeScreen({super.key, required this.child});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _isNavbarVisible = false;
  bool _isLoggedIn = false;

  late AuthService authService;

  @override
  void initState() {
    super.initState();
    authService = Provider.of<AuthService>(context, listen: false);
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final token = await authService.getToken();
    setState(() {
      _isLoggedIn = token != null;
    });

    if (_isLoggedIn) {
      final isValid = await authService.checkTokenExpiry();
      if (!mounted) return;
      if (!isValid) {
        context.go('/login');
      }
    } else {
      if (!mounted) return;
      context.go('/login');
    }
  }

  void _toggleNavbar() {
    setState(() => _isNavbarVisible = !_isNavbarVisible);
  }

  void _closeNavbar() {
    setState(() => _isNavbarVisible = false);
  }

  void _logout() {
    authService.clearToken();
    _closeNavbar();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF010B1F),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10),
            const Text('Financial Advisor', style: TextStyle(fontSize: 24)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: _toggleNavbar,
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF010B1F), Color(0xFF0F1D36)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Text(
                  'Financial Advisor',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              if (_isLoggedIn) ...[
                _buildNavItem(Icons.explore, 'Dashboard', '/dashboard'),
                _buildNavItem(Icons.wallet, 'Budget', '/budget'),
                _buildNavItem(Icons.track_changes, 'Goal', '/goal'),
                _buildNavItem(Icons.list, 'Categories', '/categories'),
                _buildNavItem(Icons.receipt, 'Expenses', '/expenses'),
                _buildNavItem(Icons.pie_chart, 'Analyze', '/analyze'),
                _buildNavItem(Icons.smart_toy, 'Chat', '/chat'),
                _buildNavItem(Icons.trending_up, 'Invest', '/invest'),
                _buildNavItem(Icons.history, 'History', '/history'),
                _buildNavItem(Icons.account_circle, 'Account', '/account'),
              ],
              if (!_isLoggedIn) ...[
                _buildNavItem(Icons.login, 'Login', '/login'),
                _buildNavItem(Icons.person_add, 'Register', '/register'),
              ],
              if (_isLoggedIn)
                ListTile(
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  tileColor: const Color(0xFFF33D3D),
                  onTap: _logout,
                ),
            ],
          ),
        ),
      ),
      body: widget.child, // Display the routed screen content
    );
  }

  Widget _buildNavItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        _closeNavbar();
        context.go(route);
      },
    );
  }
}
