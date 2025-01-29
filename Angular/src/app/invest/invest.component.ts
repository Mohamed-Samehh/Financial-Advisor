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
  interestRate: string;
  duration: string;
  minInvestment: number;
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
      name: 'Commercial International Bank (CIB)',
      description: 'CIB offers competitive interest rates for various types of certificates with flexible terms.',
      image: './Banks/CIB.png',
      investmentLink: 'https://www.cibeg.com/en/personal/accounts-and-deposits/deposits/certificate',
      certificates: [
        {
          type: '3-Year Floating "2024" CD',
          interestRate: '24.75% (monthly)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'Offers a variable interest rate linked to the Central Bank of Egypt\'s rates, suitable for those anticipating rate increases.'
        },
        {
          type: '3-Year Fixed Prime CD',
          interestRate: '18% (monthly)',
          duration: '3 years',
          minInvestment: 100000,
          description: 'Designed for investors seeking stable returns with a lower entry point.'
        },
        {
          type: '3-Year Fixed Plus CD',
          interestRate: '19% (monthly)',
          duration: '3 years',
          minInvestment: 500000,
          description: 'Ideal for investors desiring competitive returns with a moderate initial investment.'
        },
        {
          type: '3-Year Fixed Premium CD',
          interestRate: '20% (monthly)',
          duration: '3 years',
          minInvestment: 1000000,
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
          type: 'Retail Fixed CD',
          interestRate: '20% (monthly), 20.05% (quarterly), 20.10% (semi-annually), 20.15% (annually)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'Suitable for investors seeking stable returns with a modest initial investment.'
        },
        {
          type: 'First CD',
          interestRate: '21% (monthly), 21.05% (quarterly), 21.15% (annually)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'Ideal for investors desiring higher returns with a low entry point.'
        },
        {
          type: 'Exclusive CD',
          interestRate: '21.50% (monthly)',
          duration: '3 years',
          minInvestment: 1000000,
          description: 'Designed for investors seeking premium returns with a substantial initial investment.'
        },
        {
          type: 'First Plus CD',
          interestRate: '22.50% (monthly)',
          duration: '3 years',
          minInvestment: 5000000,
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
          interestRate: '22% (monthly)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'A premium certificate with high interest and monthly payments.'
        },
        {
          type: 'Diamond Plus CD',
          interestRate: '19% (monthly)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'A competitive certificate with a strong interest rate.'
        },
        {
          type: 'Diamond CD',
          interestRate: '17.25% (annually), 16% (monthly)',
          duration: '3 years',
          minInvestment: 100000,
          description: 'A high-value certificate with flexible interest payment options.'
        },
        {
          type: 'Golden CD',
          interestRate: '14% (monthly)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'A solid option for investors seeking monthly payouts.'
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
          type: 'Platinum Annual Certificate',
          interestRate: '23.5% monthly, 27% annually (at maturity), 23% daily',
          duration: '1 year',
          minInvestment: 1000,
          description: 'A high-yield certificate with options for monthly, daily, or annual interest payouts.'
        },
        {
          type: 'Platinum Certificate With Monthly Step Down Interest',
          interestRate: '26% (1st year), 22% (2nd year), 18% (3rd year)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'A declining interest certificate with a higher rate in the first year.'
        },
        {
          type: 'Platinum Certificate With Annual Step Down Interest',
          interestRate: '30% (1st year), 25% (2nd year), 20% (3rd year)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'Provides annual step-down interest rates for long-term investment planning.'
        },
        {
          type: 'Platinum Certificate 3 Years',
          interestRate: '21.5% monthly',
          duration: '3 years',
          minInvestment: 1000,
          description: 'Offers stable monthly payouts for medium-term investors.'
        },
        {
          type: 'Platinum Variable Interest',
          interestRate: '27.5% quarterly',
          duration: '3 years',
          minInvestment: 1000,
          description: 'A variable interest certificate with quarterly payouts.'
        },
        {
          type: 'Five Years CD',
          interestRate: '14.25% monthly',
          duration: '5 years',
          minInvestment: 1000,
          description: 'A long-term investment option with consistent monthly returns.'
        },
        {
          type: 'Egyptian Certificate Aman',
          interestRate: '13%',
          duration: '3 years',
          minInvestment: 500,
          description: 'A low-minimum investment certificate with a fixed interest rate and a cap on maximum investment.'
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
          type: 'Talaat Harb Certificate of Deposit',
          interestRate: '23.5% (monthly) or 27% (at maturity)',
          duration: '1 year',
          minInvestment: 1000,
          description: 'A 1-year certificate offering a high fixed interest rate, with options for monthly payments or lump sum at maturity.'
        },
        {
          type: 'Ibn Misr Al-Tholatheya Descending Certificate',
          interestRate: 'First Option (Monthly): 26% (1st year), 22.5% (2nd year), 19% (3rd year) OR Second Option (Quarterly): 27% (1st year), 23% (2nd year), 19% (3rd year) OR Third Option (Annually): 30% (1st year), 25% (2nd year), 20% (3rd year)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'A 3-year certificate with a descending fixed interest rate, offering multiple payout options.'
        },
        {
          type: 'Al Qimma Certificate of Deposit',
          interestRate: '21.5% (monthly)',
          duration: '3 years',
          minInvestment: 1000,
          description: 'A 3-year certificate providing a fixed monthly interest rate.'
        },
        {
          type: 'Certificates of Deposit with Fixed Interest (5 years)',
          interestRate: '12.25% (monthly) or 12.5% (annually)',
          duration: '5 years',
          minInvestment: 1200,
          description: 'A 5-year certificate offering fixed interest rates with options for monthly or annual payouts.'
        },
        {
          type: 'Certificates of Deposit with Fixed Interest (7 years)',
          interestRate: '12.75% (monthly)',
          duration: '7 years',
          minInvestment: 750,
          description: 'A 7-year certificate providing a fixed monthly interest rate.'
        },
        {
          type: 'El Tholatheya Certificate with Monthly Variable Interest',
          interestRate: 'Variable (paid monthly)',
          duration: '3 years',
          minInvestment: 500,
          description: 'A 3-year certificate with a variable monthly interest rate.'
        },
        {
          type: 'Aman El-Masreyeen Certificate of Deposit',
          interestRate: '13% (at maturity)',
          duration: '3 years',
          minInvestment: 500,
          description: 'A 3-year nominal certificate offering life insurance and prize draws, with interest paid at maturity.'
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
          interestRate: '20.50% per annum',
          duration: '3 years',
          minInvestment: 1000,
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
          type: 'Floating Rate Certificate',
          interestRate: '22.75% (monthly), 23% (quarterly)',
          duration: '3 years',
          minInvestment: 1000,
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
}
