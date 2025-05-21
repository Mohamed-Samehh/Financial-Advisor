import { ComponentFixture, TestBed } from '@angular/core/testing';
import { InvestComponent } from './invest.component';
import { ApiService } from '../api.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { of, throwError } from 'rxjs';
import { ElementRef } from '@angular/core';
import Chart from 'chart.js/auto';
import { marked } from 'marked';

// Mock Chart.js
jest.mock('chart.js/auto', () => {
  return {
    Chart: jest.fn().mockImplementation(() => ({
      destroy: jest.fn(),
    })),
  };
});

// Mock marked.js
jest.mock('marked', () => ({
  parse: jest.fn().mockImplementation((text) => `<p>${text}</p>`)
}));

describe('InvestComponent', () => {
  let component: InvestComponent;
  let fixture: ComponentFixture<InvestComponent>;
  let apiServiceMock: jest.Mocked<ApiService>;

  const mockGoalResponse = {
    goal: {
      id: '1',
      name: 'Invest in stocks',
      target_amount: 5000
    }
  };

  const mockEgyptStocks = [
    {
      Code: 'COMI.CA',
      Name: 'Commercial International Bank Egypt S.A.E',
      Exchange: 'EGX',
      Currency: 'EGP',
      Country: 'Egypt',
      Type: 'Common Stock'
    },
    {
      Code: 'HRHO.CA',
      Name: 'EFG Hermes Holding S.A.E',
      Exchange: 'EGX',
      Currency: 'EGP',
      Country: 'Egypt',
      Type: 'Common Stock'
    }
  ];

  const mockStockDetails = [
    {
      date: '2025-05-01',
      open: 42.50,
      high: 43.10,
      low: 42.20,
      close: 43.00,
      volume: 500000
    },
    {
      date: '2025-05-02',
      open: 43.00,
      high: 43.80,
      low: 42.90,
      close: 43.50,
      volume: 600000
    }
  ];

  const mockChatResponse = {
    message: 'This is an analysis of your investment.'
  };

  beforeEach(async () => {
    // Create mock for ApiService
    const apiMock = {
      getGoal: jest.fn(),
      getEgyptStocks: jest.fn(),
      getStockDetails: jest.fn(),
      sendChatMessage: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        FormsModule,
        InvestComponent
      ],
      providers: [
        { provide: ApiService, useValue: apiMock }
      ]
    }).compileComponents();

    apiServiceMock = TestBed.inject(ApiService) as jest.Mocked<ApiService>;
  });

  beforeEach(() => {
    // Set up the default return values
    apiServiceMock.getGoal.mockReturnValue(of(mockGoalResponse));
    apiServiceMock.getEgyptStocks.mockReturnValue(of(mockEgyptStocks));
    apiServiceMock.getStockDetails.mockReturnValue(of(mockStockDetails));
    apiServiceMock.sendChatMessage.mockReturnValue(of(mockChatResponse));

    fixture = TestBed.createComponent(InvestComponent);
    component = fixture.componentInstance;
    
    // Mock the stockChart ElementRef
    component.stockChart = { nativeElement: document.createElement('canvas') } as ElementRef;
    
    fixture.detectChanges();
  });

  afterEach(() => {
    if (component.chartInstance) {
      component.chartInstance.destroy();
    }
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load goal on initialization', () => {
    expect(apiServiceMock.getGoal).toHaveBeenCalled();
    expect(component.goal.id).toBe('1');
    expect(component.goal.name).toBe('Invest in stocks');
    expect(component.isLoading).toBe(false);
    expect(component.showInvestmentModeMessage).toBe(false); // Goal name contains "invest"
  });

  it('should show investment mode message when goal name doesn\'t include "invest"', () => {
    apiServiceMock.getGoal.mockReturnValue(of({
      goal: {
        id: '2',
        name: 'Vacation',
        target_amount: 3000
      }
    }));
    
    component.ngOnInit();
    
    expect(component.showInvestmentModeMessage).toBe(true);
  });

  it('should load Egypt stocks when investment mode is active', () => {
    expect(apiServiceMock.getEgyptStocks).toHaveBeenCalled();
    expect(component.egyptStocks.length).toBe(2);
    expect(component.filteredStocks.length).toBe(2);
    expect(component.isLoadingStocks).toBe(false);
  });

  it('should filter stocks based on search query', () => {
    component.searchQuery = 'commercial';
    component.searchStocks();
    
    expect(component.filteredStocks.length).toBe(1);
    expect(component.filteredStocks[0].name).toContain('Commercial');
    
    // Reset search
    component.searchQuery = '';
    component.searchStocks();
    expect(component.filteredStocks.length).toBe(2);
  });

  it('should load stock details when viewing a stock', () => {
    const stock = {
      code: 'COMI.CA',
      name: 'Commercial International Bank Egypt S.A.E',
      exchange: 'EGX'
    };
    
    component.viewStockDetails(stock);
    
    expect(apiServiceMock.getStockDetails).toHaveBeenCalledWith('COMI.CA');
    expect(component.selectedStock).toBeTruthy();
    if (component.selectedStock) {
      expect(component.selectedStock.historicalData).toEqual(mockStockDetails);
    }
    expect(component.isLoadingStocks).toBe(false);
  });

  it('should render chart when stock has historical data', () => {
    const renderChartSpy = jest.spyOn(component, 'renderChart');
    
    component.selectedStock = {
      code: 'COMI.CA',
      name: 'Commercial International Bank Egypt S.A.E',
      exchange: 'EGX',
      historicalData: mockStockDetails
    };
    
    component.ngAfterViewChecked();
    
    expect(renderChartSpy).toHaveBeenCalled();
    expect(Chart).toHaveBeenCalled();
  });

  it('should switch between certificates and stocks tabs', () => {
    // Start with certificates tab
    expect(component.activeTab).toBe('certificates');
    
    // Switch to stocks tab
    component.switchTab('stocks');
    expect(component.activeTab).toBe('stocks');
    
    // Switch back to certificates tab
    component.switchTab('certificates');
    expect(component.activeTab).toBe('certificates');
    expect(component.selectedBank).not.toBeNull();
  });

  it('should select a bank', () => {
    const bank = component.banks[1]; // Select the second bank
    
    component.selectedBank = bank;
    component.onBankSelect();
    
    expect(component.selectedBank).toBe(bank);
  });

  it('should toggle certificate selection', () => {
    const bank = component.banks[0];
    const certificate = bank.certificates[0];
    
    // Select certificate
    component.toggleCertificateSelection(certificate, bank);
    expect(component.selectedCertificates.length).toBe(1);
    expect(component.selectedCertificates[0].certificate).toBe(certificate);
    expect(component.selectedCertificates[0].bank).toBe(bank);
    
    // Check if certificate is selected
    expect(component.isCertificateSelected(certificate, bank)).toBe(true);
    
    // Deselect certificate
    component.toggleCertificateSelection(certificate, bank);
    expect(component.selectedCertificates.length).toBe(0);
    expect(component.isCertificateSelected(certificate, bank)).toBe(false);
  });

  it('should open and close compare modal', () => {
    // Setup two certificates for comparison
    const bank1 = component.banks[0];
    const cert1 = bank1.certificates[0];
    const bank2 = component.banks[1];
    const cert2 = bank2.certificates[0];
    
    component.toggleCertificateSelection(cert1, bank1);
    component.toggleCertificateSelection(cert2, bank2);
    
    // Open compare modal
    component.openCompareModal();
    expect(component.showCompareModal).toBe(true);
    
    // Close compare modal
    component.closeCompareModal();
    expect(component.showCompareModal).toBe(false);
  });

  it('should calculate winning values for comparison', () => {
    // Setup two certificates with different attributes
    const bank1 = component.banks[0];
    const cert1 = bank1.certificates[0]; // Higher interest rate
    const bank2 = component.banks[1];
    const cert2 = bank2.certificates[0]; // Lower min investment
    
    component.toggleCertificateSelection(cert1, bank1);
    component.toggleCertificateSelection(cert2, bank2);
    
    // Calculate winning values
    component.calculateWinningValues();
    
    // Check if winning values are calculated
    expect(component.winningValues).toBeDefined();
    expect(Object.keys(component.winningValues).length).toBeGreaterThan(0);
  });

  it('should remove certificate from comparison', () => {
    // Setup two certificates for comparison
    const bank1 = component.banks[0];
    const cert1 = bank1.certificates[0];
    const bank2 = component.banks[1];
    const cert2 = bank2.certificates[0];
    
    component.toggleCertificateSelection(cert1, bank1);
    component.toggleCertificateSelection(cert2, bank2);
    
    // Open compare modal
    component.openCompareModal();
    
    // Remove one certificate
    component.removeCertificateFromComparison({ certificate: cert1, bank: bank1 });
    expect(component.selectedCertificates.length).toBe(1);
    
    // Remove the last certificate should close the modal
    component.removeCertificateFromComparison({ certificate: cert2, bank: bank2 });
    expect(component.selectedCertificates.length).toBe(0);
    expect(component.showCompareModal).toBe(false);
  });

  it('should open and process chatbot for certificate', () => {
    const bank = component.banks[0];
    const certificate = bank.certificates[0];
    
    // Open chatbot for certificate analysis
    component.openChatbot(certificate, 'certificate');
    
    expect(component.showChatModal).toBe(true);
    expect(component.chatResponses.length).toBeGreaterThan(0); // Initial message added
    expect(apiServiceMock.sendChatMessage).toHaveBeenCalled();
  });

  it('should open and process chatbot for stock', () => {
    const stock = {
      code: 'COMI.CA',
      name: 'Commercial International Bank Egypt S.A.E',
      exchange: 'EGX',
      historicalData: mockStockDetails
    };
    
    // Open chatbot for stock analysis
    component.openChatbot(stock, 'stock');
    
    expect(component.showChatModal).toBe(true);
    expect(component.chatResponses.length).toBeGreaterThan(0); // Initial message added
    expect(apiServiceMock.sendChatMessage).toHaveBeenCalled();
  });

  it('should handle response from chatbot API', () => {
    // Initial chatbot state
    component.showChatModal = true;
    component.chatResponses = [];
    component.isChatLoading = true;
    
    // Simulate response from API
    component.sendInitialInvestmentInfo(component.banks[0].certificates[0], component.banks[0], 'certificate');
    
    expect(apiServiceMock.sendChatMessage).toHaveBeenCalled();
    expect(component.isChatLoading).toBe(false);
    expect(component.chatResponses.length).toBe(2); // Initial message + API response
    expect(marked.parse).toHaveBeenCalled();
  });

  it('should handle error from chatbot API', () => {
    // Make API return an error
    apiServiceMock.sendChatMessage.mockReturnValue(throwError(() => new Error('API error')));
    
    // Initial chatbot state
    component.showChatModal = true;
    component.chatResponses = [];
    component.isChatLoading = true;
    
    // Simulate response from API
    component.sendInitialInvestmentInfo(component.banks[0].certificates[0], component.banks[0], 'certificate');
    
    expect(apiServiceMock.sendChatMessage).toHaveBeenCalled();
    expect(component.isChatLoading).toBe(false);
    expect(component.chatResponses.length).toBe(2); // Initial message + error message
    expect(component.chatResponses[1].message).toContain("I'm having trouble");
  });

  it('should calculate interest returns correctly', () => {
    // Test with single interest rate
    const singleRateResult = component.calculateReturns(10000, '15%', 3);
    expect(singleRateResult.monthly).toBeCloseTo(125, 0);
    expect(singleRateResult.annual).toBeCloseTo(1500, 0);
    expect(singleRateResult.isChangingRate).toBe(false);
    
    // Test with variable interest rates
    const variableRateResult = component.calculateReturns(10000, '20% (Y1), 15% (Y2), 10% (Y3)', 3);
    expect(variableRateResult.monthly).toBeCloseTo(125, 0); // Average 15%
    expect(variableRateResult.annual).toBeCloseTo(1500, 0);
    expect(variableRateResult.isChangingRate).toBe(true);
  });

  it('should handle errors when loading goal', () => {
    apiServiceMock.getGoal.mockReturnValue(throwError(() => new Error('Error loading goal')));
    
    component.loadGoal();
    
    expect(component.isLoading).toBe(false);
    expect(component.showInvestmentModeMessage).toBe(true);
  });

  it('should handle errors when loading Egypt stocks', () => {
    apiServiceMock.getEgyptStocks.mockReturnValue(throwError(() => new Error('Error loading stocks')));
    
    component.loadEgyptStocks();
    
    expect(component.isLoadingStocks).toBe(false);
    expect(component.stocksError).toBeTruthy();
  });

  it('should handle errors when loading stock details', () => {
    apiServiceMock.getStockDetails.mockReturnValue(throwError(() => new Error('Error loading stock details')));
    
    const stock = {
      code: 'COMI.CA',
      name: 'Commercial International Bank Egypt S.A.E',
      exchange: 'EGX'
    };
    
    component.viewStockDetails(stock);
    
    expect(component.isLoadingStocks).toBe(false);
    expect(component.stocksError).toBeTruthy();
  });

  it('should round to nearest multiple correctly', () => {
    expect(component.roundToNearestMultiple(1750, 1000)).toBe(1000);
    expect(component.roundToNearestMultiple(2500, 1000)).toBe(2000);
    expect(component.roundToNearestMultiple(750, 500)).toBe(500);
    expect(component.roundToNearestMultiple(1200, 500)).toBe(1000);
  });

  it('should extract interest rates correctly', () => {
    expect(component.extractInterestRates('15%')).toEqual([15]);
    expect(component.extractInterestRates('20% (Y1), 15% (Y2), 10% (Y3)')).toEqual([20, 15, 10]);
    expect(component.extractInterestRates('No rates')).toEqual([]);
  });

  it('should calculate average rate correctly', () => {
    expect(component.calculateAverageRate('15%')).toBe(15);
    expect(component.calculateAverageRate('20% (Y1), 15% (Y2), 10% (Y3)')).toBe(15);
    expect(component.calculateAverageRate('No rates')).toBe(0);
  });

  it('should check if all certificates have dashes for a property', () => {
    // Setup certificates where none have dailyInterestRate
    const bank1 = component.banks[0];
    const cert1 = { ...bank1.certificates[0], dailyInterestRate: undefined };
    const bank2 = component.banks[1];
    const cert2 = { ...bank2.certificates[0], dailyInterestRate: undefined };
    
    component.selectedCertificates = [
      { certificate: cert1, bank: bank1 },
      { certificate: cert2, bank: bank2 }
    ];
    
    expect(component.isAllDashes('dailyInterestRate')).toBe(true);
    expect(component.isAllDashes('monthlyInterestRate')).toBe(false);
  });

  it('should identify winning values correctly', () => {
    // Setup winning values
    component.winningValues = {
      duration: 3,
      minInvestment: 1000,
      monthlyInterest: 20
    };
    
    expect(component.isWinningValue(3, 'duration')).toBe(true);
    expect(component.isWinningValue(5, 'duration')).toBe(false);
    expect(component.isWinningValue(1000, 'minInvestment')).toBe(true);
    expect(component.isWinningValue(2000, 'minInvestment')).toBe(false);
    expect(component.isWinningValue(20, 'monthlyInterest')).toBe(true);
    expect(component.isWinningValue('20%', 'monthlyInterest')).toBe(true); // String with %
    expect(component.isWinningValue(15, 'monthlyInterest')).toBe(false);
  });
});
