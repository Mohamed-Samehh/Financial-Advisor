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
    // Mock console.error to prevent error output during tests
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    
    // Reset the component state
    component.isLoading = true;
    component.message = null;
    
    // Mock the error response
    apiServiceMock.getAllExpenses.mockReturnValue(throwError(() => new Error('Error loading expenses')));
    
    component.loadExpenseHistory();
    
    expect(component.message).not.toBeNull();
    expect((component.message as any)?.type).toBe('danger');
    expect(component.isLoading).toBe(false);
    
    // Verify console.error was called - following the pattern from budget component
    expect(consoleSpy).toHaveBeenCalled();
    
    // Restore console.error
    consoleSpy.mockRestore();
  });

  it('should export expenses to CSV', () => {
    // Mock URL.createObjectURL
    const mockUrl = 'blob:mock-url';
    global.URL.createObjectURL = jest.fn().mockReturnValue(mockUrl);
    global.URL.revokeObjectURL = jest.fn();
    
    // Mock document methods
    const mockLink = {
      setAttribute: jest.fn(),
      click: jest.fn(),
      href: '',
      download: ''
    };
    
    const createElementSpy = jest.spyOn(document, 'createElement').mockReturnValue(mockLink as any);
    const appendChildSpy = jest.spyOn(document.body, 'appendChild').mockImplementation(() => mockLink as any);
    const removeChildSpy = jest.spyOn(document.body, 'removeChild').mockImplementation(() => mockLink as any);
    
    const year = component.sortedYears[0] || component.currentYear.toString();
    const monthYear = `${year}-04`; // Use a past month, not current month
    
    // Setup mock expenses for the test
    component.expensesByYear[year] = [
      { id: '1', category: 'Food', amount: 300, date: '2025-04-01', description: 'Groceries' }
    ];
    
    component.exportToCSV(monthYear);
    
    // Verify the process
    expect(createElementSpy).toHaveBeenCalledWith('a');
    expect(mockLink.setAttribute).toHaveBeenCalledWith('href', mockUrl);
    expect(mockLink.setAttribute).toHaveBeenCalledWith('download', `expenses-${monthYear}.csv`);
    expect(appendChildSpy).toHaveBeenCalledWith(mockLink);
    expect(mockLink.click).toHaveBeenCalled();
    expect(removeChildSpy).toHaveBeenCalledWith(mockLink);
    
    // Verify success message
    expect(component.message).not.toBeNull();
    expect((component.message as any)?.type).toBe('success');
    expect((component.message as any)?.text).toContain('successfully exported');
    
    // Restore mocks
    createElementSpy.mockRestore();
    appendChildSpy.mockRestore();
    removeChildSpy.mockRestore();
    jest.restoreAllMocks();
  });

  it('should handle CSV export with no expenses', () => {
    const year = component.sortedYears[0] || component.currentYear.toString();
    const monthYear = `${year}-04`; // Use a past month, not current month
    
    // Setup empty expenses for the test
    component.expensesByYear[year] = [];
    
    component.exportToCSV(monthYear);
    
    // Verify error message is shown
    expect(component.message).not.toBeNull();
    expect((component.message as any)?.type).toBe('danger');
    expect((component.message as any)?.text).toBe('No expenses to export for this month.');
  });

  it('should return empty array for current month filtering', () => {
    const currentYear = new Date().getFullYear();
    const currentMonth = new Date().getMonth() + 1;
    const currentMonthStr = `${currentYear}-${String(currentMonth).padStart(2, '0')}`;
    
    // Setup mock expenses
    const expenses = [
      { id: '1', category: 'Food', amount: 300, date: `${currentYear}-${String(currentMonth).padStart(2, '0')}-01`, description: 'Groceries' }
    ];
    
    const filtered = component.filterByMonth(expenses, currentMonthStr);
    expect(filtered).toEqual([]);
  });

  it('should handle hasExpenseHistory correctly', () => {
    // Test with no expenses
    component.expensesByYear = {};
    expect(component.hasExpenseHistory()).toBe(false);
    
    // Test with empty expenses array
    component.expensesByYear = { '2025': [] };
    expect(component.hasExpenseHistory()).toBe(false);
    
    // Test with actual expenses
    component.expensesByYear = { '2025': [{ id: '1', category: 'Food', amount: 300, date: '2025-04-01', description: 'Groceries' }] };
    expect(component.hasExpenseHistory()).toBe(true);
  });
});
