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
                    color: Colors.blue,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.home,
                        size: 80,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your Financial Dashboard',
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
                        'Take control of your finances with ease!',
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
                  child: Column(
                    children: [
                      Text(
                        'Explore Your Tools',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: const Color(0xFF4682A9)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.6,
                        children: [
                          _buildCard(
                            context,
                            icon: Icons.account_balance_wallet,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Manage Budget',
                            subtitle: 'Plan your monthly budget effectively.',
                            route: '/budget',
                          ),
                          _buildCard(
                            context,
                            icon: Icons.track_changes,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Manage Goal',
                            subtitle: 'Define your financial targets clearly.',
                            route: '/goal',
                          ),
                          _buildCard(
                            context,
                            icon: Icons.list,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Categories',
                            subtitle: 'Organize your categories effectively.',
                            route: '/categories',
                          ),
                          _buildCard(
                            context,
                            icon: Icons.receipt,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Track Expenses',
                            subtitle: 'Monitor your daily expenses.',
                            route: '/expenses',
                          ),
                          _buildCard(
                            context,
                            icon: Icons.pie_chart,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Analyze Expenses',
                            subtitle: 'Gain visual insights.',
                            route: '/analyze',
                          ),
                          _buildCard(
                            context,
                            icon: Icons.smart_toy,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Chat with AI',
                            subtitle:
                                'Get instant financial advice, insights, and tips with our AI chatbot.',
                            route: '/chat',
                          ),
                          _buildCard(
                            context,
                            icon: Icons.trending_up,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Invest',
                            subtitle:
                                'Explore bank certificates to grow your savings.',
                            route: '/invest',
                          ),
                          _buildCard(
                            context,
                            icon: Icons.history,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Expense History',
                            subtitle:
                                'Review and reflect on your past expenses.',
                            route: '/history',
                          ),
                          _buildCard(
                            context,
                            icon: Icons.account_circle,
                            color: const Color(0xFFEFF6FF),
                            accentColor: const Color(0xFF1D4ED8),
                            title: 'Account',
                            subtitle: 'Manage your profile.',
                            route: '/account',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Floating Action Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => context.go('/expenses'),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Add Expense',
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
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
                color: accentColor.withOpacity(0.1),
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF1E3A8A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
