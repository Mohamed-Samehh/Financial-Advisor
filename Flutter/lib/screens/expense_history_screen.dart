import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../screens/navbar.dart';
import 'package:intl/intl.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  ExpenseHistoryScreenState createState() => ExpenseHistoryScreenState();
}

class ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  Map<String, List<Map<String, dynamic>>> expensesByMonth = {};
  Map<String, num?> totalExpensesByMonth = {};
  Map<String, Map<String, dynamic>> budgetByMonth = {};
  Map<String, Map<String, dynamic>> goalByMonth = {};
  List<String> sortedMonths = [];
  String? message;
  String? messageType; // 'success' or 'error'
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  final int yearsPerPage = 1;
  late int currentYear;
  late int currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentYear = now.year;
    currentMonth = now.month;
    _loadExpenses();
  }

  void _loadExpenses() async {
    setState(() => isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final expensesResponse = await apiService.getAllExpenses(
        page: currentPage,
        perPage: yearsPerPage,
      );
      final budgetsResponse = await apiService.getAllBudgets();
      final goalsResponse = await apiService.getAllGoals();

      final List<dynamic> expenseData = expensesResponse['data'] ?? [];
      final List<dynamic> budgets =
          budgetsResponse['budgets'] as List<dynamic>? ?? [];
      final List<dynamic> goals =
          goalsResponse['goals'] as List<dynamic>? ?? [];

      _groupExpensesByMonth(expenseData);
      _assignBudgetsAndGoals(budgets, goals);
      _setupPagination(expensesResponse);

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        message = 'Failed to load data. Error: $e';
        messageType = 'error';
        isLoading = false;
      });
    }
  }

  num? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  void _groupExpensesByMonth(List<dynamic> expensesByYear) {
    expensesByMonth = {};
    totalExpensesByMonth = {};
    sortedMonths = [];

    for (var yearExpenses in expensesByYear) {
      if (yearExpenses is List<dynamic>) {
        final year =
            _parseDate(
              yearExpenses.isNotEmpty ? yearExpenses[0]['date'] : null,
            )?.year.toString() ??
            currentYear.toString();
        sortedMonths = [year];

        for (var expense in yearExpenses) {
          if (expense is Map<String, dynamic>) {
            final expenseDate = _parseDate(expense['date']);
            if (expenseDate == null) continue;
            final month = expenseDate.month;
            final monthYear = '$year-${month.toString().padLeft(2, '0')}';
            final amount = _parseAmount(expense['amount']) ?? 0;

            if (_isCurrentMonth(monthYear)) {
              totalExpensesByMonth[monthYear] = null;
            } else {
              if (!expensesByMonth.containsKey(monthYear)) {
                expensesByMonth[monthYear] = [];
                totalExpensesByMonth[monthYear] = 0;
              }
              expensesByMonth[monthYear]!.add({
                'category': expense['category']?.toString() ?? 'Unknown',
                'amount': amount,
                'date': expense['date']?.toString() ?? '',
              });
              totalExpensesByMonth[monthYear] =
                  (totalExpensesByMonth[monthYear] ?? 0) + amount;
            }
          }
        }
      }
    }

    final year =
        sortedMonths.isNotEmpty ? sortedMonths[0] : currentYear.toString();
    for (int month = 1; month <= 12; month++) {
      final monthYear = '$year-${month.toString().padLeft(2, '0')}';
      if (!expensesByMonth.containsKey(monthYear)) {
        expensesByMonth[monthYear] = [];
        totalExpensesByMonth[monthYear] ??=
            _isCurrentMonth(monthYear) ? null : 0;
      }
    }

    sortedMonths =
        expensesByMonth.keys.toList()..sort((a, b) {
          final [yearA, monthA] = a.split('-').map(int.parse).toList();
          final [yearB, monthB] = b.split('-').map(int.parse).toList();
          return yearB.compareTo(yearA) != 0
              ? yearB.compareTo(yearA)
              : monthB.compareTo(monthA);
        });
  }

  void _assignBudgetsAndGoals(List<dynamic> budgets, List<dynamic> goals) {
    for (var budget in budgets) {
      if (budget is! Map<String, dynamic>) continue;
      final budgetDate = _parseDate(budget['created_at']);
      if (budgetDate == null) continue;
      final monthYear =
          '${budgetDate.year}-${budgetDate.month.toString().padLeft(2, '0')}';
      budgetByMonth[monthYear] = budget;
    }

    for (var goal in goals) {
      if (goal is! Map<String, dynamic>) continue;
      final goalDate = _parseDate(goal['created_at']);
      if (goalDate == null) continue;
      final monthYear =
          '${goalDate.year}-${goalDate.month.toString().padLeft(2, '0')}';
      goalByMonth[monthYear] = goal;
    }
  }

  void _setupPagination(Map<String, dynamic> expensesResponse) {
    currentPage = expensesResponse['current_page'] ?? 1;
    totalPages = expensesResponse['last_page'] ?? 1;
  }

  List<String> _getMonthsForCurrentPage() {
    final year =
        sortedMonths.isNotEmpty
            ? sortedMonths[0].split('-')[0]
            : currentYear.toString();
    return List.generate(
      12,
      (index) => '$year-${(index + 1).toString().padLeft(2, '0')}',
    );
  }

  void _changePage(int page) {
    if (page < 1 || page > totalPages) return;
    setState(() {
      currentPage = page;
      _loadExpenses();
    });
  }

  String _formatNumber(num? value) {
    if (value == null) return '0';
    return NumberFormat('#,##0').format(value);
  }

  String _expenseSummary(String monthYear) {
    if (_isCurrentMonth(monthYear)) return '';
    final budget = budgetByMonth[monthYear]?['monthly_budget'] as num? ?? 0;
    final goalTarget = goalByMonth[monthYear]?['target_amount'] as num? ?? 0;
    final totalExpenses = totalExpensesByMonth[monthYear] ?? 0;

    if (totalExpenses > budget) return 'budget_surpassed';
    if (goalTarget == 0 || totalExpenses > (budget - goalTarget)) {
      return 'goal_not_met';
    }
    return 'goal_met';
  }

  bool _isFutureMonth(String monthYear) {
    final [year, month] = monthYear.split('-').map(int.parse).toList();
    return year > currentYear || (year == currentYear && month > currentMonth);
  }

  bool _isCurrentMonth(String monthYear) {
    final [year, month] = monthYear.split('-').map(int.parse).toList();
    return year == currentYear && month == currentMonth;
  }

  bool _hasExpenseHistory() {
    return expensesByMonth.values.any((expenses) => expenses.isNotEmpty);
  }

  String _getCurrentPageYear() {
    return sortedMonths.isNotEmpty
        ? sortedMonths[0].split('-')[0]
        : currentYear.toString();
  }

  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth < 400) {
      return 1;
    } else if (screenWidth < 600) {
      return 2;
    } else if (screenWidth < 900) {
      return 3;
    } else {
      return 4;
    }
  }

  double _calculateChildAspectRatio(double screenWidth, int crossAxisCount) {
    double baseWidth = screenWidth / crossAxisCount;
    double baseHeight = 120;
    return baseWidth / baseHeight;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);
    final childAspectRatio = _calculateChildAspectRatio(
      screenWidth,
      crossAxisCount,
    );

    return Scaffold(
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
      body: SingleChildScrollView(
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
                alignment: Alignment.center,
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
                            Icons.history,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Expense History',
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
                          'Review your past expenses',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  if (isLoading)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isLoading) ...[
                    if (message != null)
                      AlertMessage(
                        message: message!,
                        type:
                            messageType == 'error'
                                ? MessageType.error
                                : MessageType.success,
                        onDismiss:
                            () => setState(() {
                              message = null;
                              messageType = null;
                            }),
                      ),
                    if (!_hasExpenseHistory())
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD1DBE5)),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No expense history recorded yet.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    if (sortedMonths.isNotEmpty) ...[
                      Text(
                        _getCurrentPageYear(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ..._getMonthsForCurrentPage().map((monthYear) {
                        final expenses = expensesByMonth[monthYear] ?? [];
                        final totalExpenses = totalExpensesByMonth[monthYear];
                        final isCurrent = _isCurrentMonth(monthYear);
                        final showBudgetAndGoal =
                            totalExpenses != null &&
                            totalExpenses > 0 &&
                            !isCurrent;

                        return Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: const Color(0xFFF8F9FA),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    monthYear,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (totalExpenses != null &&
                                          totalExpenses > 0)
                                        Text(
                                          'Total: E£${_formatNumber(totalExpenses)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _expenseSummary(monthYear) ==
                                                        'goal_met'
                                                    ? Colors.green
                                                    : _expenseSummary(
                                                          monthYear,
                                                        ) ==
                                                        'goal_not_met'
                                                    ? Colors.orange
                                                    : _expenseSummary(
                                                          monthYear,
                                                        ) ==
                                                        'budget_surpassed'
                                                    ? Colors.red
                                                    : Colors.black,
                                          ),
                                        )
                                      else if (isCurrent)
                                        const Text(
                                          'Tracking ongoing 🚀',
                                          style: TextStyle(fontSize: 14),
                                        )
                                      else if (_isFutureMonth(monthYear))
                                        const Text(
                                          'Plan ahead 📅',
                                          style: TextStyle(fontSize: 14),
                                        )
                                      else
                                        const Text(
                                          'Nothing recorded 📂',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Budget and Goal Info
                                      if (isCurrent)
                                        const Text(
                                          'Current month - Expenses are not displayed',
                                          style: TextStyle(color: Colors.grey),
                                        )
                                      else if (expenses.isNotEmpty) ...[
                                        if (showBudgetAndGoal) ...[
                                          if (budgetByMonth[monthYear] != null)
                                            Text(
                                              'Budget: E£${_formatNumber(budgetByMonth[monthYear]!['monthly_budget'])}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          else
                                            const Text(
                                              'Budget: No budget was set for this month.',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          if (goalByMonth[monthYear] != null)
                                            Text(
                                              'Goal: ${goalByMonth[monthYear]!['name']} - E£${_formatNumber(goalByMonth[monthYear]!['target_amount'])}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          else
                                            const Text(
                                              'Goal: No goal was set for this month.',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          if (goalByMonth[monthYear] != null &&
                                              _expenseSummary(monthYear) ==
                                                  'goal_met')
                                            AlertMessage(
                                              message:
                                                  'Goal Achieved! You\'ve successfully reached your financial goal this month. 🎉',
                                              type: MessageType.success,
                                            ),
                                          if (goalByMonth[monthYear] != null &&
                                              _expenseSummary(monthYear) ==
                                                  'goal_not_met')
                                            AlertMessage(
                                              message:
                                                  'Goal Not Met! Unfortunately, the financial goal this month wasn\'t reached.',
                                              type: MessageType.warning,
                                            ),
                                          if (budgetByMonth[monthYear] !=
                                                  null &&
                                              _expenseSummary(monthYear) ==
                                                  'budget_surpassed')
                                            AlertMessage(
                                              message:
                                                  'Budget Exceeded! You\'ve gone over your budget this month. ⚠️',
                                              type: MessageType.error,
                                            ),
                                          if (budgetByMonth[monthYear] !=
                                                  null ||
                                              goalByMonth[monthYear] != null)
                                            const SizedBox(height: 16),
                                        ],
                                        GridView.count(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: childAspectRatio,
                                          children:
                                              expenses.map((expense) {
                                                return Card(
                                                  elevation: 4,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Text(
                                                          'Category: ${expense['category'] ?? 'Unknown'}',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                        Text(
                                                          'Amount: E£${_formatNumber(expense['amount'])}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                              ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                        Text(
                                                          'Date: ${expense['date'] ?? 'Unknown'}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                              ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ] else
                                        Text(
                                          _isFutureMonth(monthYear)
                                              ? 'Upcoming month - No expenses recorded yet'
                                              : 'No expenses recorded for this month',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (totalPages > 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed:
                                  currentPage > 1
                                      ? () => _changePage(currentPage - 1)
                                      : null,
                            ),
                            for (int page in List.generate(
                              totalPages,
                              (index) => index + 1,
                            ))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: ElevatedButton(
                                  onPressed: () => _changePage(page),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        currentPage == page
                                            ? Colors.blue
                                            : Colors.grey[200],
                                    foregroundColor:
                                        currentPage == page
                                            ? Colors.white
                                            : Colors.black,
                                    minimumSize: const Size(40, 40),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text('$page'),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed:
                                  currentPage < totalPages
                                      ? () => _changePage(currentPage + 1)
                                      : null,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusing AlertMessage from previous screens
enum MessageType {
  // Green for success - Orange for warning - Red for error
  success,
  warning,
  error,
}

class AlertMessage extends StatelessWidget {
  final String message;
  final MessageType type;
  final VoidCallback? onDismiss;

  const AlertMessage({
    super.key,
    required this.message,
    required this.type,
    this.onDismiss,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case MessageType.success:
        return Colors.green[50]!;
      case MessageType.warning:
        return Colors.orange[50]!;
      case MessageType.error:
        return Colors.red[50]!;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case MessageType.success:
        return Colors.green;
      case MessageType.warning:
        return Colors.orange;
      case MessageType.error:
        return Colors.red;
    }
  }

  Color _getIconAndTextColor() {
    switch (type) {
      case MessageType.success:
        return Colors.green;
      case MessageType.warning:
        return Colors.orange;
      case MessageType.error:
        return Colors.red;
    }
  }

  Color _getDarkTextColor() {
    switch (type) {
      case MessageType.success:
        return Colors.green[900]!;
      case MessageType.warning:
        return Colors.orange[900]!;
      case MessageType.error:
        return Colors.red[900]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(), width: 1),
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
            type == MessageType.success
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: _getIconAndTextColor(),
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _getDarkTextColor(), fontSize: 14),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: _getIconAndTextColor(),
            ),
        ],
      ),
    );
  }
}
