import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/navbar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (BuildContext appBarContext) {
            return Navbar(
              onMenuPressed: () => Scaffold.of(appBarContext).openDrawer(),
            );
          },
        ),
      ),
      drawer: Navbar.buildDrawer(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3949AB), Color(0xFF1E88E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment:
                        Alignment.center, // Add alignment center to Stack
                    children: [
                      // Decorative circles in background
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      // Content Column - now with width: double.infinity to center text properly
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: const Icon(
                                Icons.explore,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(0, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Take control of your finances with ease!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
                  child: Column(
                    children: [
                      Text(
                        'Explore Your Tools',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: const Color(0xFF4682A9)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 34),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double screenWidth = constraints.maxWidth;
                          int crossAxisCount;

                          if (screenWidth >= 600) {
                            crossAxisCount = 3;
                          } else {
                            crossAxisCount = (screenWidth / 300).floor().clamp(
                              1,
                              2,
                            );
                          }

                          double childAspectRatio =
                              screenWidth >= 600 ? 1.3 : 1.6;

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: childAspectRatio,
                            children: [
                              _buildCard(
                                context,
                                icon: Icons.account_balance_wallet,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Manage Budget',
                                subtitle: 'Plan your monthly budget',
                                route: '/budget',
                              ),
                              _buildCard(
                                context,
                                icon: Icons.track_changes,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Set Goal',
                                subtitle: 'Define your financial targets',
                                route: '/goal',
                              ),
                              _buildCard(
                                context,
                                icon: Icons.list,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Categories',
                                subtitle: 'Prioritize your categories',
                                route: '/categories',
                              ),
                              _buildCard(
                                context,
                                icon: Icons.receipt,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Track Expenses',
                                subtitle: 'Monitor your daily expenses',
                                route: '/expenses',
                              ),
                              _buildCard(
                                context,
                                icon: Icons.pie_chart,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Analyze Expenses',
                                subtitle:
                                    'Gain insights with visual expense analysis',
                                route: '/analyze',
                              ),
                              _buildCard(
                                context,
                                icon: Icons.smart_toy,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Chat with AI',
                                subtitle:
                                    'Get instant financial advices and insights',
                                route: '/chat',
                              ),
                              _buildCard(
                                context,
                                icon: Icons.trending_up,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Invest',
                                subtitle: 'Explore ways to grow your savings',
                                route: '/invest',
                              ),
                              _buildCard(
                                context,
                                icon: Icons.history,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Expense History',
                                subtitle: 'Review your past expenses',
                                route: '/history',
                              ),
                              _buildCard(
                                context,
                                icon: Icons.account_circle,
                                color: const Color(0xFFEFF6FF),
                                accentColor: const Color(0xFF1D4ED8),
                                title: 'Account',
                                subtitle: 'Manage your account',
                                route: '/account',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => context.go('/expenses'),
              backgroundColor: Colors.blue,
              tooltip: 'Add Expense',
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color accentColor,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 300),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withAlpha(51), width: 1),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withAlpha(204),
                blurRadius: 12,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withAlpha(25),
                ),
                child: Icon(icon, size: 40, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF2563EB),
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
