import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'navbar.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});

  @override
  InvestScreenState createState() => InvestScreenState();
}

class InvestScreenState extends State<InvestScreen> {
  bool isLoading = true;
  Map<String, dynamic> goal = {'id': null, 'name': '', 'target_amount': null};
  bool showInvestmentModeMessage = true;
  String? selectedBankName;

  // Tabs
  String activeTab = 'certificates'; // 'certificates' or 'stocks'

  // Certificates
  bool isLoadingCertificates = false;
  List<Map<String, dynamic>> selectedCertificates = [];
  bool showCompareModal = false;
  Map<String, dynamic> winningValues = {};

  // Stocks
  bool isLoadingStocks = false;
  List<Map<String, dynamic>> egyptStocks = [];
  List<Map<String, dynamic>> filteredStocks = [];
  Map<String, dynamic>? selectedStock;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  String stocksError = '';
  DateTime currentDate = DateTime.now();

  // Chatbot
  bool showChatModal = false;
  List<Map<String, dynamic>> chatResponses = [];
  bool isChatLoading = false;
  dynamic selectedInvestment;
  String selectedInvestmentType = 'certificate';

  // Banks data
  // Pics from Wikimedia Commons (https://commons.wikimedia.org/)
  final List<Map<String, dynamic>> banks = [
    {
      'name': 'Banque Misr',
      'description':
          'A major Egyptian bank offering a wide range of investment and savings products.',
      'image': 'assets/Banks/Banque Misr.png',
      'investmentLink':
          'https://www.banquemisr.com/-/media/Interest-rates/Interest-rates-EN.pdf',
      'certificates': [
        {
          'type': 'Talaat Harb Certificate',
          'monthlyInterestRate': '23.5%',
          'atMaturityInterestRate': '27%',
          'duration': 1,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A 1-year certificate offering a high fixed interest rate, with options for monthly payments or lump sum at maturity.',
        },
        {
          'type': 'Certificates of Deposit (5 years)',
          'monthlyInterestRate': '12.25%',
          'annuallyInterestRate': '12.5%',
          'duration': 5,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A 5-year certificate offering fixed interest rates with options for monthly or annual payouts.',
        },
        {
          'type': 'Certificates of Deposit (7 years)',
          'monthlyInterestRate': '12.75%',
          'duration': 7,
          'minInvestment': 750,
          'multiples': 750,
          'description':
              'A 7-year certificate providing a fixed monthly interest rate.',
        },
        {
          'type': 'Al Qimma Certificate',
          'monthlyInterestRate': '21.5%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A 3-year certificate providing a fixed monthly interest rate.',
        },
        {
          'type': 'Aman Al Masreyeen Certificate of Deposit',
          'atMaturityInterestRate': '13%',
          'duration': 3,
          'minInvestment': 500,
          'multiples': 500,
          'description':
              'A 3-year nominal certificate offering life insurance and prize draws, with interest paid at maturity.',
        },
        {
          'type': 'Ibn Misr Al-Tholatheya Descending Certificate',
          'monthlyInterestRate': '26% (Y1), 22.5% (Y2), 19% (Y3)',
          'quarterlyInterestRate': '27% (Y1), 23% (Y2), 19% (Y3)',
          'annuallyInterestRate': '30% (Y1), 25% (Y2), 20% (Y3)',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A 3-year certificate with a descending fixed interest rate, offering multiple payout options.',
        },
      ],
    },
    {
      'name': 'National Bank of Egypt (NBE)',
      'description':
          'One of the largest banks in Egypt, offering a variety of fixed deposit and savings products.',
      'image': 'assets/Banks/NBE.png',
      'investmentLink':
          'https://www.nbe.com.eg/NBE/E/#/EN/ProductCategory?inParams=%7B%22CategoryID%22%3A%22LocalCertificatesID%22%7D',
      'certificates': [
        {
          'type': 'Platinum Certificate With Monthly Step Down Interest',
          'monthlyInterestRate': '26% (Y1), 22% (Y2), 18% (Y3)',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A declining interest certificate with a higher rate in the first year.',
        },
        {
          'type': 'Platinum Certificate With Annual Step Down Interest',
          'annuallyInterestRate': '30% (Y1), 25% (Y2), 20% (Y3)',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'Provides annual step-down interest rates for long-term investment planning.',
        },
        {
          'type': 'Platinum Certificate 3 Years',
          'monthlyInterestRate': '21.5%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'Offers stable monthly payouts for medium-term investors.',
        },
        {
          'type': 'Platinum Variable Interest',
          'quarterlyInterestRate': '27.5%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A variable interest certificate with quarterly payouts.',
        },
        {
          'type': 'Five Years CD',
          'monthlyInterestRate': '14.25%',
          'duration': 5,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A long-term investment option with consistent monthly returns.',
        },
        {
          'type': 'Egyptian Certificate Aman',
          'atMaturityInterestRate': '13%',
          'duration': 3,
          'minInvestment': 500,
          'multiples': 500,
          'description':
              'A low-minimum investment certificate with a fixed interest rate and a cap on maximum investment.',
        },
        {
          'type': 'Platinum Annual Certificate',
          'dailyInterestRate': '23%',
          'monthlyInterestRate': '23.5%',
          'annuallyInterestRate': '27%',
          'duration': 1,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A high-yield certificate with options for monthly, daily, or annual interest payouts.',
        },
      ],
    },
    {
      'name': 'Commercial International Bank (CIB)',
      'description':
          'CIB offers competitive interest rates for various types of certificates with flexible terms.',
      'image': 'assets/Banks/CIB.png',
      'investmentLink':
          'https://www.cibeg.com/en/personal/accounts-and-deposits/deposits/certificate',
      'certificates': [
        {
          'type': '3 Years Floating "2024"',
          'monthlyInterestRate': '24.75%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'Offers a variable interest rate linked to the Central Bank of Egypt\'s rates, suitable for those anticipating rate increases.',
        },
        {
          'type': '3 Years Fixed Prime CD',
          'monthlyInterestRate': '18%',
          'duration': 3,
          'minInvestment': 100000,
          'multiples': 1000,
          'description':
              'Designed for investors seeking stable returns with a lower entry point.',
        },
        {
          'type': '3 Years Fixed Plus CD',
          'monthlyInterestRate': '19%',
          'duration': 3,
          'minInvestment': 500000,
          'multiples': 1000,
          'description':
              'Ideal for investors desiring competitive returns with a moderate initial investment.',
        },
        {
          'type': '3 Years Fixed Premium CD',
          'monthlyInterestRate': '20%',
          'duration': 3,
          'minInvestment': 1000000,
          'multiples': 1000,
          'description':
              'Suitable for investors seeking high returns with a substantial initial investment.',
        },
      ],
    },
    {
      'name': 'QNB Alahli',
      'description':
          'Part of the Qatar National Bank Group, providing a range of banking services in Egypt.',
      'image': 'assets/Banks/QNB.png',
      'investmentLink':
          'https://www.qnbalahli.com/sites/qnb/qnbegypt/page/en/enfixedcds.html',
      'certificates': [
        {
          'type': 'Retail Fixed CD 3 years',
          'monthlyInterestRate': '20%',
          'quarterlyInterestRate': '20.05%',
          'semiAnnuallyInterestRate': '20.10%',
          'annuallyInterestRate': '20.15%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'Suitable for investors seeking stable returns with a modest initial investment.',
        },
        {
          'type': 'First CD',
          'monthlyInterestRate': '21%',
          'quarterlyInterestRate': '21.05%',
          'annuallyInterestRate': '21.15% ',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'Ideal for investors desiring higher returns with a low entry point.',
        },
        {
          'type': 'Exclusive CD',
          'monthlyInterestRate': '21.50%',
          'duration': 3,
          'minInvestment': 1000000,
          'multiples': 1000,
          'description':
              'Designed for investors seeking premium returns with a substantial initial investment.',
        },
        {
          'type': 'First Plus CD',
          'monthlyInterestRate': '22.50%',
          'duration': 3,
          'minInvestment': 5000000,
          'multiples': 1000,
          'description':
              'Tailored for investors aiming for the highest returns with a significant initial investment.',
        },
      ],
    },
    {
      'name': 'Al Baraka Bank',
      'description':
          'Al Baraka Bank offers various local currency certificates with competitive interest rates and flexible terms.',
      'image': 'assets/Banks/Al Baraka.png',
      'investmentLink': 'https://www.albaraka.com.eg/personal/cds/',
      'certificates': [
        {
          'type': 'Al Baraka Elite',
          'monthlyInterestRate': '22%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A premium certificate with high interest and monthly payments.',
        },
        {
          'type': 'Golden CD',
          'monthlyInterestRate': '14%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A solid option for investors seeking monthly payouts.',
        },
        {
          'type': 'Diamond Plus CD',
          'monthlyInterestRate': '19%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A competitive certificate with a strong interest rate.',
        },
        {
          'type': 'Diamond CD',
          'monthlyInterestRate': '16%',
          'annuallyInterestRate': '17.25%',
          'duration': 3,
          'minInvestment': 100000,
          'multiples': 5000,
          'description':
              'A high-value certificate with flexible interest payment options.',
        },
      ],
    },
    {
      'name': 'HSBC Egypt',
      'description':
          'A subsidiary of HSBC Holdings, providing comprehensive banking services in Egypt.',
      'image': 'assets/Banks/HSBC.png',
      'investmentLink':
          'https://www.hsbc.com.eg/accounts/products/savings-certificates/',
      'certificates': [
        {
          'type': 'Savings Certificate',
          'monthlyInterestRate': '20.50%',
          'duration': 3,
          'minInvestment': 10000,
          'multiples': 1000,
          'description':
              'A high-return savings certificate with monthly interest payments and tax exemption.',
        },
      ],
    },
    {
      'name': 'Arab International Bank (AIB)',
      'description':
          'AIB offers certificates with competitive interest rates and flexible terms for saving and wealth growth.',
      'image': 'assets/Banks/AIB.png',
      'investmentLink': 'https://aib.com.eg/aib-certificates',
      'certificates': [
        {
          'type': 'Floating rate certificate - 3 years',
          'monthlyInterestRate': '22.75%',
          'quarterlyInterestRate': '23%',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'Floating interest rate, adjusted with CBE discount rate changes.',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGoal();
    selectedBankName = banks.isNotEmpty ? banks[0]['name'] : null;
    searchController.text = searchQuery;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
        showInvestmentModeMessage =
            !goal['name'].toString().toLowerCase().contains('invest');

        if (!showInvestmentModeMessage) {
          _loadEgyptStocks();
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Load Egypt stocks from API
  void _loadEgyptStocks() async {
    if (egyptStocks.isNotEmpty) return;

    setState(() {
      isLoadingStocks = true;
      stocksError = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.getEgyptStocks();
      List<Map<String, dynamic>> stocks = [];

      for (var stock in response) {
        stocks.add({
          'code': stock['Code'],
          'name': stock['Name'] ?? stock['Code'],
          'exchange': stock['Exchange'],
          'currency': stock['Currency'],
          'country': stock['Country'],
          'type': stock['Type'],
          'isin': stock['Isin'],
        });
      }

      setState(() {
        egyptStocks = stocks;
        filteredStocks = List.from(stocks);
        isLoadingStocks = false;

        if (stocks.isNotEmpty) {
          _viewStockDetails(stocks[0]);
        }
      });
    } catch (e) {
      setState(() {
        isLoadingStocks = false;
        stocksError = 'Unable to load Egyptian stocks. Please try again later.';
      });
    }
  }

  void _toggleCertificateSelection(
    Map<String, dynamic> certificate,
    Map<String, dynamic> bank,
  ) {
    final int index = selectedCertificates.indexWhere(
      (item) =>
          item['certificate']['type'] == certificate['type'] &&
          item['bank']['name'] == bank['name'],
    );

    setState(() {
      if (index == -1) {
        selectedCertificates.add({'certificate': certificate, 'bank': bank});
      } else {
        selectedCertificates.removeAt(index);
      }
    });
  }

  bool _isCertificateSelected(
    Map<String, dynamic> certificate,
    Map<String, dynamic> bank,
  ) {
    return selectedCertificates.any(
      (item) =>
          item['certificate']['type'] == certificate['type'] &&
          item['bank']['name'] == bank['name'],
    );
  }

  void _openCompareModal() {
    if (selectedCertificates.length >= 2) {
      setState(() {
        showCompareModal = true;
        _calculateWinningValues();
      });
    }
  }

  void _closeCompareModal() {
    setState(() {
      showCompareModal = false;
      winningValues = {};
    });
  }

  void _removeCertificateFromComparison(Map<String, dynamic> item) {
    setState(() {
      final int index = selectedCertificates.indexWhere(
        (selected) =>
            selected['certificate']['type'] == item['certificate']['type'] &&
            selected['bank']['name'] == item['bank']['name'],
      );

      if (index != -1) {
        selectedCertificates.removeAt(index);
        if (selectedCertificates.length == 1) {
          selectedCertificates = [];
          _closeCompareModal();
        } else if (selectedCertificates.length >= 2) {
          _calculateWinningValues();
        }
      }
    });
  }

  void _calculateWinningValues() {
    setState(() {
      winningValues = {};

      for (var item in selectedCertificates) {
        final certificate = item['certificate'];
        final double investmentAmount =
            double.tryParse(goal['target_amount'] ?? '0') != null
                ? roundToNearestMultiple(
                  double.parse(goal['target_amount']),
                  certificate['multiples'].toDouble(),
                )
                : 0.0;

        // Duration (shortest is best)
        if (winningValues['duration'] == null ||
            certificate['duration'] < winningValues['duration']) {
          winningValues['duration'] = certificate['duration'];
        }

        // Min Investment (lowest is best)
        if (winningValues['minInvestment'] == null ||
            certificate['minInvestment'] < winningValues['minInvestment']) {
          winningValues['minInvestment'] = certificate['minInvestment'];
        }

        // Allowed Multiples (lowest is best)
        if (winningValues['multiples'] == null ||
            certificate['multiples'] < winningValues['multiples']) {
          winningValues['multiples'] = certificate['multiples'];
        }

        // Daily Interest (highest average rate is best)
        if (certificate['dailyInterestRate'] != null) {
          final avgRate = calculateAverageRate(
            certificate['dailyInterestRate'],
          );
          if (winningValues['dailyInterest'] == null ||
              avgRate > winningValues['dailyInterest']) {
            winningValues['dailyInterest'] = avgRate;
          }
        }

        // Monthly Interest (highest average rate is best)
        if (certificate['monthlyInterestRate'] != null) {
          final avgRate = calculateAverageRate(
            certificate['monthlyInterestRate'],
          );
          if (winningValues['monthlyInterest'] == null ||
              avgRate > winningValues['monthlyInterest']) {
            winningValues['monthlyInterest'] = avgRate;
          }
        }

        // Quarterly Interest (highest average rate is best)
        if (certificate['quarterlyInterestRate'] != null) {
          final avgRate = calculateAverageRate(
            certificate['quarterlyInterestRate'],
          );
          if (winningValues['quarterlyInterest'] == null ||
              avgRate > winningValues['quarterlyInterest']) {
            winningValues['quarterlyInterest'] = avgRate;
          }
        }

        // Semi-Annual Interest (highest average rate is best)
        if (certificate['semiAnnuallyInterestRate'] != null) {
          final avgRate = calculateAverageRate(
            certificate['semiAnnuallyInterestRate'],
          );
          if (winningValues['semiAnnualInterest'] == null ||
              avgRate > winningValues['semiAnnualInterest']) {
            winningValues['semiAnnualInterest'] = avgRate;
          }
        }

        // Annual Interest (highest average rate is best)
        if (certificate['annuallyInterestRate'] != null) {
          final avgRate = calculateAverageRate(
            certificate['annuallyInterestRate'],
          );
          if (winningValues['annualInterest'] == null ||
              avgRate > winningValues['annualInterest']) {
            winningValues['annualInterest'] = avgRate;
          }
        }

        // At Maturity Interest (highest average rate is best)
        if (certificate['atMaturityInterestRate'] != null) {
          final avgRate = calculateAverageRate(
            certificate['atMaturityInterestRate'],
          );
          if (winningValues['atMaturityInterest'] == null ||
              avgRate > winningValues['atMaturityInterest']) {
            winningValues['atMaturityInterest'] = avgRate;
          }
        }

        // Your Investment (highest adjusted amount is best)
        if (goal['target_amount'] != null) {
          final double targetAmount = double.parse(
            goal['target_amount'] ?? '0',
          );
          final double adjustedInvestment = roundToNearestMultiple(
            targetAmount,
            certificate['multiples'].toDouble(),
          );
          if (winningValues['yourInvestment'] == null ||
              adjustedInvestment > winningValues['yourInvestment']) {
            winningValues['yourInvestment'] = adjustedInvestment;
          }
        }

        // Daily Return (highest is best)
        if (certificate['dailyInterestRate'] != null &&
            goal['target_amount'] != null) {
          final returns = calculateReturns(
            investmentAmount,
            certificate['dailyInterestRate'],
            certificate['duration'].toDouble(),
          );
          if (winningValues['dailyReturn'] == null ||
              returns['daily'] > winningValues['dailyReturn']) {
            winningValues['dailyReturn'] = returns['daily'];
          }
        }

        // Monthly Return (highest is best)
        if (certificate['monthlyInterestRate'] != null &&
            goal['target_amount'] != null) {
          final returns = calculateReturns(
            investmentAmount,
            certificate['monthlyInterestRate'],
            certificate['duration'].toDouble(),
          );
          if (winningValues['monthlyReturn'] == null ||
              returns['monthly'] > winningValues['monthlyReturn']) {
            winningValues['monthlyReturn'] = returns['monthly'];
          }
        }

        // Quarterly Return (highest is best)
        if (certificate['quarterlyInterestRate'] != null &&
            goal['target_amount'] != null) {
          final returns = calculateReturns(
            investmentAmount,
            certificate['quarterlyInterestRate'],
            certificate['duration'].toDouble(),
          );
          if (winningValues['quarterlyReturn'] == null ||
              returns['quarterly'] > winningValues['quarterlyReturn']) {
            winningValues['quarterlyReturn'] = returns['quarterly'];
          }
        }

        // Semi-Annual Return (highest is best)
        if (certificate['semiAnnuallyInterestRate'] != null &&
            goal['target_amount'] != null) {
          final returns = calculateReturns(
            investmentAmount,
            certificate['semiAnnuallyInterestRate'],
            certificate['duration'].toDouble(),
          );
          if (winningValues['semiAnnualReturn'] == null ||
              returns['semiAnnual'] > winningValues['semiAnnualReturn']) {
            winningValues['semiAnnualReturn'] = returns['semiAnnual'];
          }
        }

        // Annual Return (highest is best)
        if (certificate['annuallyInterestRate'] != null &&
            goal['target_amount'] != null) {
          final returns = calculateReturns(
            investmentAmount,
            certificate['annuallyInterestRate'],
            certificate['duration'].toDouble(),
          );
          if (winningValues['annualReturn'] == null ||
              returns['annual'] > winningValues['annualReturn']) {
            winningValues['annualReturn'] = returns['annual'];
          }
        }

        // At Maturity Return (highest is best)
        if (certificate['atMaturityInterestRate'] != null &&
            goal['target_amount'] != null) {
          final returns = calculateReturns(
            investmentAmount,
            certificate['atMaturityInterestRate'],
            certificate['duration'].toDouble(),
          );
          if (winningValues['atMaturityReturn'] == null ||
              returns['atMaturity'] > winningValues['atMaturityReturn']) {
            winningValues['atMaturityReturn'] = returns['atMaturity'];
          }
        }
      }
    });
  }

  double calculateAverageRate(String interestRate) {
    final rates = extractInterestRates(interestRate);
    return rates.isNotEmpty
        ? rates.reduce((a, b) => a + b) / rates.length
        : 0.0;
  }

  String? _getInterestRateForReturnType(
    Map<String, dynamic> certificate,
    String returnType,
  ) {
    if (returnType == 'daily') {
      return certificate['dailyInterestRate'];
    } else if (returnType == 'monthly') {
      return certificate['monthlyInterestRate'];
    } else if (returnType == 'quarterly') {
      return certificate['quarterlyInterestRate'];
    } else if (returnType == 'semiAnnual') {
      return certificate['semiAnnuallyInterestRate'];
    } else if (returnType == 'annual') {
      return certificate['annuallyInterestRate'];
    } else if (returnType == 'atMaturity') {
      return certificate['atMaturityInterestRate'];
    }
    return null;
  }

  // Get details for a specific stock
  void _viewStockDetails(Map<String, dynamic> stock) async {
    setState(() {
      selectedStock = stock;
      isLoadingStocks = true;
      stocksError = '';
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final histData = await apiService.getStockDetails(stock['code']);

      if (mounted) {
        setState(() {
          if (selectedStock != null &&
              selectedStock!['code'] == stock['code']) {
            selectedStock!['historicalData'] = histData;
            if (histData != null && histData.isNotEmpty) {
              currentDate = DateTime.parse(
                histData[histData.length - 1]['date'],
              );
            }
          }
          isLoadingStocks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingStocks = false;
          stocksError = 'Unable to load stock details. Please try again later.';
        });
      }
    }
  }

  // Search stocks
  void _searchStocks() {
    final query = searchQuery.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        filteredStocks = List.from(egyptStocks);
      });
      return;
    }

    setState(() {
      filteredStocks =
          egyptStocks
              .where(
                (stock) =>
                    stock['name'].toString().toLowerCase().contains(query) ||
                    stock['code'].toString().toLowerCase().contains(query) ||
                    (stock['type'] != null &&
                        stock['type'].toString().toLowerCase().contains(query)),
              )
              .toList();
    });
  }

  // Switch between certificates and stocks tabs
  void _switchTab(String tab) {
    setState(() {
      activeTab = tab;

      if (tab == 'stocks' && egyptStocks.isEmpty) {
        _loadEgyptStocks();
      }
    });
  }

  Map<String, dynamic> calculateReturns(
    double targetAmount,
    String interestRate,
    double duration,
  ) {
    final rates = extractInterestRates(interestRate);
    final isChangingRate = rates.length > 1;
    final averageRate =
        rates.isNotEmpty
            ? rates.reduce((a, b) => a + b) / rates.length / 100
            : 0.0;

    return {
      'daily': targetAmount * (averageRate / 365),
      'monthly': targetAmount * (averageRate / 12),
      'quarterly': targetAmount * (averageRate / 4),
      'semiAnnual': targetAmount * (averageRate / 2),
      'annual': targetAmount * averageRate,
      'atMaturity': targetAmount * averageRate * duration,
      'isChangingRate': isChangingRate,
    };
  }

  List<double> extractInterestRates(String interestRate) {
    RegExp regExp = RegExp(r'\d+(\.\d+)?(?=%)');
    return regExp
        .allMatches(interestRate)
        .map((match) => double.parse(match.group(0)!))
        .toList();
  }

  double roundToNearestMultiple(double targetAmount, double multiple) {
    return (targetAmount / multiple).floorToDouble() * multiple;
  }

  double _calculateInterval(List historicalData) {
    if (historicalData.isEmpty) return 5.0;

    double maxValue = 0;
    for (var item in historicalData) {
      maxValue = math.max(
        maxValue,
        math.max(
          item['open'].toDouble(),
          math.max(item['close'].toDouble(), item['high'].toDouble()),
        ),
      );
    }

    // Choose an interval based on the data range
    if (maxValue > 1000) return 100.0;
    if (maxValue > 500) return 50.0;
    if (maxValue > 200) return 20.0;
    if (maxValue > 100) return 10.0;
    if (maxValue > 50) return 5.0;
    if (maxValue > 20) return 2.0;
    return 1.0;
  }

  Future<void> _launchURL(String url) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bool isMounted = context.mounted;

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (isMounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Cannot launch $url')),
          );
        }
      }
    } catch (e) {
      if (isMounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
  }

  // Open chatbot modal
  void _openChatbot(dynamic investment, String type) {
    setState(() {
      showChatModal = true;
      chatResponses = [];
      selectedInvestment = investment;
      selectedInvestmentType = type;

      // Add initial welcome message
      if (type == 'certificate') {
        final bank = banks.firstWhere(
          (b) => b['certificates'].any((c) => c['type'] == investment['type']),
          orElse: () => {'name': 'Unknown Bank'},
        );

        chatResponses.add({
          'message':
              'I\'m analyzing your ${investment['type']} certificate from ${bank['name']} now. Just a moment while I prepare insights on returns and suitability for your investment.',
          'isBot': true,
        });

        _sendInitialInvestmentInfo(investment, bank, 'certificate');
      } else if (type == 'stock') {
        chatResponses.add({
          'message':
              'I\'m analyzing ${investment['name']} (${investment['code']}) stock now. Just a moment while I prepare insights on performance and suitability for your investment.',
          'isBot': true,
        });

        _sendInitialInvestmentInfo(investment, null, 'stock');
      }
    });
  }

  // Close chatbot modal
  void _closeChatbot() {
    setState(() {
      showChatModal = false;
    });
  }

  // Send investment info to chatbot
  void _sendInitialInvestmentInfo(
    dynamic investment,
    dynamic bank,
    String type,
  ) async {
    setState(() {
      isChatLoading = true;
    });

    String initialMessage = '';

    if (type == 'certificate') {
      // Format certificate data for analysis
      initialMessage = '''
        You are a Professional Financial Advisor with comprehensive expertise in Egyptian banks' certificates, including interest rate structures, bank reliability, and Egypt's economic environment. I'm considering a ${investment['type']} from ${bank?['name'] ?? 'unspecified bank'} with the following details:

        - Duration: ${investment['duration']} year(s)
        - Minimum Investment: ${investment['minInvestment']} EGP
        - My Investment Amount: ${goal['target_amount'] != null ? roundToNearestMultiple(double.parse(goal['target_amount']), investment['multiples'].toDouble()) : 'Not set'} EGP
        - Interest Rates:
          ${investment['dailyInterestRate'] != null ? 'Daily: ${investment['dailyInterestRate']}' : ''}
          ${investment['monthlyInterestRate'] != null ? 'Monthly: ${investment['monthlyInterestRate']}' : ''}
          ${investment['quarterlyInterestRate'] != null ? 'Quarterly: ${investment['quarterlyInterestRate']}' : ''}
          ${investment['semiAnnuallyInterestRate'] != null ? 'Semi-Annual: ${investment['semiAnnuallyInterestRate']}' : ''}
          ${investment['annuallyInterestRate'] != null ? 'Annual: ${investment['annuallyInterestRate']}' : ''}
          ${investment['atMaturityInterestRate'] != null ? 'At Maturity: ${investment['atMaturityInterestRate']}' : ''}

        Please provide a detailed analysis of whether this certificate is a good investment, considering my investment amount and Egypt's financial landscape. Include:
        1. Pros and cons of this certificate compared to other Egyptian bank offerings.
        2. Key risks (e.g., bank stability, inflation, early withdrawal penalties).
        3. A recommendation on the optimal interest rate payout option (e.g., monthly, at maturity) based on my financial goals and Egypt's economic conditions (e.g., inflation trends, EGP stability).
        Ensure the analysis uses my spending data and reflects current Egyptian banking regulations and market conditions.
      ''';
    } else if (type == 'stock') {
      // Format stock data for analysis
      initialMessage = '''
        You are a Professional Financial Advisor with extensive expertise in the Egyptian Stocks Market, including deep knowledge of market trends, sectoral performance, and economic factors impacting Egypt. I'm evaluating ${investment['name']} (${investment['code']}) stock listed on ${investment['exchange']}, with prices in ${investment['currency'] ?? 'EGP'}. Below are the details:

        - Current Price: ${investment['historicalData'] != null && investment['historicalData'].isNotEmpty ? investment['historicalData'][investment['historicalData'].length - 1]['close'] : 'Not available'}
        - Current Volume: ${investment['historicalData'] != null && investment['historicalData'].isNotEmpty ? investment['historicalData'][investment['historicalData'].length - 1]['volume'] : 'Not available'}
        - My Investment Amount: ${goal['target_amount']?.toString() ?? 'Not set'} EGP
        - Estimated Shares: ${investment['historicalData'] != null && goal['target_amount'] != null ? (double.parse(goal['target_amount']) / (investment['historicalData'][investment['historicalData'].length - 1]['close'] ?? 1)).floor() : 'Not calculated'}
        - Historical Data (last 10 days, if available):
          ${investment['historicalData'] != null && investment['historicalData'].isNotEmpty ? List.from(investment['historicalData']).reversed.take(10).map((data) => '${data['date']}: Close=${data['close']}, High=${data['high']}, Low=${data['low']}, Volume=${data['volume']}').join('\n') : 'No historical data provided'}

        Please provide a detailed analysis of whether this is a sound investment, considering my investment amount, current Egyptian market conditions, and the stock's performance. Include:
        1. Pros and cons of Sponsors for this stock.
        2. Key risks (e.g., volatility, sector-specific issues, macroeconomic factors in Egypt).
        3. A recommendation on whether to invest now or wait, with justification.
        Ensure the analysis incorporates my spending data and aligns with Egypt's economic context (e.g., inflation, currency stability).
      ''';
    }

    // Send message to API
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final response = await apiService.sendChatMessage(initialMessage);

      if (mounted) {
        setState(() {
          isChatLoading = false;
          if (response != null && response['message'] != null) {
            chatResponses.add({'message': response['message'], 'isBot': true});
          } else {
            chatResponses.add({
              'message':
                  "I couldn't generate a specific analysis for this investment. Please consider traditional financial metrics like potential return, risk level, and your investment timeline.",
              'isBot': true,
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isChatLoading = false;
          chatResponses.add({
            'message':
                "Sorry, I'm having trouble analyzing this investment right now. Please try again later or consult with a financial advisor.",
            'isBot': true,
          });
        });
      }
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
                                Icons.trending_up,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Investment Explorer',
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
                              'Explore ways to grow your savings',
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
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

                      if (!isLoading && !showInvestmentModeMessage)
                        _buildTabNavigation(),

                      if (!isLoading &&
                          !showInvestmentModeMessage &&
                          activeTab == 'certificates')
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Banks Data Update: 1st of Feb. 2025',
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const Text(
                                'Explore top investment options from Egyptian leading banks.',
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                      if (!isLoading &&
                          !showInvestmentModeMessage &&
                          activeTab == 'stocks')
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Stocks Data Update:',
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                DateFormat('MMMM d, yyyy').format(currentDate),
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const Text(
                                'Explore investment opportunities in the Egyptian stock market (EGX).',
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                      if (!isLoading && showInvestmentModeMessage)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD1DBE5)),
                          ),
                          child: Column(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.lock,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'To turn on Investment Explorer, just include "invest" in your goal name.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      if (!isLoading &&
                          !showInvestmentModeMessage &&
                          activeTab == 'certificates')
                        _buildCertificatesContent(),
                      if (!isLoading &&
                          !showInvestmentModeMessage &&
                          activeTab == 'stocks')
                        _buildStocksContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showChatModal) _buildChatbotModal(),
          if (showCompareModal) _buildComparisonModal(),
        ],
      ),
    );
  }

  // Tab navigation widget
  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Bank Certificates',
              icon: Icons.account_balance,
              isActive: activeTab == 'certificates',
              onTap: () => _switchTab('certificates'),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Egyptian Stock Market',
              icon: FontAwesomeIcons.chartLine,
              isActive: activeTab == 'stocks',
              onTap: () => _switchTab('stocks'),
            ),
          ),
        ],
      ),
    );
  }

  // Tab button widget
  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: isActive ? Colors.blue : Colors.grey, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.blue : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Build certificates content
  Widget _buildCertificatesContent() {
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: selectedBankName,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  hintText: 'Select a Bank',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                isExpanded: true,
                items:
                    banks.map((bank) {
                      return DropdownMenuItem<String>(
                        value: bank['name'],
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bank['name'],
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedBankName = newValue;
                  });
                },
                dropdownColor: Colors.grey[100],
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF6B7280),
                  size: 24,
                ),
                style: const TextStyle(color: Colors.blueGrey, fontSize: 16),
              ),
            ),
          ),
        ),
        if (selectedBankName != null) _buildSelectedBankCard(),
      ],
    );
  }

  // Build the bank card for the selected bank
  Widget _buildSelectedBankCard() {
    final selectedBank = banks.firstWhere(
      (bank) => bank['name'] == selectedBankName,
      orElse: () => banks[0],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Image.asset(
                      selectedBank['image'],
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text(
                    selectedBank['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedBank['description'],
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),

                  // Compare button
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed:
                        selectedCertificates.length < 2
                            ? null
                            : _openCompareModal,
                    icon: Icon(
                      FontAwesomeIcons.scaleBalanced,
                      size: 16,
                      color:
                          selectedCertificates.length < 2
                              ? Colors.grey[600]
                              : Colors.white,
                    ),
                    label: Text(
                      'Compare Selected (${selectedCertificates.length})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedBank['certificates'].length,
                    itemBuilder: (context, index) {
                      return _buildCertificateCard(
                        selectedBank['certificates'][index],
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _launchURL(selectedBank['investmentLink']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'More Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build certificate card
  Widget _buildCertificateCard(Map<String, dynamic> certificate) {
    final selectedBank = banks.firstWhere(
      (bank) => bank['name'] == selectedBankName,
      orElse: () => banks[0],
    );

    final targetAmount = double.tryParse(goal['target_amount'] ?? '0') ?? 0.0;
    final roundedAmount = roundToNearestMultiple(
      targetAmount,
      certificate['multiples'].toDouble(),
    );

    final dailyReturns =
        certificate['dailyInterestRate'] != null
            ? calculateReturns(
              roundedAmount,
              certificate['dailyInterestRate'],
              certificate['duration'].toDouble(),
            )
            : null;

    final monthlyReturns =
        certificate['monthlyInterestRate'] != null
            ? calculateReturns(
              roundedAmount,
              certificate['monthlyInterestRate'],
              certificate['duration'].toDouble(),
            )
            : null;

    final quarterlyReturns =
        certificate['quarterlyInterestRate'] != null
            ? calculateReturns(
              roundedAmount,
              certificate['quarterlyInterestRate'],
              certificate['duration'].toDouble(),
            )
            : null;

    final semiAnnualReturns =
        certificate['semiAnnuallyInterestRate'] != null
            ? calculateReturns(
              roundedAmount,
              certificate['semiAnnuallyInterestRate'],
              certificate['duration'].toDouble(),
            )
            : null;

    final annualReturns =
        certificate['annuallyInterestRate'] != null
            ? calculateReturns(
              roundedAmount,
              certificate['annuallyInterestRate'],
              certificate['duration'].toDouble(),
            )
            : null;

    final atMaturityReturns =
        certificate['atMaturityInterestRate'] != null
            ? calculateReturns(
              roundedAmount,
              certificate['atMaturityInterestRate'],
              certificate['duration'].toDouble(),
            )
            : null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Certificate name
            Text(
              certificate['type'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Checkbox
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _isCertificateSelected(certificate, selectedBank),
                  onChanged: (bool? value) {
                    _toggleCertificateSelection(certificate, selectedBank);
                  },
                  activeColor: Colors.blue,
                ),
                Text(
                  "Add to comparison",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Duration: ${certificate['duration'].toInt()} years',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Min Investment: E£${NumberFormat('#,##0').format(certificate['minInvestment'])}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Multiples: E£${NumberFormat('#,##0').format(certificate['multiples'])}',
              style: const TextStyle(fontSize: 14),
            ),
            const Divider(),
            if (certificate['dailyInterestRate'] != null)
              Text(
                'Daily: ${certificate['dailyInterestRate']}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            if (certificate['monthlyInterestRate'] != null)
              Text(
                'Monthly: ${certificate['monthlyInterestRate']}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            if (certificate['quarterlyInterestRate'] != null)
              Text(
                'Quarterly: ${certificate['quarterlyInterestRate']}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            if (certificate['semiAnnuallyInterestRate'] != null)
              Text(
                'Semi-Annual: ${certificate['semiAnnuallyInterestRate']}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            if (certificate['annuallyInterestRate'] != null)
              Text(
                'Annual: ${certificate['annuallyInterestRate']}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            if (certificate['atMaturityInterestRate'] != null)
              Text(
                'At Maturity: ${certificate['atMaturityInterestRate']}',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            const Divider(),
            if (goal['target_amount'] != null) ...[
              Text(
                'Your Investment: E£${NumberFormat('#,##0').format(roundedAmount)}',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
              if (targetAmount < certificate['minInvestment'])
                Text(
                  'Min Required: E£${NumberFormat('#,##0').format(certificate['minInvestment'])}',
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                ),
              if (targetAmount >= certificate['minInvestment']) ...[
                if (dailyReturns != null)
                  Text(
                    'Daily Return: E£${NumberFormat('#,##0${dailyReturns['daily'] % 1 == 0 ? '' : '.00'}').format(dailyReturns['daily'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                if (monthlyReturns != null)
                  Text(
                    'Monthly Return: E£${NumberFormat('#,##0${monthlyReturns['monthly'] % 1 == 0 ? '' : '.00'}').format(monthlyReturns['monthly'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                if (quarterlyReturns != null)
                  Text(
                    'Quarterly Return: E£${NumberFormat('#,##0${quarterlyReturns['quarterly'] % 1 == 0 ? '' : '.00'}').format(quarterlyReturns['quarterly'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                if (semiAnnualReturns != null)
                  Text(
                    'Semi-Annual Return: E£${NumberFormat('#,##0${semiAnnualReturns['semiAnnual'] % 1 == 0 ? '' : '.00'}').format(semiAnnualReturns['semiAnnual'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                if (annualReturns != null)
                  Text(
                    'Annual Return: E£${NumberFormat('#,##0${annualReturns['annual'] % 1 == 0 ? '' : '.00'}').format(annualReturns['annual'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                if (atMaturityReturns != null)
                  Text(
                    'At Maturity Return: E£${NumberFormat('#,##0${atMaturityReturns['atMaturity'] % 1 == 0 ? '' : '.00'}').format(atMaturityReturns['atMaturity'])}',
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              certificate['description'],
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _openChatbot(certificate, 'certificate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.comment_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Get Financial Advice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                              MediaQuery.of(context).size.width < 360 ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build stocks content
  Widget _buildStocksContent() {
    if (isLoadingStocks) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            CircularProgressIndicator(color: Color(0xFF2196F3)),
            SizedBox(height: 16),
            Text(
              'Loading stock data...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      );
    }

    if (stocksError.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            Text(
              stocksError,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search and stock list
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  // Search box
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.search, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Search Stocks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                _searchStocks();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stock list
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.list, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'EGX Available Stocks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 400,
                          constraints: const BoxConstraints(maxHeight: 400),
                          child:
                              filteredStocks.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.search_off,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No stocks found matching "$searchQuery"',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Try adjusting your search criteria',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: filteredStocks.length,
                                    itemBuilder: (context, index) {
                                      final stock = filteredStocks[index];
                                      final bool isSelected =
                                          selectedStock != null &&
                                          selectedStock!['code'] ==
                                              stock['code'];

                                      return ListTile(
                                        title: Text(
                                          stock['name'],
                                          style: TextStyle(
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color:
                                                isSelected
                                                    ? Colors.blue
                                                    : Colors.black87,
                                          ),
                                        ),
                                        subtitle: Text(
                                          stock['code'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isSelected
                                                    ? Colors.blue.shade700
                                                    : Colors.grey,
                                          ),
                                        ),
                                        tileColor:
                                            isSelected
                                                ? Colors.blue.withValues(
                                                  alpha: 0.1,
                                                )
                                                : null,
                                        onTap: () => _viewStockDetails(stock),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stock details
            if (MediaQuery.of(context).size.width > 800)
              const SizedBox(width: 16),

            if (MediaQuery.of(context).size.width > 800)
              Expanded(
                flex: 2,
                child:
                    selectedStock == null
                        ? _buildNoStockSelectedCard()
                        : _buildStockDetailsCard(),
              ),
          ],
        ),

        // Stock details for smaller screens
        if (MediaQuery.of(context).size.width <= 800)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child:
                selectedStock == null
                    ? _buildNoStockSelectedCard()
                    : _buildStockDetailsCard(),
          ),
      ],
    );
  }

  // Widget for when no stock is selected
  Widget _buildNoStockSelectedCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 72,
              color: Colors.blue.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select a stock to view detailed information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse the Egyptian stocks from the list',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget for stock details
  Widget _buildStockDetailsCard() {
    final stock = selectedStock!;
    final hasHistoricalData =
        stock['historicalData'] != null &&
        (stock['historicalData'] as List).isNotEmpty;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.insights,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          Text(
                            stock['code'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Company and investment information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Company Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('Symbol', stock['code']),
                    _buildInfoRow('Exchange', stock['exchange'] ?? 'EGX'),
                    _buildInfoRow('Country', stock['country'] ?? 'Egypt'),
                    _buildInfoRow('Currency', stock['currency'] ?? 'EGP'),
                    _buildInfoRow('Type', stock['type'] ?? 'Common Stock'),
                    if (stock['isin'] != null)
                      _buildInfoRow('ISIN', stock['isin']),
                  ],
                ),

                // Investment information
                if (hasHistoricalData && goal['target_amount'] != null) ...[
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Investment Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Your Investment',
                        'E£${NumberFormat('#,##0').format(double.parse(goal['target_amount']))}',
                        valueColor: Colors.green,
                      ),
                      _buildInfoRow(
                        'Current Price',
                        'E£${NumberFormat('#,##0.00').format(stock['historicalData'][stock['historicalData'].length - 1]['close'])}',
                      ),
                      _buildInfoRow(
                        'Estimated Shares',
                        '${(double.parse(goal['target_amount']) / stock['historicalData'][stock['historicalData'].length - 1]['close']).floor()}',
                      ),
                    ],
                  ),
                ],

                // Historical data table
                if (hasHistoricalData) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.clockRotateLeft,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Historical Price Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 18,
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Open')),
                        DataColumn(label: Text('High')),
                        DataColumn(label: Text('Low')),
                        DataColumn(label: Text('Close')),
                        DataColumn(label: Text('Volume')),
                      ],
                      rows:
                          List.from(
                            stock['historicalData'],
                          ).reversed.take(10).map<DataRow>((data) {
                            final isUp = data['close'] > data['open'];
                            final isDown = data['close'] < data['open'];
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    data['date'],
                                    style: TextStyle(
                                      color:
                                          isUp
                                              ? Colors.green
                                              : (isDown
                                                  ? Colors.red
                                                  : Colors.amber),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'E£${NumberFormat('#,##0.00').format(data['open'])}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'E£${NumberFormat('#,##0.00').format(data['high'])}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'E£${NumberFormat('#,##0.00').format(data['low'])}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'E£${NumberFormat('#,##0.00').format(data['close'])}',
                                    style: TextStyle(
                                      color:
                                          isUp
                                              ? Colors.green
                                              : (isDown
                                                  ? Colors.red
                                                  : Colors.amber),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    NumberFormat(
                                      '#,###',
                                    ).format(data['volume']),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),

                  // Stock chart
                  if (hasHistoricalData) ...[
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.show_chart,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Price Trend',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.grey,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'From ${stock['historicalData'][0]['date']} to ${stock['historicalData'][stock['historicalData'].length - 1]['date']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 250,
                            padding: const EdgeInsets.all(16),
                            child: _buildStockChart(stock),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Investment tips
                  const SizedBox(height: 24),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Investment Tips',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTipItem(
                                      Icons.search,
                                      'Research company fundamentals before investing',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTipItem(
                                      Icons.pie_chart,
                                      'Diversify your investments across multiple sectors',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTipItem(
                                      Icons.show_chart,
                                      'Past performance doesn\'t guarantee future results',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTipItem(
                                      Icons.person,
                                      'Consider consulting with a professional financial advisor',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Footer actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed:
                      () =>
                          _launchURL('https://www.egx.com.eg/en/homepage.aspx'),
                  icon: const Icon(Icons.open_in_new, color: Colors.blue),
                  label:
                      MediaQuery.of(context).size.width < 360
                          ? const Text('Visit EGX')
                          : const Text('Visit Egyptian Exchange (EGX)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _openChatbot(stock, 'stock'),
                  icon: const Icon(Icons.comment_outlined, color: Colors.blue),
                  label:
                      MediaQuery.of(context).size.width < 360
                          ? const Text('Get Advice')
                          : const Text('Get Financial Advice'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for building info rows
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for building tip items
  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }

  // Build stock chart using fl_chart
  Widget _buildStockChart(Map<String, dynamic> stock) {
    if (stock['historicalData'] == null ||
        (stock['historicalData'] as List).isEmpty) {
      return const Center(child: Text('No historical data available'));
    }

    final List<FlSpot> closeSpots = [];
    final List<FlSpot> openSpots = [];
    final List<String> bottomTitles = [];

    // Prepare data
    final List historicalData = List.from(stock['historicalData']);
    for (int i = 0; i < historicalData.length; i++) {
      closeSpots.add(
        FlSpot(i.toDouble(), historicalData[i]['close'].toDouble()),
      );
      openSpots.add(FlSpot(i.toDouble(), historicalData[i]['open'].toDouble()));
      bottomTitles.add(historicalData[i]['date']);
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < bottomTitles.length &&
                    value.toInt() % 3 == 0) {
                  final formattedDate = bottomTitles[value.toInt()].substring(
                    5,
                  ); // Show only MM-DD
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat('#,##0').format(value),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
              reservedSize: 40,
              interval: _calculateInterval(historicalData),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        lineBarsData: [
          // Close price line
          LineChartBarData(
            spots: closeSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
          // Open price line
          LineChartBarData(
            spots: openSpots,
            isCurved: true,
            color: Colors.grey,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                final date = bottomTitles[index];
                final value = barSpot.y;
                final isCloseLine = barSpot.barIndex == 0;

                return LineTooltipItem(
                  '${isCloseLine ? 'Close' : 'Open'}: E£${NumberFormat('#,##0.00').format(value)}\n$date',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonModal() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity, // Full width
            height:
                MediaQuery.of(context).size.height *
                0.9, // 90% of screen height
            constraints: const BoxConstraints(maxWidth: 900),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.scaleBalanced,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Compare Certificates',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _closeCompareModal,
                      ),
                    ],
                  ),
                ),

                // Comparison table with horizontal scroll
                Expanded(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: IntrinsicWidth(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header row with certificate names
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Empty cell for the property column header
                                  Container(
                                    width:
                                        160, // Fixed width for property column
                                    padding: const EdgeInsets.all(12),
                                  ),

                                  // Certificate headers with delete buttons
                                  ...selectedCertificates.map((item) {
                                    final certificate = item['certificate'];

                                    return Container(
                                      width:
                                          200, // Fixed width for each certificate column
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 22,
                                            ),
                                            onPressed:
                                                () =>
                                                    _removeCertificateFromComparison(
                                                      item,
                                                    ),
                                            tooltip: 'Remove from comparison',
                                            constraints: const BoxConstraints(
                                              minHeight: 36,
                                            ),
                                          ),
                                          Text(
                                            certificate['type'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),

                              const SizedBox(height: 10),
                              Divider(thickness: 2, color: Colors.grey[300]),

                              // Bank row - always shown
                              _buildCompareFixedRow(
                                'Bank',
                                (item) => item['bank']['name'],
                              ),

                              // Duration row - always shown
                              _buildCompareFixedRow(
                                'Duration (Years)',
                                (item) =>
                                    item['certificate']['duration'].toString(),
                                valueLabelKey: 'duration',
                              ),

                              // Min Investment row - always shown
                              _buildCompareFixedRow(
                                'Min Investment',
                                (item) =>
                                    'E£${NumberFormat('#,##0').format(item['certificate']['minInvestment'])}',
                                valueLabelKey: 'minInvestment',
                              ),

                              // Allowed Multiples row - always shown
                              _buildCompareFixedRow(
                                'Allowed Multiples',
                                (item) =>
                                    'E£${NumberFormat('#,##0').format(item['certificate']['multiples'])}',
                                valueLabelKey: 'multiples',
                              ),

                              // Interest rates - check if any certificates have this attribute
                              _buildCompareFixedRowIfAnyExists(
                                'Daily Interest',
                                selectedCertificates,
                                (item) =>
                                    item['certificate']['dailyInterestRate'] ??
                                    '-',
                                valueCheck:
                                    (item) =>
                                        item['certificate']['dailyInterestRate'] !=
                                        null,
                                interestRateKey: 'dailyInterestRate',
                                valueLabelKey: 'dailyInterest',
                              ),

                              _buildCompareFixedRowIfAnyExists(
                                'Monthly Interest',
                                selectedCertificates,
                                (item) =>
                                    item['certificate']['monthlyInterestRate'] ??
                                    '-',
                                valueCheck:
                                    (item) =>
                                        item['certificate']['monthlyInterestRate'] !=
                                        null,
                                interestRateKey: 'monthlyInterestRate',
                                valueLabelKey: 'monthlyInterest',
                              ),

                              _buildCompareFixedRowIfAnyExists(
                                'Quarterly Interest',
                                selectedCertificates,
                                (item) =>
                                    item['certificate']['quarterlyInterestRate'] ??
                                    '-',
                                valueCheck:
                                    (item) =>
                                        item['certificate']['quarterlyInterestRate'] !=
                                        null,
                                interestRateKey: 'quarterlyInterestRate',
                                valueLabelKey: 'quarterlyInterest',
                              ),

                              _buildCompareFixedRowIfAnyExists(
                                'Semi-Annual Interest',
                                selectedCertificates,
                                (item) =>
                                    item['certificate']['semiAnnuallyInterestRate'] ??
                                    '-',
                                valueCheck:
                                    (item) =>
                                        item['certificate']['semiAnnuallyInterestRate'] !=
                                        null,
                                interestRateKey: 'semiAnnuallyInterestRate',
                                valueLabelKey: 'semiAnnualInterest',
                              ),

                              _buildCompareFixedRowIfAnyExists(
                                'Annual Interest',
                                selectedCertificates,
                                (item) =>
                                    item['certificate']['annuallyInterestRate'] ??
                                    '-',
                                valueCheck:
                                    (item) =>
                                        item['certificate']['annuallyInterestRate'] !=
                                        null,
                                interestRateKey: 'annuallyInterestRate',
                                valueLabelKey: 'annualInterest',
                              ),

                              _buildCompareFixedRowIfAnyExists(
                                'At Maturity Interest',
                                selectedCertificates,
                                (item) =>
                                    item['certificate']['atMaturityInterestRate'] ??
                                    '-',
                                valueCheck:
                                    (item) =>
                                        item['certificate']['atMaturityInterestRate'] !=
                                        null,
                                interestRateKey: 'atMaturityInterestRate',
                                valueLabelKey: 'atMaturityInterest',
                              ),

                              // Investment and returns only if target_amount is set
                              if (goal['target_amount'] != null) ...[
                                _buildCompareFixedRow(
                                  'Your Investment',
                                  (item) {
                                    final targetAmount =
                                        double.tryParse(
                                          goal['target_amount'] ?? '0',
                                        ) ??
                                        0.0;
                                    final roundedAmount =
                                        roundToNearestMultiple(
                                          targetAmount,
                                          item['certificate']['multiples']
                                              .toDouble(),
                                        );
                                    final belowMin =
                                        targetAmount <
                                        item['certificate']['minInvestment'];

                                    return 'E£${NumberFormat('#,##0').format(roundedAmount)}${belowMin ? '\n(Below Min)' : ''}';
                                  },
                                  valueLabelKey: 'yourInvestment',
                                  showBelowMinWarning: true,
                                ),

                                // Returns rows - only show if any certificate has this return type
                                _buildCompareFixedRowIfAnyExists(
                                  'Daily Return',
                                  selectedCertificates,
                                  (item) {
                                    final targetAmount =
                                        double.tryParse(
                                          goal['target_amount'] ?? '0',
                                        ) ??
                                        0.0;
                                    final roundedAmount =
                                        roundToNearestMultiple(
                                          targetAmount,
                                          item['certificate']['multiples']
                                              .toDouble(),
                                        );
                                    final dailyRate =
                                        _getInterestRateForReturnType(
                                          item['certificate'],
                                          'daily',
                                        );
                                    if (dailyRate == null) return '-';

                                    final dailyReturn =
                                        calculateReturns(
                                          roundedAmount,
                                          dailyRate,
                                          item['certificate']['duration']
                                              .toDouble(),
                                        )['daily'];

                                    return 'E£${NumberFormat('#,##0.00').format(dailyReturn)}';
                                  },
                                  valueCheck:
                                      (item) =>
                                          item['certificate']['dailyInterestRate'] !=
                                          null,
                                  valueLabelKey: 'dailyReturn',
                                ),

                                _buildCompareFixedRowIfAnyExists(
                                  'Monthly Return',
                                  selectedCertificates,
                                  (item) {
                                    final targetAmount =
                                        double.tryParse(
                                          goal['target_amount'] ?? '0',
                                        ) ??
                                        0.0;
                                    final roundedAmount =
                                        roundToNearestMultiple(
                                          targetAmount,
                                          item['certificate']['multiples']
                                              .toDouble(),
                                        );
                                    final monthlyRate =
                                        _getInterestRateForReturnType(
                                          item['certificate'],
                                          'monthly',
                                        );
                                    if (monthlyRate == null) return '-';

                                    final monthlyReturn =
                                        calculateReturns(
                                          roundedAmount,
                                          monthlyRate,
                                          item['certificate']['duration']
                                              .toDouble(),
                                        )['monthly'];

                                    return 'E£${NumberFormat('#,##0.00').format(monthlyReturn)}';
                                  },
                                  valueCheck:
                                      (item) =>
                                          item['certificate']['monthlyInterestRate'] !=
                                          null,
                                  valueLabelKey: 'monthlyReturn',
                                ),

                                _buildCompareFixedRowIfAnyExists(
                                  'Quarterly Return',
                                  selectedCertificates,
                                  (item) {
                                    final targetAmount =
                                        double.tryParse(
                                          goal['target_amount'] ?? '0',
                                        ) ??
                                        0.0;
                                    final roundedAmount =
                                        roundToNearestMultiple(
                                          targetAmount,
                                          item['certificate']['multiples']
                                              .toDouble(),
                                        );
                                    final quarterlyRate =
                                        _getInterestRateForReturnType(
                                          item['certificate'],
                                          'quarterly',
                                        );
                                    if (quarterlyRate == null) return '-';

                                    final quarterlyReturn =
                                        calculateReturns(
                                          roundedAmount,
                                          quarterlyRate,
                                          item['certificate']['duration']
                                              .toDouble(),
                                        )['quarterly'];

                                    return 'E£${NumberFormat('#,##0.00').format(quarterlyReturn)}';
                                  },
                                  valueCheck:
                                      (item) =>
                                          item['certificate']['quarterlyInterestRate'] !=
                                          null,
                                  valueLabelKey: 'quarterlyReturn',
                                ),

                                _buildCompareFixedRowIfAnyExists(
                                  'Semi-Annual Return',
                                  selectedCertificates,
                                  (item) {
                                    final targetAmount =
                                        double.tryParse(
                                          goal['target_amount'] ?? '0',
                                        ) ??
                                        0.0;
                                    final roundedAmount =
                                        roundToNearestMultiple(
                                          targetAmount,
                                          item['certificate']['multiples']
                                              .toDouble(),
                                        );
                                    final semiAnnualRate =
                                        _getInterestRateForReturnType(
                                          item['certificate'],
                                          'semiAnnual',
                                        );
                                    if (semiAnnualRate == null) return '-';

                                    final semiAnnualReturn =
                                        calculateReturns(
                                          roundedAmount,
                                          semiAnnualRate,
                                          item['certificate']['duration']
                                              .toDouble(),
                                        )['semiAnnual'];

                                    return 'E£${NumberFormat('#,##0.00').format(semiAnnualReturn)}';
                                  },
                                  valueCheck:
                                      (item) =>
                                          item['certificate']['semiAnnuallyInterestRate'] !=
                                          null,
                                  valueLabelKey: 'semiAnnualReturn',
                                ),

                                _buildCompareFixedRowIfAnyExists(
                                  'Annual Return',
                                  selectedCertificates,
                                  (item) {
                                    final targetAmount =
                                        double.tryParse(
                                          goal['target_amount'] ?? '0',
                                        ) ??
                                        0.0;
                                    final roundedAmount =
                                        roundToNearestMultiple(
                                          targetAmount,
                                          item['certificate']['multiples']
                                              .toDouble(),
                                        );
                                    final annualRate =
                                        _getInterestRateForReturnType(
                                          item['certificate'],
                                          'annual',
                                        );
                                    if (annualRate == null) return '-';

                                    final annualReturn =
                                        calculateReturns(
                                          roundedAmount,
                                          annualRate,
                                          item['certificate']['duration']
                                              .toDouble(),
                                        )['annual'];

                                    return 'E£${NumberFormat('#,##0.00').format(annualReturn)}';
                                  },
                                  valueCheck:
                                      (item) =>
                                          item['certificate']['annuallyInterestRate'] !=
                                          null,
                                  valueLabelKey: 'annualReturn',
                                ),

                                _buildCompareFixedRowIfAnyExists(
                                  'At Maturity Return',
                                  selectedCertificates,
                                  (item) {
                                    final targetAmount =
                                        double.tryParse(
                                          goal['target_amount'] ?? '0',
                                        ) ??
                                        0.0;
                                    final roundedAmount =
                                        roundToNearestMultiple(
                                          targetAmount,
                                          item['certificate']['multiples']
                                              .toDouble(),
                                        );
                                    final atMaturityRate =
                                        _getInterestRateForReturnType(
                                          item['certificate'],
                                          'atMaturity',
                                        );
                                    if (atMaturityRate == null) return '-';

                                    final atMaturityReturn =
                                        calculateReturns(
                                          roundedAmount,
                                          atMaturityRate,
                                          item['certificate']['duration']
                                              .toDouble(),
                                        )['atMaturity'];

                                    return 'E£${NumberFormat('#,##0.00').format(atMaturityReturn)}';
                                  },
                                  valueCheck:
                                      (item) =>
                                          item['certificate']['atMaturityInterestRate'] !=
                                          null,
                                  valueLabelKey: 'atMaturityReturn',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Footer with centered button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _closeCompareModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for building comparison rows with fixed widths
  Widget _buildCompareFixedRow(
    String label,
    String Function(Map<String, dynamic>) valueGetter, {
    String? interestRateKey,
    String? valueLabelKey,
    bool showBelowMinWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Property label (fixed width)
          Container(
            width: 160,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[200]!)),
              color: Colors.grey[100],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),

          // Certificate values
          ...selectedCertificates.map((item) {
            final certificate = item['certificate'];
            final valueText = valueGetter(item);
            bool isWinner = false;

            if (valueLabelKey != null &&
                winningValues.containsKey(valueLabelKey)) {
              if (valueLabelKey.contains('Return') && valueText != '-') {
                final numericValue = double.tryParse(
                  valueText.replaceAll('E£', '').replaceAll(',', ''),
                );

                if (numericValue != null &&
                    winningValues[valueLabelKey] != null &&
                    (numericValue - winningValues[valueLabelKey]).abs() <
                        0.01) {
                  isWinner = true;
                }
              } else if (interestRateKey != null &&
                  certificate[interestRateKey] != null) {
                // For interest rates
                final avgRate = calculateAverageRate(
                  certificate[interestRateKey],
                );
                isWinner =
                    (avgRate - winningValues[valueLabelKey]).abs() < 0.01;
              } else if (valueText != '-') {
                // For other numeric values
                dynamic value;
                if (valueText.startsWith('E£')) {
                  // Extract numeric value from currency
                  value = double.tryParse(
                    valueText
                        .replaceAll('E£', '')
                        .replaceAll(',', '')
                        .split('\n')[0],
                  );
                } else {
                  value =
                      double.tryParse(valueText.split('\n')[0]) ?? valueText;
                }

                if (value != null) {
                  if (value is num && winningValues[valueLabelKey] is num) {
                    isWinner =
                        (value - winningValues[valueLabelKey]).abs() < 0.01;
                  } else {
                    isWinner = value == winningValues[valueLabelKey];
                  }
                }
              }
            }

            bool hasWarning =
                showBelowMinWarning && valueText.contains('(Below Min)');

            return Container(
              width: 200, // Fixed width for each value cell
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Text(
                valueText,
                style: TextStyle(
                  color:
                      hasWarning
                          ? Colors.red
                          : (isWinner ? Colors.green : Colors.black87),
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper method to build a comparison row only if any certificate has a value for this attribute
  Widget _buildCompareFixedRowIfAnyExists(
    String label,
    List<Map<String, dynamic>> certificates,
    String Function(Map<String, dynamic>) valueGetter, {
    required bool Function(Map<String, dynamic>) valueCheck,
    String? interestRateKey,
    String? valueLabelKey,
    bool showBelowMinWarning = false,
  }) {
    // Check if at least one certificate has a valid value for this attribute
    bool anyExists = certificates.any((item) => valueCheck(item));

    // If none have this attribute, don't show the row
    if (!anyExists) {
      return const SizedBox.shrink();
    }

    // Otherwise, build the row normally
    return _buildCompareFixedRow(
      label,
      valueGetter,
      interestRateKey: interestRateKey,
      valueLabelKey: valueLabelKey,
      showBelowMinWarning: showBelowMinWarning,
    );
  }

  // Build chatbot modal
  Widget _buildChatbotModal() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.smart_toy, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'AI Financial Chatbot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _closeChatbot,
                      ),
                    ],
                  ),
                ),

                // Chat messages
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child:
                        chatResponses.isEmpty
                            ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.comment,
                                    size: 48,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading Analysis...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Please wait while we analyze this investment.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount:
                                  chatResponses.length +
                                  (isChatLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index < chatResponses.length) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue.shade100,
                                      ),
                                    ),
                                    child: MarkdownBody(
                                      data: chatResponses[index]['message'],
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(fontSize: 14),
                                        h1: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h2: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h3: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        listBullet: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Loading indicator
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Analyzing',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _closeChatbot,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
