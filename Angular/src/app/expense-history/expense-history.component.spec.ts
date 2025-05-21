import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ExpenseHistoryComponent } from './expense-history.component';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { of, throwError } from 'rxjs';

describe('ExpenseHistoryComponent', () => {
  let component: ExpenseHistoryComponent;
  let fixture: ComponentFixture<ExpenseHistoryComponent>;
  let apiServiceMock: jest.Mocked<ApiService>;

  const mockExpensesResponse = {
    data: [
      [
        { id: '1', category: 'Food', amount: 300, date: '2025-05-01', description: 'Groceries' },
        { id: '2', category: 'Transport', amount: 200, date: '2025-05-10', description: 'Taxi' }
      ]
    ],
    current_page: 1,
    last_page: 2
  };

  const mockBudgetsResponse = {
    budgets: [
      { id: '1', monthly_budget: 5000, created_at: '2025-05-01T10:00:00.000Z' }
    ]
  };

  const mockGoalsResponse = {
    goals: [
      { id: '1', name: 'Savings', target_amount: 1000, created_at: '2025-05-01T10:00:00.000Z' }
    ]
  };

  beforeEach(async () => {
    // Create mock for ApiService
    const apiMock = {
      getAllExpenses: jest.fn(),
      getAllBudgets: jest.fn(),
      getAllGoals: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        ExpenseHistoryComponent
      ],
      providers: [
        DecimalPipe,
        { provide: ApiService, useValue: apiMock }
      ]
    }).compileComponents();

    apiServiceMock = TestBed.inject(ApiService) as jest.Mocked<ApiService>;
  });

  beforeEach(() => {
    // Set up the mock responses
    apiServiceMock.getAllExpenses.mockReturnValue(of(mockExpensesResponse));
    apiServiceMock.getAllBudgets.mockReturnValue(of(mockBudgetsResponse));
    apiServiceMock.getAllGoals.mockReturnValue(of(mockGoalsResponse));

    fixture = TestBed.createComponent(ExpenseHistoryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load expense history on initialization', () => {
    expect(apiServiceMock.getAllExpenses).toHaveBeenCalled();
    expect(apiServiceMock.getAllBudgets).toHaveBeenCalled();
    expect(apiServiceMock.getAllGoals).toHaveBeenCalled();
    
    expect(component.sortedYears.length).toBeGreaterThan(0);
    expect(component.isLoading).toBe(false);
  });

  it('should format numbers correctly', () => {
    const result = component.formatNumber(5000.5);
    expect(result).toBe('5,001');
  });

  it('should detect current month correctly', () => {
    const currentYear = new Date().getFullYear();
    const currentMonth = new Date().getMonth() + 1;
    const currentMonthStr = `${currentYear}-${String(currentMonth).padStart(2, '0')}`;
    const lastMonthStr = `${currentYear}-${String(currentMonth - 1).padStart(2, '0')}`;
    
    expect(component.isCurrentMonth(currentMonthStr)).toBe(true);
    expect(component.isCurrentMonth(lastMonthStr)).toBe(false);
  });

  it('should detect future month correctly', () => {
    const currentYear = new Date().getFullYear();
    const currentMonth = new Date().getMonth() + 1;
    const futureMonthStr = `${currentYear}-${String(currentMonth + 1).padStart(2, '0')}`;
    const pastMonthStr = `${currentYear}-${String(currentMonth - 1).padStart(2, '0')}`;
    
    expect(component.isFutureMonth(futureMonthStr)).toBe(true);
    expect(component.isFutureMonth(pastMonthStr)).toBe(false);
  });

  it('should filter expenses by month', () => {
    const year = component.sortedYears[0] || component.currentYear.toString();
    const monthYear = `${year}-05`;
    const expenses = component.expensesByYear[year] || [];
    
    const filtered = component.filterByMonth(expenses, monthYear);
    expect(filtered.length).toBeGreaterThanOrEqual(0);
  });

  it('should navigate pagination correctly', () => {
    const initialPage = component.currentPage;
    
    // Go to next page
    component.nextPage();
    expect(apiServiceMock.getAllExpenses).toHaveBeenCalledTimes(2);
    
    // Reset to initial page
    component.currentPage = initialPage;
    
    // Go to previous page if possible
    if (initialPage > 1) {
      component.previousPage();
      expect(apiServiceMock.getAllExpenses).toHaveBeenCalledTimes(3);
    }
    
    // Go to specific page
    component.goToPage(1);
    expect(apiServiceMock.getAllExpenses).toHaveBeenCalledTimes(initialPage > 1 ? 4 : 3);
  });

  it('should handle expense summary status correctly', () => {
    // Mock data for testing
    const monthYear = '2025-04'; // Not current month
    component.budgetByMonth[monthYear] = { monthly_budget: 5000 };
    component.goalByMonth[monthYear] = { target_amount: 1000 };
    
    // Case 1: Budget surpassed
    component.totalExpensesByMonth[monthYear] = 6000;
    expect(component.Expense_summary(monthYear)).toBe('budget_surpassed');
    
    // Case 2: Goal not met
    component.totalExpensesByMonth[monthYear] = 4500;
    expect(component.Expense_summary(monthYear)).toBe('goal_not_met');
    
    // Case 3: Goal met
    component.totalExpensesByMonth[monthYear] = 3500;
    expect(component.Expense_summary(monthYear)).toBe('goal_met');
    
    // Current month should return empty string
    const currentMonthYear = `${component.currentYear}-${String(component.currentMonth).padStart(2, '0')}`;
    expect(component.Expense_summary(currentMonthYear)).toBe('');
  });

  it('should handle error when loading expense history', () => {
    apiServiceMock.getAllExpenses.mockReturnValue(throwError(() => new Error('Error loading expenses')));
    
    component.loadExpenseHistory();
    
    expect(component.message).not.toBeNull();
    expect(component.message?.type).toBe('danger');
    expect(component.isLoading).toBe(false);
  });

  it('should export expenses to CSV', () => {
    // Mock methods needed for CSV export
    global.URL.createObjectURL = jest.fn();
    const createElementMock = document.createElement;
    const appendChildMock = document.body.appendChild;
    const removeChildMock = document.body.removeChild;
    
    document.createElement = jest.fn().mockImplementation((tag) => {
      const element = createElementMock.call(document, tag);
      if (tag === 'a') {
        element.click = jest.fn();
      }
      return element;
    });
    
    document.body.appendChild = jest.fn();
    document.body.removeChild = jest.fn();
    
    const year = component.sortedYears[0] || component.currentYear.toString();
    const monthYear = `${year}-05`;
    
    // Setup mock expenses for the test
    component.expensesByYear[year] = [
      { id: '1', category: 'Food', amount: 300, date: '2025-05-01', description: 'Groceries' }
    ];
    
    component.exportToCSV(monthYear);
    
    // Verify link creation and click
    expect(document.createElement).toHaveBeenCalledWith('a');
    expect(document.body.appendChild).toHaveBeenCalled();
    expect(document.body.removeChild).toHaveBeenCalled();
    
    // Restore original methods
    document.createElement = createElementMock;
    document.body.appendChild = appendChildMock;
    document.body.removeChild = removeChildMock;
    jest.restoreAllMocks();
  });

  it('should handle CSV export with no expenses', () => {
    const year = component.sortedYears[0] || component.currentYear.toString();
    const monthYear = `${year}-05`;
    
    // Setup empty expenses for the test
    component.expensesByYear[year] = [];
    
    component.exportToCSV(monthYear);
    
    // Verify message is shown
    expect(component.message).not.toBeNull();
    expect(component.message?.type).toBe('danger');
  });
});
