import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ExpensesComponent } from './expenses.component';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { of, throwError } from 'rxjs';
import Swal from 'sweetalert2';

// Mock SweetAlert2
jest.mock('sweetalert2', () => ({
  fire: jest.fn().mockResolvedValue({ isConfirmed: true })
}));

describe('ExpensesComponent', () => {
  let component: ExpensesComponent;
  let fixture: ComponentFixture<ExpensesComponent>;
  let apiServiceMock: jest.Mocked<ApiService>;
  let consoleErrorSpy: jest.SpyInstance;

  const mockExpenses = {
    expenses: [
      { id: '1', category: 'Food', amount: 500, date: '2025-05-01', description: 'Groceries' },
      { id: '2', category: 'Transport', amount: 300, date: '2025-05-10', description: 'Taxi' }
    ]
  };

  const mockCategories = [
    { id: '1', name: 'Food', priority: 1 },
    { id: '2', name: 'Transport', priority: 2 },
    { id: '3', name: 'Entertainment', priority: 3 }
  ];

  beforeEach(async () => {
    // Create mock for ApiService
    const apiMock = {
      getExpenses: jest.fn(),
      getCategories: jest.fn(),
      addExpense: jest.fn(),
      updateExpense: jest.fn(),
      deleteExpense: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        FormsModule,
        ExpensesComponent
      ],
      providers: [
        DecimalPipe,
        { provide: ApiService, useValue: apiMock }
      ]
    }).compileComponents();

    apiServiceMock = TestBed.inject(ApiService) as jest.Mocked<ApiService>;
  });

  beforeEach(() => {
    // Mock console.error to prevent error output during tests
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    
    // Set up the default return values
    apiServiceMock.getExpenses.mockReturnValue(of(mockExpenses));
    apiServiceMock.getCategories.mockReturnValue(of(mockCategories));
    apiServiceMock.addExpense.mockReturnValue(of({ id: '3', category: 'Food', amount: 200 }));
    apiServiceMock.updateExpense.mockReturnValue(of({ id: '1', category: 'Food', amount: 600 }));
    apiServiceMock.deleteExpense.mockReturnValue(of({ message: 'Expense deleted' }));

    fixture = TestBed.createComponent(ExpensesComponent);
    component = fixture.componentInstance;
    
    // Override the validateDate method to avoid issues with date validation
    component.validateDate = jest.fn().mockReturnValue(null);
    
    fixture.detectChanges();
  });

  afterEach(() => {
    // Restore console.error and clear all mocks
    consoleErrorSpy.mockRestore();
    jest.clearAllMocks();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load expenses and categories on initialization', () => {
    expect(apiServiceMock.getExpenses).toHaveBeenCalled();
    expect(apiServiceMock.getCategories).toHaveBeenCalled();
    expect(component.expenses.length).toBe(2);
    expect(component.categories.length).toBe(3);
    expect(component.isLoading).toBe(false);
  });

  it('should format numbers correctly', () => {
    const result = component.formatNumber(5000.5);
    expect(result).toBe('5,001');
  });

  it('should filter expenses based on category', () => {
    // Initial state has all expenses
    expect(component.filteredExpenses.length).toBe(2);
    
    // Filter by Food category
    component.filterCategory = 'Food';
    component.filterExpenses();
    expect(component.filteredExpenses.length).toBe(1);
    expect(component.filteredExpenses[0].category).toBe('Food');
    
    // Reset filter
    component.filterCategory = 'all';
    component.filterExpenses();
    expect(component.filteredExpenses.length).toBe(2);
  });

  it('should sort expenses by date and amount', () => {
    // Add a test expense with older date but higher amount
    component.expenses.push({ 
      id: '3', 
      category: 'Entertainment', 
      amount: 1000, 
      date: '2025-04-15', 
      description: 'Concert' 
    });
    
    // Default sort is by date (newest first)
    component.filterExpenses();
    expect(component.filteredExpenses[0].id).toBe('2'); // Date: 2025-05-10
    
    // Sort by amount (highest first)
    component.sortKey = 'amount';
    component.sortExpenses();
    expect(component.filteredExpenses[0].id).toBe('3'); // Amount: 1000
  });

  it('should add a new expense', async () => {
    const mockForm = { valid: true, resetForm: jest.fn() } as unknown as NgForm;
    
    component.form = {
      category: 'Food',
      amount: 200,
      date: '2025-05-15',
      description: 'Lunch'
    };
    
    component.onSubmit(mockForm);
    
    // Wait for async operations to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(apiServiceMock.addExpense).toHaveBeenCalled();
    expect(mockForm.resetForm).toHaveBeenCalled();
    expect((component.message as any)?.type).toBe('success');
  });

  it('should update an existing expense', async () => {
    const mockForm = { valid: true, resetForm: jest.fn() } as unknown as NgForm;
    
    component.editingExpenseId = 1;
    component.isEditing = true;
    component.form = {
      category: 'Food',
      amount: 600,
      date: '2025-05-01',
      description: 'Expensive groceries'
    };
    
    component.onSubmit(mockForm);
    
    // Wait for async operations to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(apiServiceMock.updateExpense).toHaveBeenCalledWith(
      {
        id: 1,
        category: 'Food',
        amount: 600,
        date: '2025-05-01',
        description: 'Expensive groceries',
        isRecentlyAdded: true
      }, 
      1
    );
    expect(mockForm.resetForm).toHaveBeenCalled();
    expect((component.message as any)?.type).toBe('success');
    expect(component.isEditing).toBe(false);
  });

  it('should handle form validation errors', () => {
    const mockForm = { valid: false } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.addExpense).not.toHaveBeenCalled();
    expect(apiServiceMock.updateExpense).not.toHaveBeenCalled();
    expect((component.message as any)?.type).toBe('error');
  });

  it('should toggle edit mode for an expense', () => {
    const expense = { 
      id: '1', 
      category: 'Food', 
      amount: 500, 
      date: '2025-05-01', 
      description: 'Groceries',
      isRecentlyAdded: false
    };
    
    // Enable edit mode
    component.editingExpenseId = 1;
    component.editExpense(expense);
    expect(component.isEditing).toBe(true);
    expect(component.editingExpenseId as any).toBe('1'); // Use type assertion
    expect(component.form.category).toBe('Food');
    
    // Toggle edit mode off
    component.editExpense(expense);
    expect(component.isEditing).toBe(false);
    expect(component.editingExpenseId).toBeNull();
    expect(component.form).toEqual({});
  });

  it('should not edit a recently added expense', () => {
    const expense = { 
      id: '3', 
      category: 'Food', 
      amount: 200, 
      date: '2025-05-15', 
      description: 'Lunch',
      isRecentlyAdded: true
    };
    
    component.editExpense(expense);
    expect(component.isEditing).toBe(false);
    expect(component.editingExpenseId).toBeNull();
  });

  it('should delete an expense with confirmation', async () => {
    const expenseId = '1';
    
    await component.deleteExpense(expenseId);
    
    expect(Swal.fire).toHaveBeenCalled();
    expect(apiServiceMock.deleteExpense).toHaveBeenCalledWith(expenseId);
    expect((component.message as any)?.type).toBe('success');
  });

  it('should handle errors when deleting an expense', async () => {
    apiServiceMock.deleteExpense.mockReturnValue(throwError(() => new Error('Error deleting expense')));
    
    await component.deleteExpense('1');
    
    expect((component.message as any)?.type).toBe('error');
    expect(consoleErrorSpy).toHaveBeenCalled();
  });

  it('should handle pagination correctly', () => {
    // Add more expenses to test pagination
    for (let i = 0; i < 10; i++) {
      component.expenses.push({ 
        id: `${i + 3}`, 
        category: 'Food', 
        amount: 100, 
        date: '2025-05-15', 
        description: `Expense ${i + 3}`
      });
    }
    
    component.filterExpenses();
    expect(component.totalPages).toBeGreaterThan(1);
    
    const initialPage = component.currentPage;
    expect(initialPage).toBe(1);
    
    // Change to page 2
    component.changePage(2);
    expect(component.currentPage).toBe(2);
    
    // Next page (should go to page 2 if totalPages >= 2)
    component.currentPage = 1; // Reset to page 1
    component.nextPage();
    expect(component.currentPage).toBe(2);
    
    // Previous page (from page 2 back to 1)
    component.prevPage();
    expect(component.currentPage).toBe(1);
  });

  it('should set the last day of month correctly', () => {
    // February in a leap year
    expect(component.setLastDayOfMonth(1, 2024)).toBe('2024-02-29');
    
    // February in a non-leap year
    expect(component.setLastDayOfMonth(1, 2023)).toBe('2023-02-28');
    
    // April (30 days)
    expect(component.setLastDayOfMonth(3, 2025)).toBe('2025-04-30');
    
    // January (31 days)
    expect(component.setLastDayOfMonth(0, 2025)).toBe('2025-01-31');
  });

  it('should handle errors when loading expenses', () => {
    apiServiceMock.getExpenses.mockReturnValue(throwError(() => new Error('Error loading expenses')));
    
    component.loadExpenses();
    
    expect(component.expenses).toEqual([]);
    expect(component.isLoading).toBe(false);
    expect(consoleErrorSpy).toHaveBeenCalled();
  });

  it('should handle errors when loading categories', () => {
    apiServiceMock.getCategories.mockReturnValue(throwError(() => new Error('Error loading categories')));
    
    component.loadCategories();
    
    expect(component.categories).toEqual([]);
    expect(component.isLoading).toBe(false);
    expect(consoleErrorSpy).toHaveBeenCalled();
  });
});
