import { TestBed } from '@angular/core/testing';
import { ApiService } from './api.service';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { HttpHeaders } from '@angular/common/http';

describe('ApiService', () => {
  let service: ApiService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [ApiService]
    });
    service = TestBed.inject(ApiService);
    httpMock = TestBed.inject(HttpTestingController);

    // Mock localStorage
    const mockLocalStorage = {
      getItem: jest.fn().mockImplementation((key) => {
        return key === 'token' ? 'test-token' : null;
      })
    };
    Object.defineProperty(window, 'localStorage', {
      value: mockLocalStorage
    });
  });

  afterEach(() => {
    httpMock.verify();
    jest.resetAllMocks();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should create headers with authorization token', () => {
    const headers = service.getHeaders();
    expect(headers instanceof HttpHeaders).toBe(true);
    expect(headers.get('Authorization')).toBe('Bearer test-token');
    expect(headers.get('Content-Type')).toBe('application/json');
  });

  // Test Budget API methods
  describe('Budget API methods', () => {
    it('should get all budgets', () => {
      const mockResponse = { budgets: [] };
      
      service.getAllBudgets().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/budget/all`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should get current budget', () => {
      const mockResponse = { budget: { id: '1', monthly_budget: 5000 } };
      
      service.getBudget().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/budget`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should add budget', () => {
      const mockBudget = { monthly_budget: 5000 };
      const mockResponse = { budget: { id: '1', monthly_budget: 5000 } };
      
      service.addBudget(mockBudget).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/budget`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(mockBudget);
      req.flush(mockResponse);
    });

    it('should update budget', () => {
      const mockBudget = { monthly_budget: 6000 };
      const budgetId = '1';
      const mockResponse = { budget: { id: '1', monthly_budget: 6000 } };
      
      service.updateBudget(mockBudget, budgetId).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/budget/${budgetId}`);
      expect(req.request.method).toBe('PUT');
      expect(req.request.body).toEqual(mockBudget);
      req.flush(mockResponse);
    });

    it('should delete budget', () => {
      const budgetId = '1';
      const mockResponse = { message: 'Budget deleted successfully' };
      
      service.deleteBudget(budgetId).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/budget/${budgetId}`);
      expect(req.request.method).toBe('DELETE');
      req.flush(mockResponse);
    });
  });

  // Test Goal API methods
  describe('Goal API methods', () => {
    it('should get all goals', () => {
      const mockResponse = { goals: [] };
      
      service.getAllGoals().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/goal/all`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should get current goal', () => {
      const mockResponse = { goal: { id: '1', name: 'Vacation', target_amount: 1000 } };
      
      service.getGoal().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/goal`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should add goal', () => {
      const mockGoal = { name: 'Vacation', target_amount: 1000 };
      const mockResponse = { goal: { id: '1', name: 'Vacation', target_amount: 1000 } };
      
      service.addGoal(mockGoal).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/goal`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(mockGoal);
      req.flush(mockResponse);
    });

    it('should update goal', () => {
      const mockGoal = { name: 'New Car', target_amount: 2000 };
      const goalId = '1';
      const mockResponse = { goal: { id: '1', name: 'New Car', target_amount: 2000 } };
      
      service.updateGoal(mockGoal, goalId).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/goal/${goalId}`);
      expect(req.request.method).toBe('PUT');
      expect(req.request.body).toEqual(mockGoal);
      req.flush(mockResponse);
    });

    it('should delete goal', () => {
      const goalId = '1';
      const mockResponse = { message: 'Goal deleted successfully' };
      
      service.deleteGoal(goalId).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/goal/${goalId}`);
      expect(req.request.method).toBe('DELETE');
      req.flush(mockResponse);
    });
  });

  // Test Expenses API methods
  describe('Expenses API methods', () => {
    it('should get all expenses with pagination parameters', () => {
      const page = 2;
      const perPage = 10;
      const mockResponse = { data: [], current_page: 2, last_page: 5 };
      
      service.getAllExpenses(page, perPage).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/expenses/all?page=${page}&per_page=${perPage}`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should get current month expenses', () => {
      const mockResponse = { expenses: [] };
      
      service.getExpenses().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/expenses`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should add expense', () => {
      const mockExpense = { category: 'Food', amount: 100, date: '2025-05-20' };
      const mockResponse = { id: '1', category: 'Food', amount: 100, date: '2025-05-20' };
      
      service.addExpense(mockExpense).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/expenses`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(mockExpense);
      req.flush(mockResponse);
    });

    it('should update expense', () => {
      const mockExpense = { category: 'Food', amount: 150, date: '2025-05-20' };
      const expenseId = '1';
      const mockResponse = { id: '1', category: 'Food', amount: 150, date: '2025-05-20' };
      
      service.updateExpense(mockExpense, expenseId).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/expenses/${expenseId}`);
      expect(req.request.method).toBe('PUT');
      expect(req.request.body).toEqual(mockExpense);
      req.flush(mockResponse);
    });

    it('should delete expense', () => {
      const expenseId = '1';
      const mockResponse = { message: 'Expense deleted successfully' };
      
      service.deleteExpense(expenseId).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/expenses/${expenseId}`);
      expect(req.request.method).toBe('DELETE');
      req.flush(mockResponse);
    });

    it('should get expense analysis', () => {
      const mockResponse = { 
        total_spent: 1000, 
        remaining_budget: 4000,
        daily_expenses: {}
      };
      
      service.analyzeExpenses().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/analyze-expenses`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });
  });

  // Test Categories API methods
  describe('Categories API methods', () => {
    it('should get categories', () => {
      const mockResponse = [
        { id: '1', name: 'Food', priority: 1 },
        { id: '2', name: 'Transport', priority: 2 }
      ];
      
      service.getCategories().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/categories`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should add category', () => {
      const mockCategory = { name: 'Entertainment', priority: 3 };
      const mockResponse = { id: '3', name: 'Entertainment', priority: 3 };
      
      service.addCategory(mockCategory).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/categories`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(mockCategory);
      req.flush(mockResponse);
    });

    it('should update category', () => {
      const mockCategory = { name: 'Entertainment', priority: 2 };
      const categoryId = '3';
      const mockResponse = { id: '3', name: 'Entertainment', priority: 2 };
      
      service.updateCategory(mockCategory, categoryId).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/categories/${categoryId}`);
      expect(req.request.method).toBe('PUT');
      expect(req.request.body).toEqual(mockCategory);
      req.flush(mockResponse);
    });

    it('should delete category with new category assignment', () => {
      const categoryId = '3';
      const newCategory = 'Food';
      const mockResponse = { message: 'Category deleted successfully' };
      
      service.deleteCategory(categoryId, newCategory).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/categories/${categoryId}`);
      expect(req.request.method).toBe('DELETE');
      expect(req.request.body).toEqual({ new_category: newCategory });
      req.flush(mockResponse);
    });

    it('should get category suggestions', () => {
      const mockResponse = { 
        suggested_priorities: [], 
        first_month_suggested: 'January',
        last_month_suggested: 'May'
      };
      
      service.getCategorySuggestions().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/categories/suggest`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should get category labels', () => {
      const mockResponse = { 
        labaled_categories: [],
        first_month_labeled: 'January',
        last_month_labeled: 'May'
      };
      
      service.getCategoryLabels().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/categories/label`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });
  });

  // Test Stock API methods
  describe('Stock API methods', () => {
    it('should get Egypt stocks', () => {
      const mockResponse = [
        { Code: 'COMI.CA', Name: 'Commercial International Bank Egypt' },
        { Code: 'HRHO.CA', Name: 'EFG Hermes Holding' }
      ];
      
      service.getEgyptStocks().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/stocks/egypt`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should get stock details', () => {
      const symbol = 'COMI.CA';
      const mockResponse = [
        { date: '2025-05-19', open: 42.5, close: 43.0 },
        { date: '2025-05-20', open: 43.0, close: 43.2 }
      ];
      
      service.getStockDetails(symbol).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/stocks/details/${symbol}`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });
  });

  // Test Chat API
  describe('Chat API methods', () => {
    it('should send chat message', () => {
      const message = 'How can I save money?';
      const mockResponse = { message: 'Here are some saving tips...' };
      
      service.sendChatMessage(message).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/chatbot`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ message });
      req.flush(mockResponse);
    });
  });
});
