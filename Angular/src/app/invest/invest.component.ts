import { Component, OnInit, ViewChild, ElementRef, AfterViewChecked, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../api.service';
import Chart from 'chart.js/auto';
import { marked } from 'marked';

interface Bank {
  name: string;
  description: string;
  certificates: Certificate[];
  image: string;
  investmentLink: string;
}

interface Certificate {
  type: string;
  duration: number;
  minInvestment: number;
  multiples: number;
  dailyInterestRate?: string;
  monthlyInterestRate?: string;
  quarterlyInterestRate?: string;
  semiAnnuallyInterestRate?: string;
  annuallyInterestRate?: string;
  atMaturityInterestRate?: string;
  description: string;
}

interface Stock {
  code: string;
  name: string;
  exchange: string;
  currency?: string;
  country?: string;
  type?: string;
  isin?: string;
  historicalData?: any[];
}

@Component({
  selector: 'app-invest',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './invest.component.html',
  styleUrl: './invest.component.css'
})
export class InvestComponent implements OnInit, AfterViewChecked, OnDestroy {
  // Pics from Wikimedia Commons (https://commons.wikimedia.org/)
  banks: Bank[] = [
    {
      name: 'Banque Misr',
      description: 'A major Egyptian bank offering a wide range of investment and savings products.',
      image: './Banks/Banque Misr.png',
      investmentLink: 'https://www.banquemisr.com/-/media/Interest-rates/Interest-rates-EN.pdf',
      certificates: [
        {
          type: 'Talaat Harb Certificate',
          monthlyInterestRate: '23.5%',
          atMaturityInterestRate: '27%',
          duration: 1,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A 1-year certificate offering a high fixed interest rate, with options for monthly payments or lump sum at maturity.'
        },
        {
          type: 'Certificates of Deposit (5 years)',
          monthlyInterestRate: '12.25%',
          annuallyInterestRate: '12.5%',
          duration: 5,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A 5-year certificate offering fixed interest rates with options for monthly or annual payouts.'
        },
        {
          type: 'Certificates of Deposit (7 years)',
          monthlyInterestRate: '12.75%',
          duration: 7,
          minInvestment: 750,
          multiples: 750,
          description: 'A 7-year certificate providing a fixed monthly interest rate.'
        },
        {
          type: 'Al Qimma Certificate',
          monthlyInterestRate: '21.5%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A 3-year certificate providing a fixed monthly interest rate.'
        },
        {
          type: 'Aman Al Masreyeen Certificate of Deposit',
          atMaturityInterestRate: '13%',
          duration: 3,
          minInvestment: 500,
          multiples: 500,
          description: 'A 3-year nominal certificate offering life insurance and prize draws, with interest paid at maturity.'
        },
        {
          type: 'Ibn Misr Al-Tholatheya Descending Certificate',
          monthlyInterestRate: '26% (1st year), 22.5% (2nd year), 19% (3rd year)',
          quarterlyInterestRate: '27% (1st year), 23% (2nd year), 19% (3rd year)',
          annuallyInterestRate: '30% (1st year), 25% (2nd year), 20% (3rd year)',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A 3-year certificate with a descending fixed interest rate, offering multiple payout options.'
        }
      ]
    },
    {
      name: 'National Bank of Egypt (NBE)',
      description: 'One of the largest banks in Egypt, offering a variety of fixed deposit and savings products.',
      image: './Banks/NBE.png',
      investmentLink: 'https://www.nbe.com.eg/NBE/E/#/EN/ProductCategory?inParams=%7B%22CategoryID%22%3A%22LocalCertificatesID%22%7D',
      certificates: [
        {
          type: 'Platinum Certificate With Monthly Step Down Interest',
          monthlyInterestRate: '26% (1st year), 22% (2nd year), 18% (3rd year)',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A declining interest certificate with a higher rate in the first year.'
        },
        {
          type: 'Platinum Certificate With Annual Step Down Interest',
          annuallyInterestRate: '30% (1st year), 25% (2nd year), 20% (3rd year)',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'Provides annual step-down interest rates for long-term investment planning.'
        },
        {
          type: 'Platinum Certificate 3 Years',
          monthlyInterestRate: '21.5%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'Offers stable monthly payouts for medium-term investors.'
        },
        {
          type: 'Platinum Variable Interest',
          quarterlyInterestRate: '27.5%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A variable interest certificate with quarterly payouts.'
        },
        {
          type: 'Five Years CD',
          monthlyInterestRate: '14.25%',
          duration: 5,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A long-term investment option with consistent monthly returns.'
        },
        {
          type: 'Egyptian Certificate Aman',
          atMaturityInterestRate: '13%',
          duration: 3,
          minInvestment: 500,
          multiples: 500,
          description: 'A low-minimum investment certificate with a fixed interest rate and a cap on maximum investment.'
        },
        {
          type: 'Platinum Annual Certificate',
          dailyInterestRate: '23%',
          monthlyInterestRate: '23.5%',
          annuallyInterestRate: '27%',
          duration: 1,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A high-yield certificate with options for monthly, daily, or annual interest payouts.'
        }
      ]
    },
    {
      name: 'Commercial International Bank (CIB)',
      description: 'CIB offers competitive interest rates for various types of certificates with flexible terms.',
      image: './Banks/CIB.png',
      investmentLink: 'https://www.cibeg.com/en/personal/accounts-and-deposits/deposits/certificate',
      certificates: [
        {
          type: '3 Years Floating "2024"',
          monthlyInterestRate: '24.75%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'Offers a variable interest rate linked to the Central Bank of Egypt\'s rates, suitable for those anticipating rate increases.'
        },
        {
          type: '3 Years Fixed Prime CD',
          monthlyInterestRate: '18%',
          duration: 3,
          minInvestment: 100000,
          multiples: 1000,
          description: 'Designed for investors seeking stable returns with a lower entry point.'
        },
        {
          type: '3 Years Fixed Plus CD',
          monthlyInterestRate: '19%',
          duration: 3,
          minInvestment: 500000,
          multiples: 1000,
          description: 'Ideal for investors desiring competitive returns with a moderate initial investment.'
        },
        {
          type: '3 Years Fixed Premium CD',
          monthlyInterestRate: '20%',
          duration: 3,
          minInvestment: 1000000,
          multiples: 1000,
          description: 'Suitable for investors seeking high returns with a substantial initial investment.'
        }
      ]
    },
    {
      name: 'QNB Alahli',
      description: 'Part of the Qatar National Bank Group, providing a range of banking services in Egypt.',
      image: './Banks/QNB.png',
      investmentLink: 'https://www.qnbalahli.com/sites/qnb/qnbegypt/page/en/enfixedcds.html',
      certificates: [
        {
          type: 'Retail Fixed CD 3 years',
          monthlyInterestRate: '20%',
          quarterlyInterestRate: '20.05%',
          semiAnnuallyInterestRate: '20.10%',
          annuallyInterestRate: '20.15%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'Suitable for investors seeking stable returns with a modest initial investment.'
        },
        {
          type: 'First CD',
          monthlyInterestRate: '21%',
          quarterlyInterestRate: '21.05%',
          annuallyInterestRate: '21.15% ',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'Ideal for investors desiring higher returns with a low entry point.'
        },
        {
          type: 'Exclusive CD',
          monthlyInterestRate: '21.50%',
          duration: 3,
          minInvestment: 1000000,
          multiples: 1000,
          description: 'Designed for investors seeking premium returns with a substantial initial investment.'
        },
        {
          type: 'First Plus CD',
          monthlyInterestRate: '22.50%',
          duration: 3,
          minInvestment: 5000000,
          multiples: 1000,
          description: 'Tailored for investors aiming for the highest returns with a significant initial investment.'
        }
      ]
    },
    {
      name: 'Al Baraka Bank',
      description: 'Al Baraka Bank offers various local currency certificates with competitive interest rates and flexible terms.',
      image: './Banks/Al Baraka.png',
      investmentLink: 'https://www.albaraka.com.eg/personal/cds/',
      certificates: [
        {
          type: 'Al Baraka Elite',
          monthlyInterestRate: '22%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A premium certificate with high interest and monthly payments.'
        },
        {
          type: 'Golden CD',
          monthlyInterestRate: '14%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A solid option for investors seeking monthly payouts.'
        },
        {
          type: 'Diamond Plus CD',
          monthlyInterestRate: '19%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'A competitive certificate with a strong interest rate.'
        },
        {
          type: 'Diamond CD',
          monthlyInterestRate: '16%',
          annuallyInterestRate: '17.25%',
          duration: 3,
          minInvestment: 100000,
          multiples: 5000,
          description: 'A high-value certificate with flexible interest payment options.'
        }
      ]
    },
    {
      name: 'HSBC Egypt',
      description: 'A subsidiary of HSBC Holdings, providing comprehensive banking services in Egypt.',
      image: './Banks/HSBC.png',
      investmentLink: 'https://www.hsbc.com.eg/accounts/products/savings-certificates/',
      certificates: [
        {
          type: 'Savings Certificate',
          monthlyInterestRate: '20.50%',
          duration: 3,
          minInvestment: 10000,
          multiples: 1000,
          description: 'A high-return savings certificate with monthly interest payments and tax exemption.'
        }
      ]
    },
    {
      name: 'Arab International Bank (AIB)',
      description: 'AIB offers certificates with competitive interest rates and flexible terms for saving and wealth growth.',
      image: './Banks/AIB.png',
      investmentLink: 'https://aib.com.eg/aib-certificates',
      certificates: [
        {
          type: 'Floating rate certificate - 3 years',
          monthlyInterestRate: '22.75%',
          quarterlyInterestRate: '23%',
          duration: 3,
          minInvestment: 1000,
          multiples: 1000,
          description: 'Floating interest rate, adjusted with CBE discount rate changes.'
        }
      ]
    }
  ];

  goal: any = { id: null, name: '', target_amount: null };
  isLoading: boolean = true;
  showInvestmentModeMessage: boolean = true;
  activeTab: 'certificates' | 'stocks' = 'certificates'; // Set certificates as default
  isLoadingStocks: boolean = false;
  egyptStocks: Stock[] = [];
  filteredStocks: Stock[] = [];
  selectedStock: Stock | null = null;
  searchQuery: string = '';
  stocksError: string = '';
  currentDate: Date = new Date();
  showChatModal: boolean = false;
  chatResponses: { message: string, isBot: boolean }[] = [];
  isChatLoading: boolean = false;
  selectedInvestment: any = null;
  
  @ViewChild('stockChart') stockChart!: ElementRef;
  chartInstance: any = null;
  needChartRender: boolean = false;

  constructor(private apiService: ApiService) { }

  ngOnInit(): void {
    this.loadGoal();
  }

  // Convert Markdown to HTML using marked.js
  formatResponse(text: string): string {
    const result = marked.parse(text);
    return typeof result === 'string' ? result : '';
  }

  ngAfterViewChecked() {
    if ((this.selectedStock?.historicalData && 
        this.stockChart?.nativeElement && 
        !this.chartInstance) || this.needChartRender) {
      this.renderChart();
      this.needChartRender = false;
    }
  }

  ngOnDestroy() {
    if (this.chartInstance) {
      this.chartInstance.destroy();
    }
  }

  loadGoal() {
    this.apiService.getGoal().subscribe(
      (res) => {
        this.goal = res.goal ? { id: res.goal.id, name: res.goal.name, target_amount: res.goal.target_amount } : { id: null, name: '', target_amount: null };
        this.isLoading = false;
        this.showInvestmentModeMessage = !this.goal.name.toLowerCase().includes('invest');

        if (!this.showInvestmentModeMessage) {
          this.loadEgyptStocks();
        }
      },
      (err) => {
        console.error('Failed to load goal', err);
        this.isLoading = false;
        this.showInvestmentModeMessage = true;
      }
    );
  }

  // Calculate interest returns based on the average interest rate
  calculateReturns(targetAmount: number, interestRate: string, duration: number): any {
    const rates = this.extractInterestRates(interestRate);
    const isChangingRate = rates.length > 1;

    const averageRate = rates.length > 0
      ? rates.reduce((sum, rate) => sum + rate, 0) / rates.length / 100
      : 0;

    const dailyReturn = targetAmount * (averageRate / 365);
    const monthlyReturn = targetAmount * (averageRate / 12);
    const quarterlyReturn = targetAmount * (averageRate / 4);
    const semiAnnualReturn = targetAmount * (averageRate / 2);
    const annualReturn = targetAmount * averageRate;
    const atMaturityReturn = targetAmount * averageRate * duration;

    return {
      daily: dailyReturn,
      monthly: monthlyReturn,
      quarterly: quarterlyReturn,
      semiAnnual: semiAnnualReturn,
      annual: annualReturn,
      atMaturity: atMaturityReturn,
      isChangingRate
    };
  }

  // Extract interest rates from a strings with percentage values
  extractInterestRates(interestRate: string): number[] {
    const rateMatches = interestRate.match(/\d+(\.\d+)?(?=%)/g);
    return rateMatches ? rateMatches.map(rate => parseFloat(rate)) : [];
  }

  // Round the target amount to the nearest multiple
  roundToNearestMultiple(targetAmount: number, multiple: number): number {
    return Math.floor(targetAmount / multiple) * multiple;
  }

  switchTab(tab: 'certificates' | 'stocks'): void {
    this.activeTab = tab;

    if (tab !== 'stocks' && this.chartInstance) {
      this.chartInstance.destroy();
      this.chartInstance = null;
    }
    
    if (tab === 'stocks') {
      if (this.egyptStocks.length === 0) {
        this.loadEgyptStocks();
      } else if (this.selectedStock && this.selectedStock.historicalData) {
        this.needChartRender = true;
      }
    }
  }

  loadEgyptStocks(): void {
    this.isLoadingStocks = true;
    this.stocksError = '';
    
    this.apiService.getEgyptStocks().subscribe(
      (data) => {
        this.egyptStocks = data
          .map((stock: any) => ({
            code: stock.Code,
            name: stock.Name || stock.Code,
            exchange: stock.Exchange,
            currency: stock.Currency,
            country: stock.Country,
            type: stock.Type,
            isin: stock.Isin
          }));

        this.filteredStocks = [...this.egyptStocks];
        
        this.isLoadingStocks = false;
        
        if (this.egyptStocks.length > 0) {
          this.viewStockDetails(this.egyptStocks[0]);
        }
      },
      (error) => {
        console.error('Error loading Egypt stocks:', error);
        this.isLoadingStocks = false;
        this.stocksError = 'Unable to load Egyptian stocks. Please try again later.';
      }
    );
  }

  viewStockDetails(stock: Stock): void {
    if (this.chartInstance) {
      this.chartInstance.destroy();
      this.chartInstance = null;
    }
    
    this.selectedStock = stock;
    this.isLoadingStocks = true;
    this.stocksError = '';
  
    this.apiService.getStockDetails(stock.code).subscribe(
      (histData) => {
        if (this.selectedStock && this.selectedStock.code === stock.code) {
          this.selectedStock.historicalData = histData;
          if (histData && histData.length > 0) {
            this.currentDate = new Date(histData[histData.length - 1].date);
          }
          this.isLoadingStocks = false;
        }
      },
      (error) => {
        console.error('Error loading stock details:', error);
        this.isLoadingStocks = false;
        this.stocksError = 'Unable to load stock details. Please try again later.';
      }
    );
  }

  renderChart() {
    if (!this.selectedStock?.historicalData || 
        this.selectedStock.historicalData.length === 0 ||
        !this.stockChart?.nativeElement) {
      return;
    }

    if (this.chartInstance) {
      this.chartInstance.destroy();
    }

    const histData = [...this.selectedStock.historicalData];
    const labels = histData.map(item => item.date);
    const closeData = histData.map(item => item.close);
    const openData = histData.map(item => item.open);

    const ctx = this.stockChart.nativeElement.getContext('2d');
    this.chartInstance = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Closing Price',
            data: closeData,
            borderColor: '#0d6efd',
            backgroundColor: 'rgba(13, 110, 253, 0.1)',
            borderWidth: 2,
            tension: 0.1,
            fill: true
          },
          {
            label: 'Opening Price',
            data: openData,
            borderColor: '#6c757d',
            borderWidth: 2,
            borderDash: [5, 5],
            tension: 0.1,
            pointRadius: 0,
            fill: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: false,
            title: {
              display: true,
              text: this.selectedStock.currency || 'EGP'
            },
            ticks: {
              callback: function(value) {
                return value.toLocaleString();
              }
            }
          },
          x: {
            title: {
              display: true,
              text: 'Date'
            }
          }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = parseFloat(context.raw as string);
                return `${context.dataset.label}: ${value.toLocaleString()} ${this.selectedStock?.currency || 'EGP'}`;
              }
            }
          },
          legend: {
            position: 'top',
          }
        }
      }
    });
  }

  searchStocks(): void {
    const query = this.searchQuery.toLowerCase().trim();
    
    if (!query) {
      this.filteredStocks = [...this.egyptStocks];
      return;
    }

    this.filteredStocks = this.egyptStocks.filter(stock => 
      stock.name.toLowerCase().includes(query) || 
      stock.code.toLowerCase().includes(query) ||
      (stock.type && stock.type.toLowerCase().includes(query))
    );
  }
  
  openChatbot(investment: any, investmentType: 'certificate' | 'stock') {
    this.showChatModal = true;
    this.chatResponses = [];
    this.selectedInvestment = investment;
    
    // Send the analysis request immediately
    if (investmentType === 'certificate') {
      const bank = this.banks.find(b => b.certificates.includes(investment)) || null;
      this.sendInitialInvestmentInfo(investment, bank, 'certificate');
    } else if (investmentType === 'stock') {
      this.sendInitialInvestmentInfo(investment, null, 'stock');
    }
  }

  closeChatbot() {
    this.showChatModal = false;
  }

  sendInitialInvestmentInfo(investment: any, bank: Bank | null, type: 'certificate' | 'stock') {
    this.isChatLoading = true;
    
    let initialMessage = '';
    
    if (type === 'certificate') {
      // Add welcome message first
      this.chatResponses.push({ 
        message: `I'm analyzing your <b>${investment.type}</b> certificate from <b>${bank?.name}</b> now. Just a moment while I prepare insights on returns and suitability for your investment.`, 
        isBot: true 
      });
      
      // Format certificate data for the analysis
      initialMessage = `I'm looking at a ${investment.type} from ${bank?.name}. 
      Duration: ${investment.duration} year(s)
      Minimum Investment: ${investment.minInvestment} EGP
      My investment amount: ${this.goal.target_amount ? this.roundToNearestMultiple(this.goal.target_amount, investment.multiples) : 'Not set'} EGP
      ${investment.dailyInterestRate ? 'Daily Interest Rate: ' + investment.dailyInterestRate : ''}
      ${investment.monthlyInterestRate ? 'Monthly Interest Rate: ' + investment.monthlyInterestRate : ''}
      ${investment.quarterlyInterestRate ? 'Quarterly Interest Rate: ' + investment.quarterlyInterestRate : ''}
      ${investment.semiAnnuallyInterestRate ? 'Semi-Annual Interest Rate: ' + investment.semiAnnuallyInterestRate : ''}
      ${investment.annuallyInterestRate ? 'Annual Interest Rate: ' + investment.annuallyInterestRate : ''}
      ${investment.atMaturityInterestRate ? 'At Maturity Interest Rate: ' + investment.atMaturityInterestRate : ''}
      Can you tell me if this is a good investment? What are the pros and cons? Which interest rate should I go with? Make sure to use my spending data in your analysis.`;
    } else if (type === 'stock') {
      // Add welcome message first
      this.chatResponses.push({ 
        message: `I'm analyzing <b>${investment.name}</b> (<b>${investment.code}</b>) stock now. Just a moment while I prepare insights on performance and suitability for your investment.`, 
        isBot: true 
      });
      
      // Format stock data for the analysis
      initialMessage = `I'm looking at ${investment.name} (${investment.code}) stock.
      Exchange: ${investment.exchange}
      Currency: ${investment.currency || 'EGP'}
      ${investment.historicalData && investment.historicalData.length > 0 ? 
        `Current Price: ${investment.historicalData[investment.historicalData.length-1].close}` : ''}
      My investment amount: ${this.goal.target_amount ? this.goal.target_amount : 'Not set'} EGP
      ${investment.historicalData && this.goal.target_amount ? 
        `Estimated Shares I can buy: ${Math.floor(this.goal.target_amount / (investment.historicalData[investment.historicalData.length-1]?.close || 1))}` : ''}
      ${investment.historicalData && investment.historicalData.length > 0 ? 
        `\nHistorical Prices:\n${investment.historicalData.slice().reverse().slice(0, 10).map((data: any) => 
          `${data.date}: Open=${data.open}, Close=${data.close}, High=${data.high}, Low=${data.low}`
        ).join('\n')}` : ''}
      Can you tell me if this is a good investment? What are the pros and cons? Make sure to use my spending data in your analysis.`;
    }
    
    // Send message to API but don't display it in the chat
    this.apiService.sendChatMessage(initialMessage).subscribe(
      (response) => {
        this.isChatLoading = false;
        if (response && response.message) {
          this.chatResponses.push({ message: this.formatResponse(response.message), isBot: true });
        } else {
          this.chatResponses.push({ 
            message: "I couldn't generate a specific analysis for this investment. Please consider traditional financial metrics like potential return, risk level, and your investment timeline.", 
            isBot: true 
          });
        }
      },
      (error) => {
        console.error('Error from analysis API:', error);
        this.isChatLoading = false;
        this.chatResponses.push({ 
          message: "Sorry, I'm having trouble analyzing this investment right now. Please try again later or consult with a financial advisor.", 
          isBot: true 
        });
      }
    );
  }
  
  get Math() {
    return Math;
  }
}
