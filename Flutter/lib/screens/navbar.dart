import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class Navbar extends StatelessWidget {
  final VoidCallback onMenuPressed;

  const Navbar({super.key, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 4,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF010B1F), Color(0xFF0F1D36)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          AnimatedLogo(),
          const SizedBox(width: 12),
          const Text(
            'Financial Advisor',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, size: 28, color: Colors.white),
          onPressed: onMenuPressed,
        ),
      ],
    );
  }

  static Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF010B1F), Color(0xFF0F1D36)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            // ignore: unnecessary_null_comparison
            final isLoggedIn = authService.getToken() != null;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white.withAlpha(25)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Financial Advisor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your Money, Your Way',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (isLoggedIn) ...[
                  _buildNavItem(
                    context,
                    Icons.explore,
                    'Dashboard',
                    '/dashboard',
                  ),
                  _buildNavItem(
                    context,
                    Icons.account_balance_wallet,
                    'Budget',
                    '/budget',
                  ),
                  _buildNavItem(context, Icons.track_changes, 'Goal', '/goal'),
                  _buildNavItem(
                    context,
                    Icons.list,
                    'Categories',
                    '/categories',
                  ),
                  _buildNavItem(
                    context,
                    Icons.receipt,
                    'Expenses',
                    '/expenses',
                  ),
                  _buildNavItem(
                    context,
                    Icons.pie_chart,
                    'Analyze',
                    '/analyze',
                  ),
                  _buildNavItem(context, Icons.smart_toy, 'Chat', '/chat'),
                  _buildNavItem(
                    context,
                    Icons.trending_up,
                    'Invest',
                    '/invest',
                  ),
                  _buildNavItem(context, Icons.history, 'History', '/history'),
                  _buildNavItem(
                    context,
                    Icons.account_circle,
                    'Account',
                    '/account',
                  ),
                ],
                if (!isLoggedIn) ...[
                  _buildNavItem(context, Icons.login, 'Login', '/login'),
                  _buildNavItem(
                    context,
                    Icons.person_add,
                    'Register',
                    '/register',
                  ),
                ],
                if (isLoggedIn)
                  Column(
                    children: [
                      const Divider(
                        color: Colors.white30,
                        thickness: 1,
                        height: 1,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF33D3D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () {
                              authService.clearToken();
                              context.go('/login');
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Scaffold.of(context).closeDrawer();
        context.go(route);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: Colors.white.withAlpha(25),
    );
  }
}

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  _AnimatedLogoState createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Image.asset('assets/logo.png', height: 40),
        );
      },
    );
  }
}
