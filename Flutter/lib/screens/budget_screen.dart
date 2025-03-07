import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../screens/navbar.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> budget = {'id': null, 'monthly_budget': null};
  Map<String, dynamic> goal = {'id': null, 'name': '', 'target_amount': null};
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
        if (budget['id'] != null) {
          _loadGoal();
        } else {
          isLoading = false;
        }
      });
    } catch (e) {
      print('Failed to load budget: $e');
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
      print('Failed to load goal: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatNumber(String? value) {
    if (value == null || value.isEmpty) return '0';
    return value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        message = null;
        messageType = null;
      });
      final apiService = Provider.of<ApiService>(context, listen: false);
      try {
        if (budget['id'] != null) {
          final response = await apiService.updateBudget({
            'monthly_budget': double.parse(budget['monthly_budget']),
          }, budget['id']);
          setState(() {
            budget = {
              'id': response['budget']['id'],
              'monthly_budget': response['budget']['monthly_budget'].toString(),
            };
            message = 'Budget updated successfully!';
            messageType = 'success';
            isLoading = false;
          });
        } else {
          final response = await apiService.addBudget({
            'monthly_budget': double.parse(budget['monthly_budget']),
          });
          setState(() {
            budget = {
              'id': response['budget']['id'],
              'monthly_budget': response['budget']['monthly_budget'].toString(),
            };
            message = 'Budget set successfully!';
            messageType = 'success';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          message =
              'Error ${budget['id'] != null ? 'updating' : 'adding'} budget. Please try again.';
          messageType = 'error';
          isLoading = false;
        });
        print(
          'Failed to ${budget['id'] != null ? 'update' : 'add'} budget: $e',
        );
      }
    } else {
      setState(() {
        message = 'Please fill in all required fields correctly.';
        messageType = 'error';
      });
    }
  }

  void _deleteBudget(int budgetId) async {
    setState(() => isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.deleteBudget(budgetId);
      if (goal['id'] != null) {
        await _deleteGoal(goal['id']);
      }
      setState(() {
        budget = {'id': null, 'monthly_budget': null};
        message = 'Budget deleted successfully!';
        messageType = 'success';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        message = 'Error deleting budget. Please try again.';
        messageType = 'error';
        isLoading = false;
      });
      print('Failed to delete budget: $e');
    }
  }

  Future<void> _deleteGoal(int goalId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.deleteGoal(goalId);
      setState(() {
        goal = {'id': null, 'name': '', 'target_amount': null};
      });
    } catch (e) {
      print('Failed to delete goal: $e');
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
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Manage Your Budget',
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
                    'Set your monthly budget with ease.',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
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
                                      labelText: 'Monthly Budget',
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
                                      fillColor: Colors.blue.withOpacity(0.05),
                                    ),
                                    keyboardType: TextInputType.number,
                                    initialValue:
                                        budget['monthly_budget']?.toString() ??
                                        '',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Monthly Budget is required';
                                      }
                                      final numValue = double.tryParse(value);
                                      if (numValue == null || numValue <= 0) {
                                        return 'Monthly Budget must be greater than 0';
                                      }
                                      return null;
                                    },
                                    onChanged:
                                        (value) =>
                                            budget['monthly_budget'] = value,
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
                                        budget['id'] != null
                                            ? 'Update Budget'
                                            : 'Set Budget',
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
                      'Your Budget:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (budget['id'] == null)
                      const Text(
                        'No budget set for this month.',
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
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Month\'s Budget: E£${_formatNumber(budget['monthly_budget'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBudget(budget['id']),
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

// Reusing AlertMessage with dismiss functionality
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
