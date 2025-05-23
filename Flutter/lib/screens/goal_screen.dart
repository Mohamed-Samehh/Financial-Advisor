import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../screens/navbar.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  GoalScreenState createState() => GoalScreenState();
}

class GoalScreenState extends State<GoalScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> goal = {'id': null, 'name': '', 'target_amount': null};
  Map<String, dynamic> budget = {'id': null, 'monthly_budget': null};
  String? message;
  String? messageType; // 'success' or 'error'
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgetAndGoal();
  }

  void _loadBudgetAndGoal() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final budgetResponse = await apiService.getBudget();
      setState(() {
        budget =
            budgetResponse['budget'] != null
                ? {
                  'id': budgetResponse['budget']['id'],
                  'monthly_budget':
                      budgetResponse['budget']['monthly_budget'].toString(),
                }
                : {'id': null, 'monthly_budget': null};
        _loadGoal();
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _loadGoal() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final goalResponse = await apiService.getGoal();
      setState(() {
        goal =
            goalResponse['goal'] != null
                ? {
                  'id': goalResponse['goal']['id'],
                  'name': goalResponse['goal']['name'],
                  'target_amount':
                      goalResponse['goal']['target_amount'].toString(),
                }
                : {'id': null, 'name': '', 'target_amount': null};
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _formatNumber(String? value) {
    if (value == null || value.isEmpty) return '0';
    double numValue = double.tryParse(value) ?? 0;
    double dividedValue = numValue / 1000;
    if (dividedValue % 1 == 0) {
      return '${dividedValue.toInt()}k';
    }
    return '${dividedValue.toStringAsFixed(2)}k';
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        message = null;
        messageType = null;
      });
      final apiService = Provider.of<ApiService>(context, listen: false);
      final targetAmount = double.parse(goal['target_amount']);
      final monthlyBudget =
          budget['monthly_budget'] != null
              ? double.parse(budget['monthly_budget'])
              : null;

      if (monthlyBudget == null) {
        setState(() {
          message = 'Please set a budget before setting a goal.';
          messageType = 'error';
          isLoading = false;
        });
        return;
      }

      if (targetAmount >= monthlyBudget) {
        setState(() {
          message = 'Goal cannot be equal or more than the budget.';
          messageType = 'error';
          isLoading = false;
        });
        return;
      }

      try {
        if (goal['id'] != null) {
          final response = await apiService.updateGoal({
            'name': goal['name'],
            'target_amount': targetAmount,
          }, goal['id']);
          setState(() {
            goal = {
              'id': response['goal']['id'],
              'name': response['goal']['name'],
              'target_amount': response['goal']['target_amount'].toString(),
            };
            message = 'Goal updated successfully!';
            messageType = 'success';
            isLoading = false;
          });
        } else {
          final response = await apiService.addGoal({
            'name': goal['name'],
            'target_amount': targetAmount,
          });
          setState(() {
            goal = {
              'id': response['goal']['id'],
              'name': response['goal']['name'],
              'target_amount': response['goal']['target_amount'].toString(),
            };
            message = 'Goal set successfully!';
            messageType = 'success';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          message =
              'Error ${goal['id'] != null ? 'updating' : 'adding'} goal. Please try again.';
          messageType = 'error';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        message = 'Please fill in all required fields correctly.';
        messageType = 'error';
      });
    }
  }

  void _deleteGoal(int goalId) async {
    setState(() => isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.deleteGoal(goalId);
      setState(() {
        goal = {'id': null, 'name': '', 'target_amount': null};
        message = 'Goal deleted successfully!';
        messageType = 'success';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        message = 'Error deleting goal. Please try again.';
        messageType = 'error';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            Icons.track_changes,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Set Your Goal',
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
                          'Define your financial targets',
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
                  if (!isLoading && budget['id'] == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD1DBE5)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.lock, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No budget set! Please set a budget before setting a goal.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  if (!isLoading && budget['id'] != null) ...[
                    Card(
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
                          children: [
                            if (message != null)
                              AlertMessage(
                                message: message!,
                                isError: messageType == 'error',
                                onDismiss:
                                    () => setState(() {
                                      message = null;
                                      messageType = null;
                                    }),
                              ),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Goal Name',
                                      labelStyle: const TextStyle(
                                        color: Colors.blueGrey,
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
                                    initialValue: goal['name'],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Goal Name is required';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) => goal['name'] = value,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Target Amount',
                                      labelStyle: const TextStyle(
                                        color: Colors.blueGrey,
                                      ),
                                      prefixText: 'E£ ',
                                      prefixStyle: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
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
                                    keyboardType: TextInputType.number,
                                    initialValue:
                                        goal['target_amount']?.toString() ?? '',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Target Amount is required';
                                      }
                                      final numValue = double.tryParse(value);
                                      if (numValue == null || numValue <= 0) {
                                        return 'Target Amount must be greater than 0';
                                      }
                                      return null;
                                    },
                                    onChanged:
                                        (value) =>
                                            goal['target_amount'] = value,
                                  ),
                                  const SizedBox(height: 16),
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
                                      onPressed: _submit,
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
                                      child: Text(
                                        goal['id'] != null
                                            ? 'Update Goal'
                                            : 'Set Goal',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your Goal:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (goal['id'] == null)
                      const Text(
                        'No goal set for this month.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Current Month\'s Goal: E£${_formatNumber(goal['target_amount'])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                  fontSize: 16,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteGoal(goal['id']),
                            ),
                          ],
                        ),
                      ),
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

// Reusing AlertMessage from BudgetScreen
class AlertMessage extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const AlertMessage({
    super.key,
    required this.message,
    required this.isError,
    this.onDismiss,
  });

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
              '${isError ? 'Oops!' : 'Awesome!'} $message',
              style: TextStyle(
                color: isError ? Colors.red[900] : Colors.green[900],
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: isError ? Colors.red : Colors.green,
            ),
        ],
      ),
    );
  }
}
