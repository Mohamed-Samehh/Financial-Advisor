import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService } from '../api.service';

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

@Component({
  selector: 'app-invest',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './invest.component.html',
  styleUrl: './invest.component.css'
})
export class InvestComponent implements OnInit {
  // Pics from Wikimedia Commons (https://commons.wikimedia.org/)
  banks: Bank[] = [
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

  constructor(private apiService: ApiService) { }

  ngOnInit(): void {
    this.loadGoal();
  }

  loadGoal() {
    this.apiService.getGoal().subscribe(
      (res) => {
        this.goal = res.goal ? { id: res.goal.id, name: res.goal.name, target_amount: res.goal.target_amount } : { id: null, name: '', target_amount: null };
        this.isLoading = false;
        this.showInvestmentModeMessage = !this.goal.name.toLowerCase().includes('invest');
      },
      (err) => {
        console.error('Failed to load goal', err);
        this.isLoading = false;
      }
    );
  }

  // Calculate interest returns based on the average interest rate
  calculateReturns(targetAmount: number, interestRate: string, duration: number): {
    daily: number;
    monthly: number;
    quarterly: number;
    semiAnnual: number;
    annual: number;
    atMaturity: number;
    isChangingRate: boolean;
  } {
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
}
