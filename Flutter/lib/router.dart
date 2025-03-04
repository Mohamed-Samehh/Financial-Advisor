// import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
// import 'screens/dashboard_screen.dart';
// import 'screens/budget_screen.dart';
// import 'screens/goals_screen.dart';
// import 'screens/categories_screen.dart';
// import 'screens/expenses_screen.dart';
// import 'screens/analyze_expenses_screen.dart';
// import 'screens/invest_screen.dart';
// import 'screens/chatbot_screen.dart';
// import 'screens/user_profile_screen.dart';
// import 'screens/expense_history_screen.dart';
// import 'screens/not_found_screen.dart';
import 'services/auth_service.dart';

final GoRouter router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    // GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
    // GoRoute(
    //   path: '/dashboard',
    //   builder: (context, state) => const DashboardScreen(),
    // ),
    // GoRoute(path: '/budget', builder: (context, state) => const BudgetScreen()),
    // GoRoute(path: '/goal', builder: (context, state) => const GoalsScreen()),
    // GoRoute(
    //   path: '/categories',
    //   builder: (context, state) => const CategoriesScreen(),
    // ),
    // GoRoute(
    //   path: '/expenses',
    //   builder: (context, state) => const ExpensesScreen(),
    // ),
    // GoRoute(
    //   path: '/analyze',
    //   builder: (context, state) => const AnalyzeExpensesScreen(),
    // ),
    // GoRoute(path: '/invest', builder: (context, state) => const InvestScreen()),
    // GoRoute(
    //   path: '/history',
    //   builder: (context, state) => const ExpenseHistoryScreen(),
    // ),
    // GoRoute(path: '/chat', builder: (context, state) => const ChatbotScreen()),
    // GoRoute(
    //   path: '/account',
    //   builder: (context, state) => const UserProfileScreen(),
    // ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    // GoRoute(
    //   path: '/:path(.*)', // Wildcard for 404
    //   builder: (context, state) => const NotFoundScreen(),
    // ),
  ],
  redirect: (context, state) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = await authService.checkTokenExpiry();
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    if (isLoggedIn && isAuthRoute) {
      return '/dashboard';
    }
    return null;
  },
);
