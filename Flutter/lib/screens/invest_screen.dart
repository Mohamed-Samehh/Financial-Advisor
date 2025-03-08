import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart'; // Adjust path as needed
import '../screens/navbar.dart'; // Assuming a similar Navbar exists

// Define a Returns class for type safety
class Returns {
  final num daily;
  final num monthly;
  final num quarterly;
  final num semiAnnual;
  final num annual;
  final num atMaturity;
  final bool isChangingRate;

  Returns({
    required this.daily,
    required this.monthly,
    required this.quarterly,
    required this.semiAnnual,
    required this.annual,
    required this.atMaturity,
    required this.isChangingRate,
  });
}

// Bank model
class Bank {
  final String name;
  final String description;
  final List<Certificate> certificates;
  final String image;
  final String investmentLink;

  Bank({
    required this.name,
    required this.description,
    required this.certificates,
    required this.image,
    required this.investmentLink,
  });
}

// Certificate model
class Certificate {
  final String type;
  final int duration;
  final int minInvestment;
  final int multiples;
  final String? dailyInterestRate;
  final String? monthlyInterestRate;
  final String? quarterlyInterestRate;
  final String? semiAnnuallyInterestRate;
  final String? annuallyInterestRate;
  final String? atMaturityInterestRate;
  final String description;

  Certificate({
    required this.type,
    required this.duration,
    required this.minInvestment,
    required this.multiples,
    this.dailyInterestRate,
    this.monthlyInterestRate,
    this.quarterlyInterestRate,
    this.semiAnnuallyInterestRate,
    this.annuallyInterestRate,
    this.atMaturityInterestRate,
    required this.description,
  });
}

// Goal model
class Goal {
  final int? id;
  final String name;
  final int? targetAmount;

  Goal({this.id, required this.name, this.targetAmount});

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      targetAmount: json['target_amount'] as int?,
    );
  }
}

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});

  @override
  InvestScreenState createState() => InvestScreenState();
}

class InvestScreenState extends State<InvestScreen> {
  Map<String, dynamic> goal = {'id': null, 'name': '', 'target_amount': null};
  bool isLoading = true;
  String? message;
  String? messageType; // 'success' or 'error'

  // Hardcoded bank data
  final List<Bank> banks = [
    Bank(
      name: 'National Bank of Egypt (NBE)',
      description:
          'One of the largest banks in Egypt, offering a variety of fixed deposit and savings products.',
      image: 'assets/Banks/NBE.png',
      investmentLink:
          'https://www.nbe.com.eg/NBE/E/#/EN/ProductCategory?inParams=%7B%22CategoryID%22%3A%22LocalCertificatesID%22%7D',
      certificates: [
        Certificate(
          type: 'Platinum Certificate With Monthly Step Down Interest',
          monthlyInterestRate: '26% (1st year), 22% (2nd year), 18% (3rd year)',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description:
              'A declining interest certificate with a higher rate in the first year.',
        ),
        Certificate(
          type: 'Platinum Certificate With Annual Step Down Interest',
          annuallyInterestRate:
              '30% (1st year), 25% (2nd year), 20% (3rd year)',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description:
              'Provides annual step-down interest rates for long-term investment planning.',
        ),
      ],
    ),
    // Add other banks as needed
  ];

  @override
  void initState() {
    super.initState();
    _loadGoal();
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
      setState(() {
        isLoading = false;
        message = 'Error loading goal. Please try again.';
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
                  Icon(
                    Icons.account_balance,
                    size: 80,
                    color: Colors.white.withAlpha(230),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Investment Explorer',
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
                    'Explore top investment options to grow your savings.',
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
                    if (!goal['name'].toLowerCase().contains('invest'))
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
                              'To turn on Investment Explorer, include "invest" in your goal name.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    if (goal['name'].toLowerCase().contains('invest')) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Banks Data Update: 1st of Feb. 2025\nExplore top investment options from leading banks.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...banks.map((bank) => _buildBankCard(bank)).toList(),
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

  Widget _buildBankCard(Bank bank) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
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
            Image.asset(bank.image, height: 80, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(
              bank.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              bank.description,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...bank.certificates
                .map((certificate) => _buildCertificateCard(certificate))
                .toList(),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Add URL launcher logic here if needed
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'More Details',
                  style: TextStyle(
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
    );
  }

  Widget _buildCertificateCard(Certificate certificate) {
    final targetAmount =
        goal['target_amount'] != null ? double.parse(goal['target_amount']) : 0;
    final roundedAmount = roundToNearestMultiple(
      targetAmount,
      certificate.multiples,
    );
    final returns = calculateReturns(
      targetAmount,
      certificate.monthlyInterestRate ?? certificate.annuallyInterestRate ?? '',
      certificate.duration,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            certificate.type,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text('Duration (years): ${certificate.duration}'),
          Text(
            'Min Investment: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 0).format(certificate.minInvestment)}',
          ),
          Text(
            'Allowed Multiples: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 0).format(certificate.multiples)}',
          ),
          const Divider(),
          if (certificate.dailyInterestRate != null)
            Text('Daily Interest: ${certificate.dailyInterestRate}'),
          if (certificate.monthlyInterestRate != null)
            Text('Monthly Interest: ${certificate.monthlyInterestRate}'),
          if (certificate.quarterlyInterestRate != null)
            Text('Quarterly Interest: ${certificate.quarterlyInterestRate}'),
          if (certificate.semiAnnuallyInterestRate != null)
            Text(
              'Semi-Annual Interest: ${certificate.semiAnnuallyInterestRate}',
            ),
          if (certificate.annuallyInterestRate != null)
            Text('Annual Interest: ${certificate.annuallyInterestRate}'),
          if (certificate.atMaturityInterestRate != null)
            Text('At Maturity Interest: ${certificate.atMaturityInterestRate}'),
          const Divider(),
          if (goal['target_amount'] != null) ...[
            Text(
              'Your Investment: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 0).format(roundedAmount)}',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (targetAmount < certificate.minInvestment)
              Text(
                'Investment Amount Too Low: Min ${NumberFormat.currency(symbol: 'E£', decimalDigits: 0).format(certificate.minInvestment)}',
                style: const TextStyle(color: Colors.red),
              ),
            if (targetAmount >= certificate.minInvestment) ...[
              if (certificate.dailyInterestRate != null)
                Text(
                  'Daily Return${returns.isChangingRate ? " (avg of ${certificate.duration} yrs)" : ""}: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 2).format(returns.daily)}',
                  style: const TextStyle(color: Colors.green),
                ),
              if (certificate.monthlyInterestRate != null)
                Text(
                  'Monthly Return${returns.isChangingRate ? " (avg of ${certificate.duration} yrs)" : ""}: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 2).format(returns.monthly)}',
                  style: const TextStyle(color: Colors.green),
                ),
              if (certificate.quarterlyInterestRate != null)
                Text(
                  'Quarterly Return${returns.isChangingRate ? " (avg of ${certificate.duration} yrs)" : ""}: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 2).format(returns.quarterly)}',
                  style: const TextStyle(color: Colors.green),
                ),
              if (certificate.semiAnnuallyInterestRate != null)
                Text(
                  'Semi-Annual Return${returns.isChangingRate ? " (avg of ${certificate.duration} yrs)" : ""}: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 2).format(returns.semiAnnual)}',
                  style: const TextStyle(color: Colors.green),
                ),
              if (certificate.annuallyInterestRate != null)
                Text(
                  'Annual Return${returns.isChangingRate ? " (avg of ${certificate.duration} yrs)" : ""}: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 2).format(returns.annual)}',
                  style: const TextStyle(color: Colors.green),
                ),
              if (certificate.atMaturityInterestRate != null)
                Text(
                  'At Maturity Return${returns.isChangingRate ? " (avg of ${certificate.duration} yrs)" : ""}: ${NumberFormat.currency(symbol: 'E£', decimalDigits: 2).format(returns.atMaturity)}',
                  style: const TextStyle(color: Colors.green),
                ),
            ],
          ],
          const SizedBox(height: 10),
          Text(
            certificate.description,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Returns calculateReturns(
    num targetAmount,
    String interestRate,
    int duration,
  ) {
    final rates = extractInterestRates(interestRate);
    final isChangingRate = rates.length > 1;
    final averageRate =
        rates.isNotEmpty
            ? rates.reduce((a, b) => a + b) / rates.length / 100
            : 0;

    final dailyReturn = targetAmount * (averageRate / 365);
    final monthlyReturn = targetAmount * (averageRate / 12);
    final quarterlyReturn = targetAmount * (averageRate / 4);
    final semiAnnualReturn = targetAmount * (averageRate / 2);
    final annualReturn = targetAmount * averageRate;
    final atMaturityReturn = targetAmount * averageRate * duration;

    return Returns(
      daily: dailyReturn,
      monthly: monthlyReturn,
      quarterly: quarterlyReturn,
      semiAnnual: semiAnnualReturn,
      annual: annualReturn,
      atMaturity: atMaturityReturn,
      isChangingRate: isChangingRate,
    );
  }

  List<double> extractInterestRates(String interestRate) {
    final regex = RegExp(r'\d+(\.\d+)?(?=%)');
    return regex
        .allMatches(interestRate)
        .map((match) => double.parse(match.group(0)!))
        .toList();
  }

  int roundToNearestMultiple(num targetAmount, int multiple) {
    return (targetAmount / multiple).floor() * multiple;
  }
}

// Reusing AlertMessage from GoalScreen
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
