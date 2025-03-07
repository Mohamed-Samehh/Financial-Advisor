import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../screens/navbar.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> categories = [];
  Map<String, dynamic> form = {'name': '', 'priority': null, 'id': null};
  Map<String, dynamic> addForm = {'name': '', 'priority': null};
  String? message;
  String? messageType; // 'success' or 'error'
  bool isLoading = false;
  bool isUpdating = false;
  bool isAdding = false;
  Map<String, String?> errorMessages = {'name': null, 'priority': null};
  bool isLabelView = false;
  List<Map<String, dynamic>>? suggestedCategories;
  String? firstMonthSuggested;
  String? lastMonthSuggested;
  List<Map<String, dynamic>>? labeledCategories;
  String? firstMonthLabeled;
  String? lastMonthLabeled;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSuggestedCategories();
    _loadLabeledCategories();
  }

  void _loadCategories() async {
    setState(() => isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.getCategories();
      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        categories = [];
        isLoading = false;
      });
      print('Failed to load categories: $e');
    }
  }

  void _loadSuggestedCategories() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.getCategorySuggestions();
      if (response['suggested_priorities'] != null &&
          response['suggested_priorities'].isNotEmpty) {
        setState(() {
          suggestedCategories = List<Map<String, dynamic>>.from(
            response['suggested_priorities'],
          );
          firstMonthSuggested = response['first_month_suggested'];
          lastMonthSuggested = response['last_month_suggested'];
        });
      } else {
        setState(() {
          suggestedCategories = null;
          firstMonthSuggested = null;
          lastMonthSuggested = null;
        });
      }
    } catch (e) {
      setState(() {
        suggestedCategories = null;
        firstMonthSuggested = null;
        lastMonthSuggested = null;
      });
      print('Failed to load suggested categories: $e');
    }
  }

  void _loadLabeledCategories() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.getCategoryLabels();
      if (response['labaled_categories'] != null &&
          response['labaled_categories'].isNotEmpty) {
        final labelData = response['labaled_categories'][0];
        setState(() {
          labeledCategories = List<Map<String, dynamic>>.from(
            labelData['predicted_importance'].map(
              (item) => {
                'category': item['category'],
                'predicted_importance': item['predicted_importance'],
              },
            ),
          );
          firstMonthLabeled = response['first_month_labeled'];
          lastMonthLabeled = response['last_month_labeled'];
          if (suggestedCategories == null || suggestedCategories!.isEmpty) {
            isLabelView = true;
          }
        });
      } else {
        setState(() {
          labeledCategories = null;
          firstMonthLabeled = null;
          lastMonthLabeled = null;
        });
      }
    } catch (e) {
      setState(() {
        labeledCategories = null;
        firstMonthLabeled = null;
        lastMonthLabeled = null;
      });
      print('Failed to load labeled categories: $e');
    }
  }

  bool _checkDuplicates(String name, {int? excludeId}) {
    final trimmedName = name.trim().toLowerCase();
    return categories.any(
      (category) =>
          category['name'].trim().toLowerCase() == trimmedName &&
          (excludeId == null || category['id'] != excludeId),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        errorMessages = {'name': null, 'priority': null};
        message = null;
        messageType = null;
      });

      if (_checkDuplicates(form['name'], excludeId: form['id'])) {
        setState(() => errorMessages['name'] = 'Category name already exists.');
        return;
      }

      final priority = int.tryParse(form['priority']?.toString() ?? '');
      final maxPriority = categories.length;
      if (priority != null && priority > maxPriority) {
        setState(
          () =>
              errorMessages['priority'] =
                  'Priority cannot be greater than $maxPriority.',
        );
        return;
      }

      if (errorMessages['name'] != null || errorMessages['priority'] != null) {
        setState(() {
          message = 'Please fix the errors before submitting.';
          messageType = 'error';
        });
        return;
      }

      final apiService = Provider.of<ApiService>(context, listen: false);
      try {
        await apiService.updateCategory({
          'name': form['name'],
          'priority': priority,
        }, form['id']);
        setState(() {
          message = 'Category updated successfully!';
          messageType = 'success';
          isUpdating = false;
          form = {'name': '', 'priority': null, 'id': null};
        });
        _loadCategories();
        _loadSuggestedCategories();
      } catch (e) {
        setState(() {
          message = 'An error occurred while updating the category.';
          messageType = 'error';
        });
        print('Failed to update category: $e');
      }
    }
  }

  void _addCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        errorMessages = {'name': null, 'priority': null};
        message = null;
        messageType = null;
      });

      if (_checkDuplicates(addForm['name'])) {
        setState(() => errorMessages['name'] = 'Category name already exists.');
        return;
      }

      final priority = int.tryParse(addForm['priority']?.toString() ?? '');
      final maxPriority = categories.length + 1;
      if (priority != null && priority > maxPriority) {
        setState(
          () =>
              errorMessages['priority'] =
                  'Priority cannot be greater than $maxPriority.',
        );
        return;
      }

      if (errorMessages['name'] != null || errorMessages['priority'] != null) {
        setState(() {
          message = 'Please fix the errors before submitting.';
          messageType = 'error';
        });
        return;
      }

      final apiService = Provider.of<ApiService>(context, listen: false);
      try {
        await apiService.addCategory({
          'name': addForm['name'],
          'priority': priority,
        });
        setState(() {
          message = 'Category added successfully!';
          messageType = 'success';
          isAdding = false;
          addForm = {'name': '', 'priority': null};
        });
        _loadCategories();
        _loadSuggestedCategories();
      } catch (e) {
        setState(() {
          message = 'An error occurred while adding the category.';
          messageType = 'error';
        });
        print('Failed to add category: $e');
      }
    }
  }

  void _toggleAddForm() {
    setState(() {
      isAdding = !isAdding;
      if (isAdding) {
        isUpdating = false;
      } else {
        addForm = {'name': '', 'priority': null};
        errorMessages = {'name': null, 'priority': null};
      }
    });
  }

  void _editCategory(Map<String, dynamic> category) {
    setState(() {
      if (isUpdating && form['id'] == category['id']) {
        isUpdating = false;
        form = {'name': '', 'priority': null, 'id': null};
      } else {
        form = Map.from(category);
        isUpdating = true;
      }
    });
  }

  void _deleteCategoryWithConfirmation(int categoryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Deleting this category will move its all-time expenses to a new category. This change is permanent. Do you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final TextEditingController controller = TextEditingController();
      final newCategory = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('New Category Name'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter new category name',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text('OK'),
                ),
              ],
            ),
      );

      if (newCategory != null && newCategory.isNotEmpty) {
        final apiService = Provider.of<ApiService>(context, listen: false);
        try {
          await apiService.deleteCategory(categoryId, newCategory);
          setState(() {
            message = 'Category deleted and expenses reassigned successfully!';
            messageType = 'success';
          });
          _loadCategories();
          _loadSuggestedCategories();
        } catch (e) {
          setState(() {
            message = 'An error occurred while deleting the category.';
            messageType = 'error';
          });
          print('Failed to delete category: $e');
        }
      } else {
        setState(() {
          message = 'No category name entered. Deletion cancelled.';
          messageType = 'error';
        });
      }
    } else {
      setState(() {
        message = 'Category deletion was cancelled.';
        messageType = 'error';
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
                  const Icon(Icons.list, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Manage Categories',
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
                    'Organize your categories effectively.',
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
                  if (!isLoading)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Text(
                        'Tip: Assign priorities based on the importance of each category to your financial goals. Higher priority should be given to the most essential categories.',
                        style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => isLabelView = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                !isLabelView ? Colors.blue : Colors.transparent,
                            foregroundColor:
                                !isLabelView ? Colors.white : Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: FaIcon(
                                  FontAwesomeIcons.arrowLeft,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Suggestions'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => setState(() => isLabelView = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isLabelView ? Colors.blue : Colors.transparent,
                            foregroundColor:
                                isLabelView ? Colors.white : Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Text('Importance'),
                              SizedBox(width: 8),
                              Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: FaIcon(
                                  FontAwesomeIcons.arrowRight,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isLabelView)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Suggested Category Priorities',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey,
                              ),
                            ),
                            if (firstMonthSuggested != null &&
                                lastMonthSuggested != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Based on your average monthly expenses from $firstMonthSuggested to $lastMonthSuggested',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            if (suggestedCategories != null &&
                                suggestedCategories!.isNotEmpty)
                              Center(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenWidth =
                                        MediaQuery.of(context).size.width;
                                    const minCardWidth = 150.0;
                                    final crossAxisCount = (screenWidth /
                                            minCardWidth)
                                        .floor()
                                        .clamp(2, 3);
                                    final maxGridWidth =
                                        minCardWidth * crossAxisCount +
                                        (crossAxisCount - 1) * 12;

                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            maxGridWidth > screenWidth
                                                ? screenWidth - 32
                                                : maxGridWidth,
                                      ),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: minCardWidth,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 0.85,
                                            ),
                                        itemCount: suggestedCategories!.length,
                                        itemBuilder: (context, index) {
                                          final category =
                                              suggestedCategories![index];
                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blueGrey
                                                      .withOpacity(0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                // Header with Category Name
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 12,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.blueAccent
                                                            .withOpacity(0.9),
                                                        Colors.blue.withOpacity(
                                                          0.7,
                                                        ),
                                                      ],
                                                      begin:
                                                          Alignment.topCenter,
                                                      end:
                                                          Alignment
                                                              .bottomCenter,
                                                    ),
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            16,
                                                          ),
                                                        ),
                                                  ),
                                                  child: Text(
                                                    category['category'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                // Body with Details
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .monetization_on,
                                                              size: 16,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'E£${NumberFormat('#,##0').format(category['average_expenses'].toInt())}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .grey[800],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .blue[100],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'Priority: ${category['suggested_priority']}',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  Colors
                                                                      .blueAccent,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 48,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'This feature is not available for you yet.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    if (isLabelView)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Category Importance Labeling',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey,
                              ),
                            ),
                            if (firstMonthLabeled != null &&
                                lastMonthLabeled != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Based on your average monthly expenses from $firstMonthLabeled to $lastMonthLabeled',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            if (labeledCategories != null &&
                                labeledCategories!.isNotEmpty)
                              Center(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenWidth =
                                        MediaQuery.of(context).size.width;
                                    const minCardWidth = 150.0;
                                    final crossAxisCount = (screenWidth /
                                            minCardWidth)
                                        .floor()
                                        .clamp(2, 3);
                                    final maxGridWidth =
                                        minCardWidth * crossAxisCount +
                                        (crossAxisCount - 1) * 12;

                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            maxGridWidth > screenWidth
                                                ? screenWidth - 32
                                                : maxGridWidth,
                                      ),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: minCardWidth,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 0.85,
                                            ),
                                        itemCount: labeledCategories!.length,
                                        itemBuilder: (context, index) {
                                          final category =
                                              labeledCategories![index];
                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blueGrey
                                                      .withOpacity(0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 12,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.blueAccent
                                                            .withOpacity(0.9),
                                                        Colors.blue.withOpacity(
                                                          0.7,
                                                        ),
                                                      ],
                                                      begin:
                                                          Alignment.topCenter,
                                                      end:
                                                          Alignment
                                                              .bottomCenter,
                                                    ),
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            16,
                                                          ),
                                                        ),
                                                  ),
                                                  child: Text(
                                                    category['category'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons.star,
                                                              size: 16,
                                                              color:
                                                                  Colors.amber,
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              'Importance',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .grey[800],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .blue[100],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            '${category['predicted_importance']}',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  Colors
                                                                      .blueAccent,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 48,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'This feature is not available for you yet.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    if (isAdding || isUpdating)
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Category Name',
                                    labelStyle: const TextStyle(
                                      color: Colors.blueGrey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                  initialValue:
                                      isAdding ? addForm['name'] : form['name'],
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Category name is required.';
                                    return null;
                                  },
                                  onChanged:
                                      (value) => setState(
                                        () =>
                                            (isAdding
                                                    ? addForm
                                                    : form)['name'] =
                                                value,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Priority',
                                    labelStyle: const TextStyle(
                                      color: Colors.blueGrey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                      (isAdding
                                              ? addForm['priority']
                                              : form['priority'])
                                          ?.toString() ??
                                      '',
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Priority is required.';
                                    final numValue = int.tryParse(value);
                                    if (numValue == null || numValue <= 0)
                                      return 'Priority must be greater than 0.';
                                    return null;
                                  },
                                  onChanged:
                                      (value) => setState(
                                        () =>
                                            (isAdding
                                                    ? addForm
                                                    : form)['priority'] =
                                                value,
                                      ),
                                ),
                                if (errorMessages['name'] != null ||
                                    errorMessages['priority'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    errorMessages['name'] ??
                                        errorMessages['priority']!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.blue, Colors.blueAccent],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        isAdding ? _addCategory : _submit,
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
                                    child: Text(
                                      isAdding
                                          ? 'Add Category'
                                          : 'Update Category',
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
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Categories:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _toggleAddForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdding ? Colors.red : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            isAdding
                                ? FontAwesomeIcons.circleXmark
                                : FontAwesomeIcons.circlePlus,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAdding ? 'Cancel' : 'Add Category',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (categories.isEmpty)
                      const Text(
                        'No categories available.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
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
                              children: [
                                if (category['priority'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const FaIcon(
                                          FontAwesomeIcons.star,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          category['priority'].toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Priority not set',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isUpdating && form['id'] == category['id'])
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'Editing...',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                IconButton(
                                  icon: FaIcon(
                                    FontAwesomeIcons.pencil,
                                    color:
                                        isUpdating &&
                                                form['id'] == category['id']
                                            ? Colors.orange
                                            : Colors.blue,
                                  ),
                                  onPressed: () => _editCategory(category),
                                ),
                                IconButton(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.trash,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _deleteCategoryWithConfirmation(
                                        category['id'],
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
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
