import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
          'monthlyInterestRate':
              '26% (1st year), 22.5% (2nd year), 19% (3rd year)',
          'quarterlyInterestRate':
              '27% (1st year), 23% (2nd year), 19% (3rd year)',
          'annuallyInterestRate':
              '30% (1st year), 25% (2nd year), 20% (3rd year)',
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
          'monthlyInterestRate':
              '26% (1st year), 22% (2nd year), 18% (3rd year)',
          'duration': 3,
          'minInvestment': 1000,
          'multiples': 1000,
          'description':
              'A declining interest certificate with a higher rate in the first year.',
        },
        {
          'type': 'Platinum Certificate With Annual Step Down Interest',
          'annuallyInterestRate':
              '30% (1st year), 25% (2nd year), 20% (3rd year)',
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
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonTopMargin = screenWidth < 600 ? 0 : 20;

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
                    'Explore bank certificates',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
                  if (!isLoading && !showInvestmentModeMessage)
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
                            'Explore top investment options from leading banks to grow your savings.',
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
                  if (!isLoading && !showInvestmentModeMessage)
                    Column(
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (selectedBankName != null)
                          Center(
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
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Image.asset(
                                            banks.firstWhere(
                                              (bank) =>
                                                  bank['name'] ==
                                                  selectedBankName,
                                            )['image'],
                                            width: 120,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        Text(
                                          selectedBankName!,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          banks.firstWhere(
                                            (bank) =>
                                                bank['name'] ==
                                                selectedBankName,
                                          )['description'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              banks
                                                  .firstWhere(
                                                    (bank) =>
                                                        bank['name'] ==
                                                        selectedBankName,
                                                  )['certificates']
                                                  .length,
                                          itemBuilder: (context, index) {
                                            final certificate =
                                                banks.firstWhere(
                                                  (bank) =>
                                                      bank['name'] ==
                                                      selectedBankName,
                                                )['certificates'][index];
                                            final targetAmount =
                                                double.tryParse(
                                                  goal['target_amount'] ?? '0',
                                                ) ??
                                                0.0;
                                            final roundedAmount =
                                                roundToNearestMultiple(
                                                  targetAmount,
                                                  certificate['multiples']
                                                      .toDouble(),
                                                );

                                            final dailyReturns =
                                                certificate['dailyInterestRate'] !=
                                                        null
                                                    ? calculateReturns(
                                                      roundedAmount,
                                                      certificate['dailyInterestRate'],
                                                      certificate['duration']
                                                          .toDouble(),
                                                    )
                                                    : null;
                                            final monthlyReturns =
                                                certificate['monthlyInterestRate'] !=
                                                        null
                                                    ? calculateReturns(
                                                      roundedAmount,
                                                      certificate['monthlyInterestRate'],
                                                      certificate['duration']
                                                          .toDouble(),
                                                    )
                                                    : null;
                                            final quarterlyReturns =
                                                certificate['quarterlyInterestRate'] !=
                                                        null
                                                    ? calculateReturns(
                                                      roundedAmount,
                                                      certificate['quarterlyInterestRate'],
                                                      certificate['duration']
                                                          .toDouble(),
                                                    )
                                                    : null;
                                            final semiAnnualReturns =
                                                certificate['semiAnnuallyInterestRate'] !=
                                                        null
                                                    ? calculateReturns(
                                                      roundedAmount,
                                                      certificate['semiAnnuallyInterestRate'],
                                                      certificate['duration']
                                                          .toDouble(),
                                                    )
                                                    : null;
                                            final annualReturns =
                                                certificate['annuallyInterestRate'] !=
                                                        null
                                                    ? calculateReturns(
                                                      roundedAmount,
                                                      certificate['annuallyInterestRate'],
                                                      certificate['duration']
                                                          .toDouble(),
                                                    )
                                                    : null;
                                            final atMaturityReturns =
                                                certificate['atMaturityInterestRate'] !=
                                                        null
                                                    ? calculateReturns(
                                                      roundedAmount,
                                                      certificate['atMaturityInterestRate'],
                                                      certificate['duration']
                                                          .toDouble(),
                                                    )
                                                    : null;

                                            return Card(
                                              elevation: 4,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      certificate['type'],
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.blueGrey,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'Duration: ${certificate['duration'].toInt()} years',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Min Investment: E£${NumberFormat('#,##0').format(certificate['minInvestment'])}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Multiples: E£${NumberFormat('#,##0').format(certificate['multiples'])}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const Divider(),
                                                    if (certificate['dailyInterestRate'] !=
                                                        null)
                                                      Text(
                                                        'Daily: ${certificate['dailyInterestRate']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    if (certificate['monthlyInterestRate'] !=
                                                        null)
                                                      Text(
                                                        'Monthly: ${certificate['monthlyInterestRate']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    if (certificate['quarterlyInterestRate'] !=
                                                        null)
                                                      Text(
                                                        'Quarterly: ${certificate['quarterlyInterestRate']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    if (certificate['semiAnnuallyInterestRate'] !=
                                                        null)
                                                      Text(
                                                        'Semi-Annual: ${certificate['semiAnnuallyInterestRate']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    if (certificate['annuallyInterestRate'] !=
                                                        null)
                                                      Text(
                                                        'Annual: ${certificate['annuallyInterestRate']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    if (certificate['atMaturityInterestRate'] !=
                                                        null)
                                                      Text(
                                                        'At Maturity: ${certificate['atMaturityInterestRate']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    const Divider(),
                                                    if (goal['target_amount'] !=
                                                        null) ...[
                                                      Text(
                                                        'Your Investment: E£${NumberFormat('#,##0').format(roundedAmount)}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                      if (targetAmount <
                                                          certificate['minInvestment'])
                                                        Text(
                                                          'Min Required: E£${NumberFormat('#,##0').format(certificate['minInvestment'])}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                        ),
                                                      if (targetAmount >=
                                                          certificate['minInvestment']) ...[
                                                        if (dailyReturns !=
                                                            null)
                                                          Text(
                                                            'Daily Return: E£${NumberFormat('#,##0${dailyReturns['daily'] % 1 == 0 ? '' : '.00'}').format(dailyReturns['daily'])}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                          ),
                                                        if (monthlyReturns !=
                                                            null)
                                                          Text(
                                                            'Monthly Return: E£${NumberFormat('#,##0${monthlyReturns['monthly'] % 1 == 0 ? '' : '.00'}').format(monthlyReturns['monthly'])}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                          ),
                                                        if (quarterlyReturns !=
                                                            null)
                                                          Text(
                                                            'Quarterly Return: E£${NumberFormat('#,##0${quarterlyReturns['quarterly'] % 1 == 0 ? '' : '.00'}').format(quarterlyReturns['quarterly'])}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                          ),
                                                        if (semiAnnualReturns !=
                                                            null)
                                                          Text(
                                                            'Semi-Annual Return: E£${NumberFormat('#,##0${semiAnnualReturns['semiAnnual'] % 1 == 0 ? '' : '.00'}').format(semiAnnualReturns['semiAnnual'])}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                          ),
                                                        if (annualReturns !=
                                                            null)
                                                          Text(
                                                            'Annual Return: E£${NumberFormat('#,##0${annualReturns['annual'] % 1 == 0 ? '' : '.00'}').format(annualReturns['annual'])}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                          ),
                                                        if (atMaturityReturns !=
                                                            null)
                                                          Text(
                                                            'At Maturity Return: E£${NumberFormat('#,##0${atMaturityReturns['atMaturity'] % 1 == 0 ? '' : '.00'}').format(atMaturityReturns['atMaturity'])}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                          ),
                                                      ],
                                                    ],
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      certificate['description'],
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(height: buttonTopMargin),
                                        ElevatedButton(
                                          onPressed: () {
                                            _launchURL(
                                              banks.firstWhere(
                                                (bank) =>
                                                    bank['name'] ==
                                                    selectedBankName,
                                              )['investmentLink'],
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'More Details',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
    );
  }
}
