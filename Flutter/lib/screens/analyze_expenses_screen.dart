import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../screens/navbar.dart';

class AnalyzeExpensesScreen extends StatefulWidget {
  const AnalyzeExpensesScreen({super.key});

  @override
  AnalyzeExpensesScreenState createState() => AnalyzeExpensesScreenState();
}

class AnalyzeExpensesScreenState extends State<AnalyzeExpensesScreen> {
  Map<String, dynamic> analysis = {};
  bool isLoading = true;
  String? errorMessage;
  Map<String, double> categoryTotals = {};
  String selectedPredictionType = 'Total';
  int selectedMonths = 6;
  bool isSpendingClusteringView = true;
  bool isFrequencyClusteringView = false;
  bool isExpenseClusteringView = false;
  bool isAssociationRulesView = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => isLoading = true);

    try {
      final analysisResponse = await apiService.analyzeExpenses();
      final expensesResponse = await apiService.getExpenses();

      setState(() {
        analysis = analysisResponse;
        _calculateCategoryTotals(expensesResponse['expenses'] ?? []);
        isLoading = false;

        if ((analysis['spending_clustering'] ?? []).isEmpty) {
          isSpendingClusteringView = false;
          isFrequencyClusteringView = true;
        }
        if ((analysis['frequency_clustering'] ?? []).isEmpty) {
          isFrequencyClusteringView = false;
          isAssociationRulesView = true;
        }

        if (analysis['category_limits'] != null) {
          analysis['category_limits'].sort((a, b) {
            if (a['name'] == "Goal") return -1;
            if (b['name'] == "Goal") return 1;
            return (b['limit'] as num).compareTo(a['limit'] as num);
          });
        }

        if (analysis['association_rules'] != null) {
          analysis['association_rules'].sort(
            (a, b) =>
                (b['confidence'] as num).compareTo(a['confidence'] as num),
          );
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Missing data';
        isLoading = false;
      });
    }
  }

  void _calculateCategoryTotals(List<dynamic> expenses) {
    categoryTotals.clear();
    for (var expense in expenses) {
      categoryTotals[expense['category']] =
          (categoryTotals[expense['category']] ?? 0) +
          (expense['amount'] as num);
    }
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  double _getAccuracy() {
    final predictions =
        selectedPredictionType == 'Total'
            ? analysis['predictions']
            : analysis['category_predictions']?[selectedPredictionType];
    return (predictions?.isNotEmpty ?? false)
        ? (predictions[0]['accuracy'] as num) * 100
        : 0;
  }

  List<String> _getCategoryKeys() {
    return analysis['category_predictions'] != null
        ? (analysis['category_predictions'] as Map<String, dynamic>).keys
            .toList()
        : [];
  }

  void _goToPrevView() {
    setState(() {
      if (isAssociationRulesView) {
        isAssociationRulesView = false;
        isExpenseClusteringView = true;
      } else if (isExpenseClusteringView) {
        isExpenseClusteringView = false;
        isFrequencyClusteringView = true;
      } else if (isFrequencyClusteringView) {
        isFrequencyClusteringView = false;
        isSpendingClusteringView = true;
      }
    });
  }

  void _goToNextView() {
    setState(() {
      if (isSpendingClusteringView) {
        isSpendingClusteringView = false;
        isFrequencyClusteringView = true;
      } else if (isFrequencyClusteringView) {
        isFrequencyClusteringView = false;
        isExpenseClusteringView = true;
      } else if (isExpenseClusteringView) {
        isExpenseClusteringView = false;
        isAssociationRulesView = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
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
                    Icons.pie_chart,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analyze Your Expenses',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gain insights into your spending habits',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  if (isLoading)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: 5,
                          ),
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
                    )
                  else ...[
                    screenWidth < 600
                        ? Column(
                          children: [
                            _buildSummaryColumn(),
                            const SizedBox(height: 24),
                            _buildPieChartCard(screenWidth),
                          ],
                        )
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSummaryColumn()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPieChartCard(screenWidth)),
                          ],
                        ),
                    if (analysis['category_limits']?.isNotEmpty ?? false)
                      _buildCategoryLimitsCard(),
                    if (analysis['predictions']?.isNotEmpty ?? false)
                      _buildPredictionCard(),
                    if ((analysis['spending_clustering']?.isNotEmpty ??
                            false) ||
                        (analysis['frequency_clustering']?.isNotEmpty ??
                            false) ||
                        (analysis['association_rules']?.isNotEmpty ?? false))
                      _buildAnalysisCard(),
                    _buildLineChartCard(screenWidth),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          _buildCard(
            title: 'Expense Summary',
            child: SizedBox(
              width: double.infinity,
              child:
                  analysis['monthly_budget'] == null
                      ? _buildLocked(
                        'Expense summary is not available for you yet.',
                      )
                      : _buildExpenseSummary(),
            ),
          ),
          if (analysis['advice']?.isNotEmpty ?? false)
            _buildCard(
              title: 'Warnings',
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children:
                      (analysis['advice'] as List)
                          .asMap()
                          .entries
                          .map(
                            (entry) => _buildListItem(
                              'Warning ${entry.key + 1}:',
                              entry.value,
                              Colors.red,
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          _buildCard(
            title: 'Insights',
            child: SizedBox(
              width: double.infinity,
              child:
                  analysis['monthly_budget'] == null
                      ? _buildLocked('Insights are not available for you yet.')
                      : (analysis['smart_insights']?.isEmpty ?? true)
                      ? _buildLocked(
                        'No insights available yet. Add more expenses!',
                      )
                      : Column(
                        children:
                            (analysis['smart_insights'] as List)
                                .asMap()
                                .entries
                                .map(
                                  (entry) => _buildListItem(
                                    'Insight ${entry.key + 1}:',
                                    entry.value,
                                    Colors.green,
                                  ),
                                )
                                .toList(),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(double screenWidth) {
    final chartHeight =
        screenWidth < 400
            ? 320.0
            : screenWidth < 600
            ? 350.0
            : 450.0;
    final chartWidth =
        screenWidth < 400
            ? screenWidth * 0.9
            : screenWidth < 600
            ? screenWidth * 0.8
            : screenWidth * 0.7;

    return _buildCard(
      title: 'Expense Categories',
      child:
          analysis['monthly_budget'] == null
              ? _buildLocked(
                'Expense categories analysis is not available for you yet.',
              )
              : categoryTotals.isEmpty
              ? _buildLocked('No expenses recorded yet.')
              : Column(
                children: [
                  SizedBox(
                    height: chartHeight,
                    width: chartWidth,
                    child: PieChart(
                      PieChartData(
                        sections:
                            categoryTotals.entries.map((entry) {
                              final percentage =
                                  (entry.value /
                                      (analysis['total_spent'] ?? 1)) *
                                  100;
                              return PieChartSectionData(
                                value: entry.value,
                                title: '${percentage.toStringAsFixed(1)}%',
                                color: _getPieColor(
                                  categoryTotals.keys.toList().indexOf(
                                    entry.key,
                                  ),
                                ),
                                radius:
                                    screenWidth < 400
                                        ? 100
                                        : screenWidth < 600
                                        ? 110
                                        : 90,
                                titleStyle: TextStyle(
                                  fontSize:
                                      screenWidth < 400
                                          ? 14
                                          : screenWidth < 600
                                          ? 14
                                          : 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withAlpha(76),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                badgeWidget: null,
                                titlePositionPercentageOffset: 0.7,
                              );
                            }).toList(),
                        sectionsSpace:
                            screenWidth < 400
                                ? 3
                                : screenWidth < 600
                                ? 4
                                : 2,
                        centerSpaceRadius:
                            screenWidth < 400
                                ? 30
                                : screenWidth < 600
                                ? 40
                                : 50,
                        borderData: FlBorderData(show: false),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 150),
                      swapAnimationCurve: Curves.linear,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        categoryTotals.entries.map((entry) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getPieColor(
                                    categoryTotals.keys.toList().indexOf(
                                      entry.key,
                                    ),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: screenWidth < 400 ? 12 : 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildCategoryLimitsCard() {
    return _buildCard(
      title: 'Category Limits',
      child: Column(
        children: [
          const Text(
            'Category limits are determined by their priority.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Green:',
                      style: TextStyle(fontSize: 14, color: Colors.green[600]),
                    ),
                    TextSpan(
                      text: ' Within limit',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Text(
                ' | ',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Red:',
                      style: TextStyle(fontSize: 14, color: Colors.red[600]),
                    ),
                    TextSpan(
                      text: ' Exceeded limit',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(analysis['category_limits'] as List)
              .where((cat) => (cat['limit'] as num) > 0)
              .map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.chartPie,
                                color: Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  category['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${((category['limit'] / analysis['monthly_budget']) * 100).toStringAsFixed(1)}% ≈ E£${_formatNumber(category['limit'].toDouble())}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    category['name'] == 'Goal'
                                        ? (analysis['remaining_budget'] >=
                                                category['limit']
                                            ? Colors.green
                                            : Colors.red)
                                        : ((categoryTotals[category['name']] ??
                                                    0) <=
                                                category['limit']
                                            ? Colors.green
                                            : Colors.red),
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (category['name'] != 'Goal')
                              Text(
                                'Spent: E£${_formatNumber(categoryTotals[category['name']] ?? 0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    return _buildCard(
      title: 'AI-Based Prediction',
      child: Column(
        children: [
          const Text(
            'Predicts future expenses based on past spending patterns.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Accuracy: ${_getAccuracy().toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  _getAccuracy() < 60
                      ? Colors.red
                      : _getAccuracy() < 80
                      ? Colors.orange
                      : Colors.green,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: selectedPredictionType,
                    items:
                        ['Total', ..._getCategoryKeys()]
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) =>
                            setState(() => selectedPredictionType = value!),
                    isExpanded: true,
                    underline: Container(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                    iconSize: 28,
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: selectedMonths,
                    items:
                        [3, 6, 9, 12]
                            .map(
                              (months) => DropdownMenuItem(
                                value: months,
                                child: Text(
                                  '$months months',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() => selectedMonths = value!),
                    isExpanded: true,
                    underline: Container(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = MediaQuery.of(context).size.width;
              int itemsPerRow;

              if (screenWidth < 600) {
                itemsPerRow = 2;
              } else {
                itemsPerRow = 3;
              }

              var predictions =
                  ((selectedPredictionType == 'Total'
                              ? analysis['predictions']
                              : analysis['category_predictions']?[selectedPredictionType]) ??
                          [])
                      .take(selectedMonths)
                      .toList();

              List<Widget> rows = [];
              for (int i = 0; i < predictions.length; i += itemsPerRow) {
                var chunk =
                    predictions
                        .skip(i)
                        .take(itemsPerRow)
                        .map<Widget>(
                          (prediction) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              child: Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${prediction['month']} ${prediction['year']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'E£${_formatNumber(prediction['predicted_spending'].toDouble())}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList();

                while (chunk.length < itemsPerRow) {
                  chunk.add(Expanded(child: Container()));
                }

                rows.add(Row(children: chunk));
              }

              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return _buildCard(
      title: 'AI-Based Analysis',
      child: Column(
        children: [
          if (isSpendingClusteringView) ...[
            const Text(
              'Spending-Based Grouping',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Groups categories based on how much money you spend.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            (analysis['spending_clustering']?.isNotEmpty ?? false)
                ? _buildTable(
                  headers: ['Category', 'Spending'],
                  rows:
                      (analysis['spending_clustering'][0]['spending_group']
                              as List)
                          .map(
                            (item) => [
                              Text(
                                item['category'],
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      item['spending_group'] == 'Low'
                                          ? Colors.green
                                          : item['spending_group'] == 'Moderate'
                                          ? Colors.orange
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['spending_group'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          )
                          .toList(),
                )
                : _buildLocked('Not enough expenses entered.'),
          ],
          if (isFrequencyClusteringView) ...[
            const Text(
              'Frequency-Based Grouping',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Groups categories based on how often you spend.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            (analysis['frequency_clustering']?.isNotEmpty ?? false)
                ? _buildTable(
                  headers: ['Category', 'Frequency'],
                  rows:
                      (analysis['frequency_clustering'][0]['frequency_group']
                              as List)
                          .map(
                            (item) => [
                              Text(
                                item['category'],
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      item['frequency_group'] == 'Low'
                                          ? Colors.green
                                          : item['frequency_group'] ==
                                              'Moderate'
                                          ? Colors.orange
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['frequency_group'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          )
                          .toList(),
                )
                : _buildLocked('Not enough expenses entered.'),
          ],
          if (isExpenseClusteringView) ...[
            const Text(
              'Expense-Based Grouping',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Groups expenses based on amount spent.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            (analysis['expenses_clustering']?.isNotEmpty ?? false)
                ? _buildTable(
                  headers: ['Spending Group', 'Range', 'Count'],
                  rows:
                      (analysis['expenses_clustering'] as List).map((item) {
                        final range =
                            item['min_expenses'] == item['max_expenses']
                                ? 'E£${_formatNumber(item['min_expenses'].toDouble())}'
                                : 'E£${_formatNumber(item['min_expenses'].toDouble())} - ${_formatNumber(item['max_expenses'].toDouble())}';
                        return [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  item['cluster'].trim().toLowerCase() == 'low'
                                      ? Colors.green
                                      : item['cluster'].trim().toLowerCase() ==
                                          'moderate'
                                      ? Colors.orange
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['cluster'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            range,
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item['count_of_expenses'].toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ];
                      }).toList(),
                )
                : _buildLocked('Not enough expenses entered.'),
          ],
          if (isAssociationRulesView) ...[
            const Text(
              'Frequently Spent Together',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Finds connections between categories.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            (analysis['association_rules']?.isNotEmpty ?? false)
                ? _buildTable(
                  headers: [
                    '#',
                    'If you spent in',
                    'Then you\'ll spend in',
                    'Chance',
                  ],
                  rows:
                      (analysis['association_rules'] as List).asMap().entries.map((
                        entry,
                      ) {
                        final rule = entry.value;
                        return [
                          Text(
                            (entry.key + 1).toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            rule['antecedents'][0] ?? 'No antecedent',
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            rule['consequents'][0] ?? 'No consequent',
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (rule['confidence'] as num) >= 0.7
                                      ? Colors.green
                                      : (rule['confidence'] as num) >= 0.4
                                      ? Colors.orange
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rule['confidence'] != null
                                  ? '${((rule['confidence'] as num) * 100).toStringAsFixed(0)}%'
                                  : 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ];
                      }).toList(),
                )
                : _buildLocked('No connections found so far.'),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const FaIcon(Icons.chevron_left, size: 24),
                onPressed: isSpendingClusteringView ? null : _goToPrevView,
                color: isSpendingClusteringView ? Colors.grey : Colors.blue,
              ),
              _buildViewButton(1, isSpendingClusteringView, () {
                setState(() {
                  isSpendingClusteringView = true;
                  isFrequencyClusteringView = false;
                  isExpenseClusteringView = false;
                  isAssociationRulesView = false;
                });
              }),
              _buildViewButton(2, isFrequencyClusteringView, () {
                setState(() {
                  isSpendingClusteringView = false;
                  isFrequencyClusteringView = true;
                  isExpenseClusteringView = false;
                  isAssociationRulesView = false;
                });
              }),
              _buildViewButton(3, isExpenseClusteringView, () {
                setState(() {
                  isSpendingClusteringView = false;
                  isFrequencyClusteringView = false;
                  isExpenseClusteringView = true;
                  isAssociationRulesView = false;
                });
              }),
              _buildViewButton(4, isAssociationRulesView, () {
                setState(() {
                  isSpendingClusteringView = false;
                  isFrequencyClusteringView = false;
                  isExpenseClusteringView = false;
                  isAssociationRulesView = true;
                });
              }),
              IconButton(
                icon: const FaIcon(Icons.chevron_right, size: 24),
                onPressed: isAssociationRulesView ? null : _goToNextView,
                color: isAssociationRulesView ? Colors.grey : Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(double screenWidth) {
    final chartHeight =
        screenWidth < 400
            ? 350.0
            : screenWidth < 600
            ? 400.0
            : 500.0;
    final sortedExpenses =
        (analysis['daily_expenses'] as Map?)?.entries
            .map((e) => MapEntry(int.parse(e.key), e.value as num))
            .toList()
            .sorted((a, b) => a.key.compareTo(b.key)) ??
        [];
    final spendingDays = sortedExpenses.map((e) => e.key.toDouble()).toList();
    final firstDay = spendingDays.isNotEmpty ? spendingDays.first : 0;
    final lastDay = spendingDays.isNotEmpty ? spendingDays.last : 0;

    final lineBarsData = _getLineChartData();
    final remainingBudgetSpots =
        lineBarsData[0].spots; // Red line (remaining budget)
    final minRemainingBudget =
        remainingBudgetSpots.isNotEmpty
            ? remainingBudgetSpots
                .map((spot) => spot.y)
                .reduce((a, b) => a < b ? a : b)
            : 0.0;
    final maxBudget = analysis['monthly_budget']?.toDouble() ?? 1000;
    final minY = minRemainingBudget < 0 ? minRemainingBudget * 1.2 : 0.0;
    final maxY = maxBudget * 1.2;

    return _buildCard(
      title: 'Remaining Budget',
      child:
          analysis['monthly_budget'] == null
              ? _buildLocked(
                'Remaining balance analysis is not available for you yet.',
              )
              : SizedBox(
                height: chartHeight,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: screenWidth < 400 ? 50 : 60,
                          interval: (maxY - minY) / 4,
                          getTitlesWidget:
                              (value, meta) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  value < 0
                                      ? '-E£${(value.abs() ~/ 1000) > 0 ? '${(value.abs() ~/ 1000)}k' : value.abs().toInt().toString()}'
                                      : 'E£${(value ~/ 1000) > 0 ? '${(value ~/ 1000)}k' : value.toInt().toString()}',
                                  style: TextStyle(
                                    fontSize: screenWidth < 400 ? 12 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 80,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt();
                            if (value == firstDay || value == lastDay) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 10,
                                angle:
                                    screenWidth < 400
                                        ? -45 * 3.1415927 / 180
                                        : 0,
                                child: Text(
                                  'Day ${day.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: screenWidth < 400 ? 10 : 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    lineBarsData: lineBarsData,
                    minX: spendingDays.isNotEmpty ? spendingDays.first : 0,
                    maxX: spendingDays.isNotEmpty ? spendingDays.last : 1,
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: (maxY - minY) / 4,
                      verticalInterval: 1,
                      getDrawingHorizontalLine:
                          (value) =>
                              FlLine(color: Colors.grey[200], strokeWidth: 0.5),
                      getDrawingVerticalLine: (value) {
                        if (spendingDays.contains(value)) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 0.5,
                          );
                        }
                        return const FlLine(strokeWidth: 0);
                      },
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchSpotThreshold: 5,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (touchedSpots) {
                          if (touchedSpots.isEmpty) {
                            return [];
                          }
                          final day = touchedSpots.first.x.toInt();
                          final allData = StringBuffer();
                          allData.writeln(
                            'Day ${day.toString().padLeft(2, '0')}',
                          );
                          final orderedSpots =
                              touchedSpots.toList()..sort((a, b) {
                                const order = [3, 0, 2, 1];
                                return order
                                    .indexOf(a.barIndex)
                                    .compareTo(order.indexOf(b.barIndex));
                              });
                          final addedLines = <int>{};
                          for (var spot in orderedSpots) {
                            if (addedLines.contains(spot.barIndex)) {
                              continue;
                            }
                            String label;
                            switch (spot.barIndex) {
                              case 0: // Red line (remaining budget)
                                label = 'Remaining Budget';
                                break;
                              case 1: // Black line (zero line)
                                label = 'Zero Line';
                                break;
                              case 2: // Blue line (goal limit)
                                label = 'Goal Limit';
                                break;
                              case 3: // Green line (budget limit)
                                label = 'Budget Limit';
                                break;
                              default:
                                continue; // Skip unknown lines
                            }
                            allData.writeln('$label: ${_formatNumber(spot.y)}');
                            addedLines.add(spot.barIndex);
                          }
                          return touchedSpots.asMap().entries.map((entry) {
                            final index = entry.key;
                            if (index == 0) {
                              return LineTooltipItem(
                                allData.toString(),
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            } else {
                              return LineTooltipItem(
                                '',
                                const TextStyle(
                                  color: Colors.transparent,
                                  fontSize: 0,
                                ),
                              );
                            }
                          }).toList();
                        },
                      ),
                      getTouchedSpotIndicator: (
                        LineChartBarData barData,
                        List<int> spotIndexes,
                      ) {
                        return spotIndexes.map((index) {
                          final redLineData = _getLineChartData()[0];
                          if (barData != redLineData) {
                            return TouchedSpotIndicatorData(
                              FlLine(color: Colors.transparent, strokeWidth: 0),
                              FlDotData(
                                getDotPainter:
                                    (spot, percent, bar, index) =>
                                        FlDotCirclePainter(
                                          radius: 0,
                                          color: Colors.transparent,
                                          strokeWidth: 0,
                                          strokeColor: Colors.transparent,
                                        ),
                              ),
                            );
                          }
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: Colors.pink.withAlpha(127),
                              strokeWidth: 2,
                            ),
                            FlDotData(
                              getDotPainter:
                                  (spot, percent, bar, index) =>
                                      FlDotCirclePainter(
                                        radius: 8,
                                        color: Colors.pink,
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      ),
                            ),
                          );
                        }).toList();
                      },
                      handleBuiltInTouches: true,
                      touchCallback:
                          (
                            FlTouchEvent event,
                            LineTouchResponse? touchResponse,
                          ) {},
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLocked(String message) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.lock, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(color: Colors.grey, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSummary() {
    final totalSpent = analysis['total_spent'] ?? 0;
    final monthlyBudget = analysis['monthly_budget'] ?? 0;
    final goal = analysis['goal'] ?? 0;
    final remainingBudget = analysis['remaining_budget'] ?? monthlyBudget;
    final predictedCurrentMonth = analysis['predicted_current_month'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Spent: E£${_formatNumber(totalSpent.toDouble())}',
          style: TextStyle(
            color:
                totalSpent > monthlyBudget * 0.75 ? Colors.red : Colors.green,
            fontSize: 18,
          ),
        ),
        if (predictedCurrentMonth != null)
          Text(
            'Estimated Total: E£${_formatNumber(predictedCurrentMonth.toDouble())}',
            style: TextStyle(
              color:
                  predictedCurrentMonth > (monthlyBudget - goal)
                      ? Colors.red
                      : Colors.green,
              fontSize: 18,
            ),
          ),
        Text(
          'Remaining Allowance: E£${_formatNumber((remainingBudget - goal).toDouble())}',
          style: TextStyle(
            color:
                (remainingBudget - goal) < (monthlyBudget - goal) * 0.25
                    ? Colors.red
                    : Colors.green,
            fontSize: 18,
          ),
        ),
        Text(
          'Remaining Budget: E£${_formatNumber(remainingBudget.toDouble())}',
          style: TextStyle(
            color:
                remainingBudget < monthlyBudget * 0.25
                    ? Colors.red
                    : Colors.green,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Green:',
                    style: TextStyle(fontSize: 14, color: Colors.green[600]),
                  ),
                  TextSpan(
                    text: ' Under control',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Text(
              ' | ',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Red:',
                    style: TextStyle(fontSize: 14, color: Colors.red[600]),
                  ),
                  TextSpan(
                    text: ' Critical',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListItem(String title, String content, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 6, height: 60, color: borderColor),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: borderColor,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns:
            headers
                .map(
                  (header) => DataColumn(
                    label: Text(
                      header,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 18,
                      ),
                    ),
                  ),
                )
                .toList(),
        rows:
            rows
                .map(
                  (row) => DataRow(
                    cells:
                        row
                            .map(
                              (cell) => DataCell(
                                cell is String
                                    ? Text(
                                      cell,
                                      style: const TextStyle(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                    : cell,
                              ),
                            )
                            .toList(),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildViewButton(int number, bool isActive, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.blue : Colors.transparent,
          foregroundColor: isActive ? Colors.white : Colors.blue,
          side: const BorderSide(color: Colors.blue, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
        ),
        child: Text('$number', style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  List<LineChartBarData> _getLineChartData() {
    final sortedExpenses =
        (analysis['daily_expenses'] as Map?)?.entries
            .map((e) => MapEntry(int.parse(e.key), e.value as num))
            .toList()
            .sorted((a, b) => a.key.compareTo(b.key)) ??
        [];
    List<FlSpot> remainingBudgetSpots = [];
    double currentBudget = analysis['monthly_budget']?.toDouble() ?? 0;
    // ignore: unused_local_variable
    double lastDay =
        sortedExpenses.isNotEmpty ? sortedExpenses.last.key.toDouble() : 0;

    for (var entry in sortedExpenses) {
      currentBudget -= entry.value.toDouble();
      remainingBudgetSpots.add(FlSpot(entry.key.toDouble(), currentBudget));
    }

    if (remainingBudgetSpots.isEmpty) {
      remainingBudgetSpots.add(FlSpot(0, currentBudget));
    }

    final redLineXValues = remainingBudgetSpots.map((spot) => spot.x).toSet();

    return [
      // Red line (remaining budget)
      LineChartBarData(
        spots: remainingBudgetSpots,
        isCurved: false,
        color: Colors.pink,
        barWidth: 4,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: true, color: Colors.pink.withAlpha(51)),
      ),
      // Black line (zero line)
      LineChartBarData(
        spots: [
          FlSpot(remainingBudgetSpots.first.x, 0),
          FlSpot(remainingBudgetSpots.last.x, 0),
        ],
        isCurved: false,
        color: Colors.grey[800]!,
        barWidth: 2,
        dashArray: [5, 5],
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            if (redLineXValues.contains(spot.x)) {
              return FlDotCirclePainter(radius: 0);
            }
            return FlDotCirclePainter(
              radius: 4,
              color: Colors.grey[800]!,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
      ),
      // Blue line (goal limit)
      LineChartBarData(
        spots: [
          FlSpot(
            remainingBudgetSpots.first.x,
            analysis['goal']?.toDouble() ?? 0.0,
          ),
          FlSpot(
            remainingBudgetSpots.last.x,
            analysis['goal']?.toDouble() ?? 0.0,
          ),
        ],
        isCurved: false,
        color: Colors.blue,
        barWidth: 2,
        dashArray: [10, 5],
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            if (redLineXValues.contains(spot.x)) {
              return FlDotCirclePainter(radius: 0);
            }
            return FlDotCirclePainter(
              radius: 4,
              color: Colors.blue,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
      ),
      // Green line (budget limit)
      LineChartBarData(
        spots: [
          FlSpot(
            remainingBudgetSpots.first.x,
            analysis['monthly_budget']?.toDouble() ?? 0.0,
          ),
          FlSpot(
            remainingBudgetSpots.last.x,
            analysis['monthly_budget']?.toDouble() ?? 0.0,
          ),
        ],
        isCurved: false,
        color: Colors.teal,
        barWidth: 2,
        dashArray: [10, 5],
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            if (redLineXValues.contains(spot.x)) {
              return FlDotCirclePainter(radius: 0);
            }
            return FlDotCirclePainter(
              radius: 4,
              color: Colors.teal,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
      ),
    ];
  }

  Color _getPieColor(int index) {
    const colors = [
      Color(0xFFFF6384), // Soft Coral
      Color(0xFF36A2EB), // Sky Blue
      Color(0xFFFFCE56), // Warm Yellow
      Color(0xFF9966FF), // Amethyst Purple
      Color(0xFFFF9F40), // Tangerine
      Color(0xFF66BB6A), // Emerald Green
      Color(0xFFFF8A65), // Peach
      Color(0xFF4BC0C0), // Teal
      Color(0xFF9575CD), // Lavender Purple
      Color(0xFFD4E157), // Lime
      Color(0xFFEF5350), // Bright Red
      Color(0xFF26C6DA), // Cyan
      Color(0xFFFFB300), // Amber
      Color(0xFF8D6E63), // Warm Brown
      Color(0xFFEC407A), // Pink
    ];
    return colors[index % colors.length];
  }
}

extension ListSort<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) {
    final newList = List<T>.from(this);
    newList.sort(compare);
    return newList;
  }
}

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red : Colors.green,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${isError ? 'Oops!' : 'Awesome!'} $message',
              style: TextStyle(
                color: isError ? Colors.red[900] : Colors.green[900],
                fontSize: 18,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 24),
              onPressed: onDismiss,
              color: isError ? Colors.red : Colors.green,
            ),
        ],
      ),
    );
  }
}
