import { ComponentFixture, TestBed } from '@angular/core/testing';
import { GoalsComponent } from './goals.component';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { of, throwError } from 'rxjs';

describe('GoalsComponent', () => {
  let component: GoalsComponent;
  let fixture: ComponentFixture<GoalsComponent>;
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
      name: 'Vacation',
      target_amount: 1000
    }
  };

  beforeEach(async () => {
    // Create mock for ApiService
    const apiMock = {
      getBudget: jest.fn(),
      getGoal: jest.fn(),
      addGoal: jest.fn(),
      updateGoal: jest.fn(),
      deleteGoal: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        FormsModule,
        GoalsComponent
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
    apiServiceMock.getBudget.mockReturnValue(of(mockBudgetResponse));
    apiServiceMock.getGoal.mockReturnValue(of(mockGoalResponse));
    apiServiceMock.addGoal.mockReturnValue(of({ goal: { id: '2', name: 'New Car', target_amount: 2000 } }));
    apiServiceMock.updateGoal.mockReturnValue(of({ goal: { id: '1', name: 'Updated Vacation', target_amount: 1500 } }));
    apiServiceMock.deleteGoal.mockReturnValue(of({ message: 'Goal deleted successfully' }));

    fixture = TestBed.createComponent(GoalsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load budget and goal on initialization', () => {
    expect(apiServiceMock.getBudget).toHaveBeenCalled();
    expect(apiServiceMock.getGoal).toHaveBeenCalled();
    expect(component.budget).toBe(5000);
    expect(component.goal.id).toBe('1');
    expect(component.goal.name).toBe('Vacation');
    expect(component.goal.target_amount).toBe(1000);
    expect(component.isLoading).toBe(false);
  });

  it('should format numbers correctly', () => {
    const result = component.formatNumber(5000.5);
    expect(result).toBe('5,001');
  });

  it('should add a new goal when form is valid', () => {
    // Reset the component state
    component.goal = { id: null, name: 'New Car', target_amount: 2000 };
    
    const mockForm = { valid: true } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.addGoal).toHaveBeenCalledWith({ id: null, name: 'New Car', target_amount: 2000 });
    expect(component.message?.type).toBe('success');
    expect(component.isLoading).toBe(false);
  });

  it('should update an existing goal when form is valid', () => {
    component.goal = { id: '1', name: 'Updated Vacation', target_amount: 1500 };
    
    const mockForm = { valid: true } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.updateGoal).toHaveBeenCalledWith({ id: '1', name: 'Updated Vacation', target_amount: 1500 }, '1');
    expect(component.message?.type).toBe('success');
    expect(component.goal.id).toBe('1');
    expect(component.isLoading).toBe(false);
  });

  it('should not submit form when no budget is set', () => {
    component.budget = null;
    
    const mockForm = { valid: true } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.addGoal).not.toHaveBeenCalled();
    expect(apiServiceMock.updateGoal).not.toHaveBeenCalled();
    expect(component.message?.type).toBe('error');
  });

  it('should not submit form when goal amount is greater than or equal to budget', () => {
    component.budget = 5000;
    component.goal = { id: null, name: 'Too Big', target_amount: 5000 };
    
    const mockForm = { valid: true } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.addGoal).not.toHaveBeenCalled();
    expect(apiServiceMock.updateGoal).not.toHaveBeenCalled();
    expect(component.message?.type).toBe('error');
  });

  it('should not submit form when form is invalid', () => {
    const mockForm = { valid: false } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.addGoal).not.toHaveBeenCalled();
    expect(apiServiceMock.updateGoal).not.toHaveBeenCalled();
    expect(component.message?.type).toBe('error');
  });

  it('should delete a goal', () => {
    const goalId = '1';
    
    component.deleteGoal(goalId);
    
    expect(apiServiceMock.deleteGoal).toHaveBeenCalledWith(goalId);
    expect(component.message?.type).toBe('success');
    expect(component.goal).toEqual({ id: null, name: '', target_amount: null });
    expect(component.isLoading).toBe(false);
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

  it('should handle errors when adding a goal', () => {
    apiServiceMock.addGoal.mockReturnValue(throwError(() => new Error('Error adding goal')));
    
    component.goal = { id: null, name: 'Test Goal', target_amount: 1000 };
    const mockForm = { valid: true } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(component.message?.type).toBe('error');
    expect(component.isLoading).toBe(false);
  });

  it('should handle errors when updating a goal', () => {
    apiServiceMock.updateGoal.mockReturnValue(throwError(() => new Error('Error updating goal')));
    
    component.goal = { id: '1', name: 'Updated Goal', target_amount: 1500 };
    const mockForm = { valid: true } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(component.message?.type).toBe('error');
    expect(component.isLoading).toBe(false);
  });

  it('should handle errors when deleting a goal', () => {
    apiServiceMock.deleteGoal.mockReturnValue(throwError(() => new Error('Error deleting goal')));
    
    component.deleteGoal('1');
    
    expect(component.message?.type).toBe('error');
    expect(component.isLoading).toBe(false);
  });
});
