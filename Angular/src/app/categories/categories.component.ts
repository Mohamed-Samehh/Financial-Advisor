import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ApiService } from '../api.service';

@Component({
  selector: 'app-categories',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './categories.component.html',
  styleUrls: ['./categories.component.css'],
})
export class CategoriesComponent implements OnInit {
  categories: any[] = [];
  form: any = { name: '', priority: null, id: null };
  addForm = { name: '', priority: null };
  isLoading: boolean = false;
  isUpdating: boolean = false;
  isAdding: boolean = false;
  errorMessages: { name: string | null; priority: string | null } = {
    name: null,
    priority: null,
  };
  message: { type: string; text: string } | null = null;
  submitted: boolean = false;
  suggestedCategories: any[] = [];
  lastMonthWithExpenses: string | null = null;
  classifiedCategories: any[] = [];
  accuracy: number | null = null;
  buttonHover: boolean = false;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadCategories();
    this.loadSuggestedCategories();
    this.loadClassifiedCategories();
  }

  loadCategories() {
    this.isLoading = true;

    this.apiService.getCategories().subscribe({
      next: (res) => {
        this.categories = res;
        this.isLoading = false;
      },
      error: () => {
        this.categories = [];
        this.isLoading = false;
      },
    });
  }

  loadSuggestedCategories() {
    this.apiService.getCategorySuggestions().subscribe({
      next: (res) => {
        if (res && res.suggested_priorities && res.suggested_priorities.length > 0) {
          this.suggestedCategories = res.suggested_priorities;

          if (res.last_month_with_expenses) {
            this.lastMonthWithExpenses = res.last_month_with_expenses;
          }
        }
      },
      error: () => {
        this.suggestedCategories = [];
        this.lastMonthWithExpenses = null;
      }
    });
  }

  loadClassifiedCategories() {
    this.apiService.getCategoryClassifications().subscribe({
      next: (res) => {
        if (res && res.importance_classification && res.importance_classification.length > 0) {
          const classificationData = res.importance_classification[0];
          this.accuracy = classificationData.accuracy;
          this.classifiedCategories = classificationData.predicted_importance.map((item: any) => ({
            category: item.category,
            predicted_importance: item.predicted_importance
          }));
        } else {
          this.classifiedCategories = [];
          this.accuracy = null;
        }
      },
      error: () => {
        this.classifiedCategories = [];
        this.accuracy = null;
      }
    });
  }

  checkDuplicates() {
    const trimmedName = (this.isAdding ? this.addForm.name : this.form.name).trim().toLowerCase();
    const duplicateName = this.categories.some(
      (category) =>
        category.name.trim().toLowerCase() === trimmedName &&
        (this.isAdding || category.id !== this.form.id)
    );
    return { name: duplicateName };
  }

  // Handle form submission for updates
  onSubmit(form: any) {
    this.submitted = true;
    this.errorMessages = { name: null, priority: null };
    this.message = null;

    const duplicates = this.checkDuplicates();

    if (duplicates.name) {
      this.errorMessages.name = 'Category name already exists.';
    }

    const maxPriority = this.categories.length;
    if (this.form.priority > maxPriority) {
      this.errorMessages.priority = `Priority cannot be greater than ${maxPriority}.`;
    }

    if (this.errorMessages.name || this.errorMessages.priority) {
      this.message = {
        type: 'error',
        text: 'Please fix the errors before submitting.',
      };
      return;
    }

    if (this.form.id) {
      this.apiService.updateCategory(this.form, this.form.id).subscribe({
        next: () => {
          this.loadCategories();
          this.loadSuggestedCategories();
          this.message = {
            type: 'success',
            text: 'Category updated successfully!',
          };

          this.form = { name: '', priority: null };
          this.isUpdating = false;
          this.submitted = false;
          this.errorMessages = { name: null, priority: null };
        },
        error: () => {
          this.message = {
            type: 'error',
            text: 'An error occurred while updating the category.',
          };
        },
      });
    }
  }

  // Handle form submission for adding a new category
  onAddCategory(form: any) {
    this.submitted = true;
    this.errorMessages = { name: null, priority: null };
    this.message = null;
    const duplicates = this.checkDuplicates();

    if (duplicates.name) {
      this.errorMessages.name = 'Category name already exists.';
    }

    const priority = this.addForm.priority;
    if (priority && !isNaN(priority)) {
      const maxPriority = this.categories.length + 1;
      if (priority > maxPriority) {
        this.errorMessages.priority = `Priority cannot be greater than ${maxPriority}.`;
      }
    } else {
      this.errorMessages.priority = 'Priority must be a valid number.';
    }

    if (this.errorMessages.name || this.errorMessages.priority) {
      this.message = {
        type: 'error',
        text: 'Please fix the errors before submitting.',
      };
      return;
    }

    const newCategory = { name: this.addForm.name, priority: this.addForm.priority };
    this.apiService.addCategory(newCategory).subscribe({
      next: () => {
        this.loadCategories();
        this.loadSuggestedCategories();
        this.message = {
          type: 'success',
          text: 'Category added successfully!',
        };

        this.addForm = { name: '', priority: null };
        this.submitted = false;
        this.errorMessages = { name: null, priority: null };
        this.isAdding = false;
      },
      error: () => {
        this.message = {
          type: 'error',
          text: 'An error occurred while adding the category.',
        };
      },
    });
  }

  toggleAddForm() {
    this.isAdding = !this.isAdding;
    if (this.isAdding) {
      this.isUpdating = false;
    } else {
      this.addForm = { name: '', priority: null };
      this.errorMessages = { name: null, priority: null };
      this.submitted = false;
    }
  }

  // Edit category for updating
  editCategory(category: any) {
    if (this.isUpdating && this.form.id === category.id) {
      this.isUpdating = false;
      this.form = { name: '', priority: null, id: null };
    } else {
      this.form = { ...category };
      this.isUpdating = true;
    }
  }

  // Delete category with confirmation and reassign expenses
  deleteCategoryWithConfirmation(categoryId: any) {
    const confirmation = window.confirm(
      'Deleting this category will move its all time expenses to a new category. This change is permanent. Do you want to continue?'
    );

    if (confirmation) {
      const newCategory = prompt(
        'Please enter the new category name to move all expenses to:'
      );

      if (newCategory) {
        this.apiService.deleteCategory(categoryId, newCategory).subscribe({
          next: () => {
            this.message = {
              type: 'success',
              text: 'Category deleted and expenses reassigned successfully!',
            };
            this.loadCategories();
            this.loadSuggestedCategories();
          },
          error: (err) => {
            this.message = {
              type: 'error',
              text: 'An error occurred while deleting the category.',
            };
          },
        });
      } else {
        this.message = {
          type: 'error',
          text: 'No category name entered. Deletion cancelled.',
        };
      }
    } else {
      this.message = {
        type: 'error',
        text: 'Category deletion was cancelled.',
      };
    }
  }
}
