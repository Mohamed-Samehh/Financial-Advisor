import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AnalyzeExpensesComponent } from './analyze-expenses.component';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { of, throwError } from 'rxjs';
import { Chart } from 'chart.js/auto';

// Mock Chart.js
jest.mock('chart.js/auto', () => {
  return {
    Chart: jest.fn().mockImplementation(() => ({
      destroy: jest.fn(),
    })),
  };
});

describe('AnalyzeExpensesComponent', () => {
  let component: AnalyzeExpensesComponent;
  let fixture: ComponentFixture<AnalyzeExpensesComponent>;
  let apiServiceMock: jest.Mocked<ApiService>;

  const mockAnalysisData = {
    monthly_budget: 5000,
    total_spent: 3000,
    remaining_budget: 2000,
    goal: 1000,
    category_limits: [
      { name: 'Goal', limit: 1000 },
      { name: 'Food', limit: 1500 }
    ],
    daily_expenses: { '1': 100, '2': 200 },
    smart_insights: ['Test insight'],
    advice: ['Test advice'],
    category_predictions: {
      'Food': [{ month: 'June', year: '2025', predicted_spending: 1200, accuracy: 0.85 }]
    },
    predictions: [{ month: 'June', year: '2025', predicted_spending: 4500, accuracy: 0.9 }],
    spending_clustering: [{
      spending_group: [
        { category: 'Food', spending_group: 'High' },
        { category: 'Transport', spending_group: 'Low' }
      ]
    }],
    frequency_clustering: [{
      frequency_group: [
        { category: 'Food', frequency_group: 'High' },
        { category: 'Transport', frequency_group: 'Low' }
      ]
    }],
    expenses_clustering: [
      { cluster: 'High', min_expenses: 1000, max_expenses: 2000, count_of_expenses: 5 }
    ],
    association_rules: [
      { antecedents: ['Food'], consequents: ['Transport'], confidence: 0.8 }
    ]
  };

  const mockExpensesData = {
    expenses: [
      { id: '1', category: 'Food', amount: 500, date: '2025-05-01' },
      { id: '2', category: 'Transport', amount: 300, date: '2025-05-02' }
    ]
  };

  beforeEach(async () => {
    // Create mock for ApiService
    const apiMock = {
      analyzeExpenses: jest.fn(),
      getExpenses: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        FormsModule,
        AnalyzeExpensesComponent
      ],
      providers: [
        DecimalPipe,
        { provide: ApiService, useValue: apiMock }
      ]
    }).compileComponents();

    apiServiceMock = TestBed.inject(ApiService) as jest.Mocked<ApiService>;
  });

  beforeEach(() => {
    // Set up the default return values
    apiServiceMock.analyzeExpenses.mockReturnValue(of(mockAnalysisData));
    apiServiceMock.getExpenses.mockReturnValue(of(mockExpensesData));
    
    // Create mock elements for chart rendering
    const mockCanvas = document.createElement('canvas');
    mockCanvas.id = 'expensesChart';
    document.body.appendChild(mockCanvas);
    
    const mockPieCanvas = document.createElement('canvas');
    mockPieCanvas.id = 'categoryChart';
    document.body.appendChild(mockPieCanvas);
    
    fixture = TestBed.createComponent(AnalyzeExpensesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    const expensesChart = document.getElementById('expensesChart');
    const categoryChart = document.getElementById('categoryChart');
    
    if (expensesChart) {
      document.body.removeChild(expensesChart);
    }
    
    if (categoryChart) {
      document.body.removeChild(categoryChart);
    }
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should initialize with data from ApiService', () => {
    expect(apiServiceMock.analyzeExpenses).toHaveBeenCalled();
    expect(apiServiceMock.getExpenses).toHaveBeenCalled();
    expect(component.analysis).toBeDefined();
    expect(component.isLoading).toBe(false);
  });

  it('should format numbers correctly', () => {
    const result = component.formatNumber(5000.5);
    expect(result).toBe('5,001');
  });

  it('should return the correct accuracy for predictions', () => {
    component.selectedPredictionType = 'Total';
    expect(component.getAccuracy()).toBe(90);
    
    component.selectedPredictionType = 'Food';
    expect(component.getAccuracy()).toBe(85);
  });

  it('should return category keys from category predictions', () => {
    const keys = component.getCategoryKeys();
    expect(keys).toEqual(['Food']);
  });

  it('should correctly navigate views with goToPrevView', () => {
    // Start with association rules view
    component.isAssociationRulesView = true;
    component.isExpenseClusteringView = false;
    component.isFrequencyClusteringView = false;
    component.isSpendingClusteringView = false;
    
    // Go to previous view
    component.goToPrevView();
    expect(component.isAssociationRulesView).toBe(false);
    expect(component.isExpenseClusteringView).toBe(true);
    
    // Go to previous view again
    component.goToPrevView();
    expect(component.isExpenseClusteringView).toBe(false);
    expect(component.isFrequencyClusteringView).toBe(true);
    
    // Go to previous view once more
    component.goToPrevView();
    expect(component.isFrequencyClusteringView).toBe(false);
    expect(component.isSpendingClusteringView).toBe(true);
  });

  it('should correctly navigate views with goToNextView', () => {
    // Start with spending clustering view
    component.isSpendingClusteringView = true;
    component.isFrequencyClusteringView = false;
    component.isExpenseClusteringView = false;
    component.isAssociationRulesView = false;
    
    // Go to next view
    component.goToNextView();
    expect(component.isSpendingClusteringView).toBe(false);
    expect(component.isFrequencyClusteringView).toBe(true);
    
    // Go to next view again
    component.goToNextView();
    expect(component.isFrequencyClusteringView).toBe(false);
    expect(component.isExpenseClusteringView).toBe(true);
    
    // Go to next view once more
    component.goToNextView();
    expect(component.isExpenseClusteringView).toBe(false);
    expect(component.isAssociationRulesView).toBe(true);
  });

  it('should create charts', () => {
    expect(Chart).toHaveBeenCalled();
    expect(component.chart).toBeDefined();
    expect(component.categoryChart).toBeDefined();
  });

  it('should handle error when getting expenses', () => {
    apiServiceMock.getExpenses.mockReturnValue(throwError(() => new Error('Failed to load expenses')));
    
    component.ngOnInit();
    expect(component.errorMessage).toBe('Failed to load expenses.');
    expect(component.isLoading).toBe(false);
  });

  it('should populate categoryTotals when creating pie chart', () => {
    const expenses = [
      { category: 'Food', amount: 500 },
      { category: 'Food', amount: 300 },
      { category: 'Transport', amount: 200 }
    ];
    
    component.createPieChart(expenses);
    
    expect(component.categoryTotals).toEqual({
      'Food': 800,
      'Transport': 200
    });
  });

  it('should handle missing data in category predictions', () => {
    // Set up analysis with missing category predictions
    component.analysis = { ...mockAnalysisData, category_predictions: {} };
    
    // Test the method with a non-existent category
    component.selectedPredictionType = 'Clothing';
    expect(component.getAccuracy()).toBe(0);
  });

  it('should handle missing predictions data', () => {
    // Set up analysis with missing predictions
    component.analysis = { ...mockAnalysisData, predictions: undefined };
    
    // Test the method
    component.selectedPredictionType = 'Total';
    expect(component.getAccuracy()).toBe(0);
  });

  it('should get empty array for category keys when no predictions exist', () => {
    // Set up analysis with missing category predictions
    component.analysis = { ...mockAnalysisData, category_predictions: undefined };
    
    const keys = component.getCategoryKeys();
    expect(keys).toEqual([]);
  });

  it('should create chart with empty budget', () => {
    // Create a new canvas for this test
    const newCanvas = document.createElement('canvas');
    newCanvas.id = 'newExpensesChart';
    document.body.appendChild(newCanvas);

    // Set up analysis with empty budget
    component.analysis = { 
      monthly_budget: 0,
      daily_expenses: { '1': 0 }
    };
    
    try {
      component.createChart();
      // If it doesn't throw an error, the test passes
      expect(true).toBe(true);
    } finally {
      // Clean up
      if (document.getElementById('newExpensesChart')) {
        document.body.removeChild(document.getElementById('newExpensesChart')!);
      }
    }
  });
});
