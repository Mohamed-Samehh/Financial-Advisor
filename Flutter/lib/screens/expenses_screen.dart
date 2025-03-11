import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../screens/navbar.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ExpensesScreenState createState() => ExpensesScreenState();
}

class ExpensesScreenState extends State<ExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> expenses = [];
  Map<String, dynamic> form = {
    'category': '',
    'amount': null,
    'date': null,
    'description': '',
  };
  String? message;
  String? messageType; // 'success' or 'error'
  bool isLoading = false;
  bool isEditing = false;
  int? editingExpenseId;
  List<String> categories = [];
  String sortKey = 'date'; // Sorting based on 'date' or 'amount'
  int currentPage = 1;
  final int itemsPerPage = 8;
  List<Map<String, dynamic>> paginatedExpenses = [];
  int totalPages = 0;

  late String minDate;
  late String maxDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final year = today.year;
    final month = today.month;
    minDate = '$year-${month.toString().padLeft(2, '0')}-01';
    maxDate = _setLastDayOfMonth(month - 1, year); // Month is 0-indexed
    _loadExpenses();
    _loadCategories();
  }

  String _setLastDayOfMonth(int month, int year) {
    int lastDay;
    if (month == 1) {
      // February
      lastDay =
          (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    } else if ([3, 5, 8, 10].contains(month)) {
      // April, June, September, November
      lastDay = 30;
    } else {
      // January, March, May, July, August, October, December
      lastDay = 31;
    }
    return '$year-${(month + 1).toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
  }

  void _loadExpenses() async {
    setState(() => isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.getExpenses();
      setState(() {
        expenses = List<Map<String, dynamic>>.from(response['expenses'] ?? []);
        _sortExpenses();
        totalPages = (expenses.length / itemsPerPage).ceil();
        _updatePaginatedExpenses();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        expenses = [];
        isLoading = false;
      });
    }
  }

  void _loadCategories() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.getCategories();
      setState(() {
        categories = List<String>.from(response.map((cat) => cat['name']));
      });
    } catch (e) {
      setState(() => categories = []);
    }
  }

  void _sortExpenses() {
    expenses.sort((a, b) {
      if (sortKey == 'date') {
        return DateTime.parse(
          b['date'],
        ).compareTo(DateTime.parse(a['date'])); // Latest first
      } else if (sortKey == 'amount') {
        return (b['amount'] as num).compareTo(
          a['amount'] as num,
        ); // Highest first
      }
      return 0;
    });
    _updatePaginatedExpenses();
  }

  String _formatNumber(num? value) {
    if (value == null) return '0';
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  void _updatePaginatedExpenses() {
    final start = (currentPage - 1) * itemsPerPage;
    setState(() {
      paginatedExpenses = expenses.sublist(
        start,
        start + itemsPerPage > expenses.length
            ? expenses.length
            : start + itemsPerPage,
      );
    });
  }

  void _changePage(int page) {
    if (page < 1 || page > totalPages) return;
    setState(() {
      currentPage = page;
      _updatePaginatedExpenses();
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (form['category'] == null || form['category'].isEmpty) {
        setState(() {
          message = 'Category seems to be empty.';
          messageType = 'error';
          isLoading = false;
        });
        return;
      }

      final date = form['date'] != null ? DateTime.parse(form['date']) : null;
      final firstDay = DateTime(DateTime.now().year, DateTime.now().month, 1);
      if (date == null ||
          date.isBefore(firstDay) ||
          date.isAfter(DateTime.parse(maxDate))) {
        setState(() {
          message = 'Date must be within the current month.';
          messageType = 'error';
          isLoading = false;
        });
        return;
      }

      final tempExpense = {
        'id': editingExpenseId,
        'category': form['category'] ?? 'No category',
        'amount': double.parse(form['amount']),
        'date': form['date'] ?? DateTime.now().toIso8601String().split('T')[0],
        'description': form['description'] ?? 'No description',
        'isRecentlyAdded': !isEditing,
      };

      final apiService = Provider.of<ApiService>(context, listen: false);
      try {
        if (isEditing && editingExpenseId != null) {
          await apiService.updateExpense(tempExpense, editingExpenseId!);
          setState(() {
            message = 'Expense updated successfully!';
            messageType = 'success';
            isEditing = false;
            editingExpenseId = null;
            form = {
              'category': '',
              'amount': null,
              'date': null,
              'description': '',
            };
          });
        } else {
          setState(() {
            expenses.insert(0, tempExpense);
            _sortExpenses();
            totalPages = (expenses.length / itemsPerPage).ceil();
          });
          await apiService.addExpense(tempExpense);
          setState(() {
            message = 'Expense added successfully!';
            messageType = 'success';
            form = {
              'category': '',
              'amount': null,
              'date': null,
              'description': '',
            };
          });
        }
        _loadExpenses(); // Refresh from server
      } catch (e) {
        if (!isEditing) {
          setState(() {
            expenses.removeAt(0);
            _sortExpenses();
            totalPages = (expenses.length / itemsPerPage).ceil();
          });
        }
        setState(() {
          message =
              'Error ${isEditing ? 'updating' : 'adding'} expense. Please try again.';
          messageType = 'error';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        message = 'Please fill out all required fields correctly.';
        messageType = 'error';
      });
    }
  }

  void _editExpense(Map<String, dynamic> expense) {
    if (expense['isRecentlyAdded'] == true) return;
    setState(() {
      if (isEditing && editingExpenseId == expense['id']) {
        isEditing = false;
        editingExpenseId = null;
        form = {
          'category': '',
          'amount': null,
          'date': null,
          'description': '',
        };
      } else {
        isEditing = true;
        editingExpenseId = expense['id'];
        form = {
          'category': expense['category'],
          'amount': expense['amount'].toString(),
          'date': expense['date'],
          'description': expense['description'],
        };
      }
    });
  }

  void _deleteExpense(int expenseId) async {
    final expense = expenses.firstWhere(
      (exp) => exp['id'] == expenseId,
      orElse: () => {},
    );
    if (expense['isRecentlyAdded'] == true) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      await apiService.deleteExpense(expenseId);
      setState(() {
        expenses.removeWhere((exp) => exp['id'] == expenseId);
        totalPages = (expenses.length / itemsPerPage).ceil();
        _updatePaginatedExpenses();
        message = 'Expense deleted successfully!';
        messageType = 'success';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        message = 'Error deleting expense. Please try again.';
        messageType = 'error';
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          form['date'] != null ? DateTime.parse(form['date']) : DateTime.now(),
      firstDate: DateTime.parse(minDate),
      lastDate: DateTime.parse(maxDate),
    );
    if (picked != null) {
      setState(() {
        form['date'] = picked.toIso8601String().split('T')[0];
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
                    Icons.receipt,
                    size: 80,
                    color: Colors.white.withAlpha(230),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Track Your Expenses',
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
                    'Monitor your daily expenses',
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
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.85,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Theme.of(context).focusColor ==
                                                    Colors.blueAccent
                                                ? Colors.blueAccent
                                                : Colors.grey,
                                        width: 2,
                                      ),
                                      color: Color.fromRGBO(33, 150, 243, 0.05),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value:
                                            form['category'].isEmpty
                                                ? null
                                                : form['category'],
                                        hint: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            'Category',
                                            style: TextStyle(
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ),
                                        items:
                                            categories.map((category) {
                                              return DropdownMenuItem<String>(
                                                value: category,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                  child: Text(
                                                    category,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                        onChanged:
                                            (value) => setState(
                                              () =>
                                                  form['category'] =
                                                      value ?? '',
                                            ),
                                        isExpanded: true,
                                        icon: const Padding(
                                          padding: EdgeInsets.only(right: 10),
                                          child: Icon(
                                            Icons.arrow_drop_down,
                                            size: 24,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.85,
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Amount',
                                        labelStyle: const TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                        prefixText: 'E£ ',
                                        prefixStyle: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                          form['amount']?.toString() ?? '',
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Amount is required.';
                                        }
                                        final numValue = double.tryParse(value);
                                        if (numValue == null || numValue <= 0) {
                                          return 'Amount must be greater than 0.';
                                        }
                                        return null;
                                      },
                                      onChanged:
                                          (value) => form['amount'] = value,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.85,
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Date',
                                        labelStyle: const TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.calendar_today,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () => _selectDate(context),
                                        ),
                                      ),
                                      readOnly: true,
                                      controller: TextEditingController(
                                        text: form['date'],
                                      ),
                                      validator:
                                          (value) =>
                                              value == null || value.isEmpty
                                                  ? 'Date is required.'
                                                  : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.85,
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: 'Description',
                                        labelStyle: const TextStyle(
                                          color: Colors.blueGrey,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                      maxLength: 100,
                                      maxLines: 2,
                                      initialValue: form['description'],
                                      onChanged:
                                          (value) =>
                                              form['description'] = value,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.85,
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
                                        isEditing
                                            ? 'Update Expense'
                                            : 'Add Expense',
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
                      'Your Expenses:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (expenses.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
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
                          children: [
                            const Text(
                              'Sort Expenses:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: sortKey,
                              items: const [
                                DropdownMenuItem(
                                  value: 'date',
                                  child: Text('Date (Latest)'),
                                ),
                                DropdownMenuItem(
                                  value: 'amount',
                                  child: Text('Amount (Highest)'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    sortKey = value;
                                    _sortExpenses();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paginatedExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = paginatedExpenses[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
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
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${expense['category']}: E£${_formatNumber(expense['amount'])} on ${_formatDate(expense['date'])}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        expense['description'] ??
                                            'No description',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      if (expense['isRecentlyAdded'] == true)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Recently Added',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      if (isEditing &&
                                          editingExpenseId == expense['id'])
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Editing...',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: FaIcon(
                                    FontAwesomeIcons.pencil,
                                    color:
                                        isEditing &&
                                                editingExpenseId ==
                                                    expense['id']
                                            ? Colors.orange
                                            : Colors.blue,
                                  ),
                                  onPressed:
                                      expense['isRecentlyAdded'] == true
                                          ? null
                                          : () => _editExpense(expense),
                                ),
                                IconButton(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.trash,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      expense['isRecentlyAdded'] == true
                                          ? null
                                          : () => _deleteExpense(expense['id']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
                    if (expenses.isEmpty)
                      const Text(
                        'No expenses found for this month.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
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

  String _formatDate(String date) {
    final DateTime parsed = DateTime.parse(date);
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }
}

// Reusing AlertMessage from previous screens
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
