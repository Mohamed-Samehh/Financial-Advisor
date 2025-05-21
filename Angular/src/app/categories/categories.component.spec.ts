import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CategoriesComponent } from './categories.component';
import { ApiService } from '../api.service';
import { FormsModule, NgForm } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { of, throwError } from 'rxjs';
import Swal from 'sweetalert2';

// Mock SweetAlert2
jest.mock('sweetalert2', () => ({
  fire: jest.fn().mockImplementation((options) => {
    if (options.title === 'Are you sure?') {
      return Promise.resolve({ isConfirmed: true });
    } else if (options.title === 'Specify New Category') {
      return Promise.resolve({ isConfirmed: true, value: 'Other' });
    }
    return Promise.resolve({ isConfirmed: false });
  })
}));

describe('CategoriesComponent', () => {
  let component: CategoriesComponent;
  let fixture: ComponentFixture<CategoriesComponent>;
  let apiServiceMock: jest.Mocked<ApiService>;

  // Mock data for testing
  const mockCategories = [
    { id: '1', name: 'Food', priority: 1 },
    { id: '2', name: 'Transport', priority: 2 }
  ];

  const mockSuggestedCategories = {
    suggested_priorities: [
      { category: 'Food', average_expenses: 1500, suggested_priority: 1 },
      { category: 'Transport', average_expenses: 800, suggested_priority: 2 }
    ],
    first_month_suggested: 'January',
    last_month_suggested: 'May'
  };

  const mockLabeledCategories = {
    labaled_categories: [
      {
        predicted_importance: [
          { category: 'Food', predicted_importance: 'High' },
          { category: 'Transport', predicted_importance: 'Medium' }
        ]
      }
    ],
    first_month_labeled: 'January',
    last_month_labeled: 'May'
  };

  beforeEach(async () => {
    // Create a mock for ApiService
    const apiMock = {
      getCategories: jest.fn(),
      getCategorySuggestions: jest.fn(),
      getCategoryLabels: jest.fn(),
      addCategory: jest.fn(),
      updateCategory: jest.fn(),
      deleteCategory: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        FormsModule, 
        CommonModule,
        CategoriesComponent
      ],
      providers: [
        { provide: ApiService, useValue: apiMock }
      ]
    }).compileComponents();

    apiServiceMock = TestBed.inject(ApiService) as jest.Mocked<ApiService>;
  });

  beforeEach(() => {
    // Set up default return values for the API calls
    apiServiceMock.getCategories.mockReturnValue(of(mockCategories));
    apiServiceMock.getCategorySuggestions.mockReturnValue(of(mockSuggestedCategories));
    apiServiceMock.getCategoryLabels.mockReturnValue(of(mockLabeledCategories));
    apiServiceMock.addCategory.mockReturnValue(of({ id: '3', name: 'Entertainment', priority: 3 }));
    apiServiceMock.updateCategory.mockReturnValue(of({ id: '1', name: 'Food Updated', priority: 1 }));
    apiServiceMock.deleteCategory.mockReturnValue(of({ message: 'Category deleted' }));
    
    fixture = TestBed.createComponent(CategoriesComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    fixture.detectChanges();
    expect(component).toBeTruthy();
  });

  it('should load categories, suggestions and labels on init', () => {
    fixture.detectChanges();
    expect(apiServiceMock.getCategories).toHaveBeenCalled();
    expect(apiServiceMock.getCategorySuggestions).toHaveBeenCalled();
    expect(apiServiceMock.getCategoryLabels).toHaveBeenCalled();
    expect(component.categories).toEqual(mockCategories);
    expect(component.suggestedCategories).toEqual(mockSuggestedCategories.suggested_priorities);
    expect(component.labeledCategories?.length).toBe(2); // Based on mockLabeledCategories
    expect(component.isLoading).toBe(false);
  });

  it('should handle case when no categories exist', () => {
    apiServiceMock.getCategories.mockReturnValue(of([]));
    fixture.detectChanges();
    expect(component.categories.length).toBe(0);
  });

  it('should handle error when loading categories', () => {
    apiServiceMock.getCategories.mockReturnValue(throwError(() => new Error('Error')));
    fixture.detectChanges();
    expect(component.categories.length).toBe(0);
    expect(component.isLoading).toBe(false);
  });

  it('should handle when no suggested categories are available', () => {
    apiServiceMock.getCategorySuggestions.mockReturnValue(of({ suggested_priorities: [] }));
    fixture.detectChanges();
    expect(component.suggestedCategories).toBeUndefined();
  });

  it('should handle when no labeled categories are available', () => {
    apiServiceMock.getCategoryLabels.mockReturnValue(of({ labaled_categories: [] }));
    fixture.detectChanges();
    expect(component.labeledCategories).toBeUndefined();
  });

  it('should check for duplicate category names', () => {
    fixture.detectChanges();
    
    // Test for a duplicate name
    component.form.name = 'Food';
    const result = component.checkDuplicates();
    expect(result.name).toBe(true);
    
    // Test for a non-duplicate name
    component.form.name = 'Entertainment';
    const result2 = component.checkDuplicates();
    expect(result2.name).toBe(false);
  });

  it('should toggle add form correctly', () => {
    fixture.detectChanges();
    
    // Initially, isAdding should be false
    expect(component.isAdding).toBe(false);
    
    // Toggle it on
    component.toggleAddForm();
    expect(component.isAdding).toBe(true);
    expect(component.isUpdating).toBe(false);
    
    // Toggle it off
    component.toggleAddForm();
    expect(component.isAdding).toBe(false);
    // The priority should be null after toggling off
    expect(component.addForm).toEqual({ name: '', priority: null });
  });

  it('should edit a category correctly', () => {
    fixture.detectChanges();
    
    const category = { id: '1', name: 'Food', priority: 1 };
    component.editCategory(category);
    
    expect(component.isUpdating).toBe(true);
    expect(component.form).toEqual(category);
    
    // Toggle off edit mode by clicking the same category again
    component.editCategory(category);
    expect(component.isUpdating).toBe(false);
    expect(component.form).toEqual({ name: '', priority: null, id: null });
  });

  it('should add a new category', () => {
    fixture.detectChanges();
    
    // Use type assertion to fix TypeScript error
    component.addForm.name = 'Entertainment';
    // Use the nullish coalescing operator to safely assign priority
    component.addForm.priority = 3 as any;
    component.isAdding = true;
    
    // Mock the form
    const mockForm = {
      valid: true,
      value: { name: 'Entertainment', priority: 3 }
    } as NgForm;
    
    component.onAddCategory(mockForm);
    
    expect(apiServiceMock.addCategory).toHaveBeenCalledWith({ name: 'Entertainment', priority: 3 });
    expect(component.message?.type).toBe('success');
    expect(component.isAdding).toBe(false);
  });

  it('should update an existing category', () => {
    fixture.detectChanges();
    
    // Set up form values
    component.form = { id: '1', name: 'Food Updated', priority: 1 };
    component.isUpdating = true;
    
    // Mock the form
    const mockForm = {
      valid: true,
      value: { name: 'Food Updated', priority: 1 }
    } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.updateCategory).toHaveBeenCalledWith(
      { id: '1', name: 'Food Updated', priority: 1 }, 
      '1'
    );
    expect(component.message?.type).toBe('success');
    expect(component.isUpdating).toBe(false);
  });

  it('should validate forms for duplicate names', () => {
    fixture.detectChanges();
    
    // Set up form with duplicate name
    component.form = { id: '3', name: 'Food', priority: 3 };
    component.isUpdating = true;
    
    // Mock the form
    const mockForm = {
      valid: true,
      value: { name: 'Food', priority: 3 }
    } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.updateCategory).not.toHaveBeenCalled();
    expect(component.errorMessages.name).toBe('Category name already exists.');
    expect(component.message?.type).toBe('error');
  });

  it('should validate priority is within bounds', () => {
    fixture.detectChanges();
    
    // Set up form with priority too high
    component.form = { id: '1', name: 'Food', priority: 10 }; // Too high for 2 categories
    component.isUpdating = true;
    
    // Mock the form
    const mockForm = {
      valid: true,
      value: { name: 'Food', priority: 10 }
    } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(apiServiceMock.updateCategory).not.toHaveBeenCalled();
    expect(component.errorMessages.priority).toBeTruthy();
    expect(component.message?.type).toBe('error');
  });

  it('should handle duplicate name when adding a category', () => {
    fixture.detectChanges();
    
    // Set up form with duplicate name
    component.addForm.name = 'Food';
    component.addForm.priority = 3 as any;
    component.isAdding = true;
    
    // Mock the form
    const mockForm = {
      valid: true,
      value: { name: 'Food', priority: 3 }
    } as NgForm;
    
    component.onAddCategory(mockForm);
    
    expect(apiServiceMock.addCategory).not.toHaveBeenCalled();
    expect(component.errorMessages.name).toBe('Category name already exists.');
    expect(component.message?.type).toBe('error');
  });

  it('should delete a category with confirmation', async () => {
    fixture.detectChanges();
    
    await component.deleteCategoryWithConfirmation('1');
    
    expect(Swal.fire).toHaveBeenCalledTimes(2); // Two confirmations
    expect(apiServiceMock.deleteCategory).toHaveBeenCalledWith('1', 'Other');
    expect(component.message?.type).toBe('success');
  });

  it('should handle category deletion error', async () => {
    fixture.detectChanges();
    
    // Set up the error response
    apiServiceMock.deleteCategory.mockReturnValue(throwError(() => new Error('Error')));
    
    await component.deleteCategoryWithConfirmation('1');
    
    expect(component.message?.type).toBe('error');
  });

  it('should toggle between label view and suggestion view', () => {
    fixture.detectChanges();
    
    // Should start with isLabelView = false
    expect(component.isLabelView).toBe(false);
    
    // Toggle to label view
    component.isLabelView = true;
    expect(component.isLabelView).toBe(true);
    
    // Toggle back
    component.isLabelView = false;
    expect(component.isLabelView).toBe(false);
  });
});
