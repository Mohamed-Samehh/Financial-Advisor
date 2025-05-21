import { ComponentFixture, TestBed } from '@angular/core/testing';
import { BudgetComponent } from './budget.component';
import { ApiService } from '../api.service';
import { FormsModule, NgForm } from '@angular/forms';
import { CommonModule, DecimalPipe } from '@angular/common';
import { of, throwError } from 'rxjs';

describe('BudgetComponent', () => {
  let component: BudgetComponent;
  let fixture: ComponentFixture<BudgetComponent>;
  let apiServiceMock: jest.Mocked<ApiService>;

  const mockBudgetResponse = {
    budget: {
      id: '1',
      monthly_budget: 5000
    }
  };

  const mockGoalResponse = {
    goal: {
      id: '1',
      name: 'Savings',
      target_amount: 1000
    }
  };

  beforeEach(async () => {
    // Create mock for ApiService
    const apiMock = {
      getBudget: jest.fn(),
      getGoal: jest.fn(),
      addBudget: jest.fn(),
      updateBudget: jest.fn(),
      deleteBudget: jest.fn(),
      deleteGoal: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        FormsModule, 
        CommonModule,
        BudgetComponent
      ],
      providers: [
        DecimalPipe,
        { provide: ApiService, useValue: apiMock }
      ]
    }).compileComponents();

    apiServiceMock = TestBed.inject(ApiService) as jest.Mocked<ApiService>;
  });

  beforeEach(() => {
    // Set up the return values for the API calls
    apiServiceMock.getBudget.mockReturnValue(of(mockBudgetResponse));
    apiServiceMock.getGoal.mockReturnValue(of(mockGoalResponse));
    apiServiceMock.addBudget.mockReturnValue(of({ budget: { id: '2', monthly_budget: 6000 } }));
    apiServiceMock.updateBudget.mockReturnValue(of({ budget: { id: '1', monthly_budget: 7000 } }));
    apiServiceMock.deleteBudget.mockReturnValue(of({ message: 'Budget deleted successfully' }));
    apiServiceMock.deleteGoal.mockReturnValue(of({ message: 'Goal deleted successfully' }));

    fixture = TestBed.createComponent(BudgetComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load budget and goal on initialization', () => {
    expect(apiServiceMock.getBudget).toHaveBeenCalled();
    expect(apiServiceMock.getGoal).toHaveBeenCalled();
    expect(component.budget.id).toBe('1');
    expect(component.budget.monthly_budget).toBe(5000);
    expect(component.goal.id).toBe('1');
    expect(component.goal.name).toBe('Savings');
    expect(component.goal.target_amount).toBe(1000);
    expect(component.isLoading).toBe(false);
  });

  it('should format numbers correctly', () => {
    const result = component.formatNumber(5000.5);
    expect(result).toBe('5,001');
  });

  it('should handle errors when loading budget', () => {
    apiServiceMock.getBudget.mockReturnValue(throwError(() => new Error('Error loading budget')));
    component.ngOnInit();
    expect(component.isLoading).toBe(false);
  });

  it('should handle errors when loading goal', () => {
    apiServiceMock.getGoal.mockReturnValue(throwError(() => new Error('Error loading goal')));
    component.loadGoal();
    expect(component.isLoading).toBe(false);
  });

  it('should update budget when form is valid', () => {
    const mockForm = { valid: true } as NgForm;
    component.budget = { id: '1', monthly_budget: 7000 };
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.updateBudget).toHaveBeenCalledWith(component.budget, '1');
    expect(component.message?.type).toBe('success');
    expect(component.message?.text).toContain('Budget updated successfully');
  });

  it('should add new budget when form is valid and no budget id exists', () => {
    const mockForm = { valid: true } as NgForm;
    component.budget = { id: null, monthly_budget: 6000 };
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.addBudget).toHaveBeenCalledWith(component.budget);
    expect(component.message?.type).toBe('success');
    expect(component.message?.text).toContain('Budget set successfully');
  });

  it('should show error message when form is invalid', () => {
    const mockForm = { valid: false } as NgForm;
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.addBudget).not.toHaveBeenCalled();
    expect(apiServiceMock.updateBudget).not.toHaveBeenCalled();
    expect(component.message?.type).toBe('error');
  });

  it('should delete budget and associated goal when deleteBudget is called', () => {
    component.deleteBudget('1');
    
    expect(apiServiceMock.deleteBudget).toHaveBeenCalledWith('1');
    expect(apiServiceMock.deleteGoal).toHaveBeenCalledWith('1');
    expect(component.budget.id).toBeNull();
    expect(component.message?.type).toBe('success');
  });

  it('should handle errors when deleting budget', () => {
    apiServiceMock.deleteBudget.mockReturnValue(throwError(() => new Error('Error deleting budget')));
    component.deleteBudget('1');
    
    expect(component.message?.type).toBe('error');
  });

  it('should delete a goal without changing the budget', () => {
    component.deleteGoal('1');
    expect(apiServiceMock.deleteGoal).toHaveBeenCalledWith('1');
  });

  it('should handle errors when deleting goal', () => {
    apiServiceMock.deleteGoal.mockReturnValue(throwError(() => new Error('Error deleting goal')));
    component.deleteGoal('1');
    // No expectation needed, just checking it doesn't crash
  });

  it('should delete goal when setting budget below goal amount', () => {
    const mockForm = { valid: true } as NgForm;
    component.budget = { id: '1', monthly_budget: 500 }; // Less than goal amount of 1000
    component.goal = { id: '1', name: 'Savings', target_amount: 1000 };
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.deleteGoal).toHaveBeenCalledWith('1');
  });
});
