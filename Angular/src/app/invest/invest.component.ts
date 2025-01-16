import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';

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
  banks: Bank[] = [
    {
      name: 'QNB Alahli',
      description: 'Part of the Qatar National Bank Group, providing a range of banking services in Egypt.',
      image: './Banks/QNB.png',
      investmentLink: 'https://www.qnbalahli.com/sites/qnb/qnbegypt/page/en/enfixedcds.html',
      certificates: [
        {
          type: 'Fixed Income Certificate',
          interestRate: '11%',
          duration: '2 years',
          minInvestment: 1000,
          description: 'A fixed-income option for steady growth over a moderate duration.'
        },
        {
          type: 'Savings Certificate',
          interestRate: '9.5%',
          duration: '1 year',
          minInvestment: 1500,
          description: 'A low-risk investment option with a stable return.'
        }
      ]
    },
    {
      name: 'Arab African International Bank (AAIB)',
      description: 'A regional bank offering a variety of financial services across the Middle East and North Africa.',
      image: './Banks/AAIB.png',
      investmentLink: 'https://www.aaib.com/individual/personal-banking/deposites/year-bullet-certificate-of-deposits',
      certificates: [
        {
          type: 'Fixed Deposit Certificate',
          interestRate: '10.5%',
          duration: '1 year',
          minInvestment: 1000,
          description: 'A secure fixed deposit certificate with a steady return.'
        },
        {
          type: 'Renewable Certificate',
          interestRate: '11.2%',
          duration: '2 years',
          minInvestment: 3000,
          description: 'A renewable certificate for long-term investors.'
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
          type: 'Fixed Income Certificate',
          interestRate: '9.5%',
          duration: '1 year',
          minInvestment: 1500,
          description: 'A stable and low-risk fixed-income certificate.'
        },
        {
          type: 'Premium Certificate',
          interestRate: '11%',
          duration: '3 years',
          minInvestment: 5000,
          description: 'A premium certificate with higher returns for larger investments.'
        }
      ]
    }
    ,{
      name: 'National Bank of Egypt (NBE)',
      description: 'One of the largest banks in Egypt, offering a variety of fixed deposit and savings products.',
      image: './Banks/NBE.png',
      investmentLink: 'https://www.nbe.com.eg/NBE/E/#/EN/PersonalBanking/CertificatesOfDeposit',
      certificates: [
        {
          type: 'Fixed Deposit Certificate',
          interestRate: '10.5%',
          duration: '1 year',
          minInvestment: 1000,
          description: 'A fixed deposit certificate offering competitive interest rates with guaranteed returns.'
        },
        {
          type: 'Premium Certificate',
          interestRate: '11%',
          duration: '3 years',
          minInvestment: 5000,
          description: 'A premium certificate for high-value investments with higher returns.'
        }
      ]
    },
    {
      name: 'Banque Misr',
      description: 'A major Egyptian bank offering a wide range of investment and savings products.',
      image: './Banks/Banque Misr.png',
      investmentLink: 'https://www.banquemisr.com/en/Home/SMEs/Retail-Banking/Accounts-And-Deposits/Certificates/Details-of-Certificates',
      certificates: [
        {
          type: 'Fixed Income Certificate',
          interestRate: '10.25%',
          duration: '1 year',
          minInvestment: 1000,
          description: 'A stable investment certificate for conservative investors.'
        },
        {
          type: 'Long-term Certificate',
          interestRate: '12%',
          duration: '5 years',
          minInvestment: 2000,
          description: 'A long-term investment option with higher returns.'
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
          type: 'Short-Term Certificate',
          interestRate: '9.75%',
          duration: '6 months',
          minInvestment: 1500,
          description: 'Ideal for investors looking for quick returns.'
        },
        {
          type: 'High Yield Certificate',
          interestRate: '11.5%',
          duration: '2 years',
          minInvestment: 5000,
          description: 'A high-yield certificate with a longer lock-in period.'
        }
      ]
    }
  ];

  constructor() { }

  ngOnInit(): void {
  }
}
