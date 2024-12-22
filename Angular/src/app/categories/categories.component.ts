import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ApiService } from '../api.service';

@Component({
  selector: 'app-categories',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './categories.component.html',
  styleUrl: './categories.component.css'
})
export class CategoriesComponent implements OnInit {
  categories: any[] = [];
  form: any = { name: '', priority: null, id: null };
  isLoading: boolean = false;
  isUpdating: boolean = false;
  errorMessages: { name: string | null, priority: string | null } = { name: null, priority: null };
  message: { type: string, text: string } | null = null;
  submitted: boolean = false;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadCategories();
  }

  loadCategories() {
    this.isLoading = true;
    this.apiService.getCategories().subscribe({
      next: (res) => {
        this.categories = res;
        this.isLoading = false;
      },
      error: (err) => {
        this.categories = [];
        this.isLoading = false;
      }
    });
  }

  // Check for duplicate name or priority
  checkDuplicates() {
    const duplicateName = this.isUpdating && this.form.name === this.categories.find(category => category.id === this.form.id)?.name
      ? false
      : this.categories.some(category => category.name.toLowerCase() === this.form.name.toLowerCase());

    const duplicatePriority = this.categories.some(category => category.priority === this.form.priority && category.id !== this.form.id);

    return { name: duplicateName, priority: duplicatePriority };
  }

  onSubmit(form: any) {
    this.submitted = true;
    this.errorMessages = { name: null, priority: null };
    this.message = null;

    const duplicates = this.checkDuplicates();

    if (duplicates.name) {
      this.errorMessages.name = 'Category name already exists.';
    }

    if (duplicates.priority) {
      this.errorMessages.priority = 'Priority already exists.';
    }

    // If there are errors, set the message and stop the submission
    if (this.errorMessages.name || this.errorMessages.priority) {
      this.message = { type: 'error', text: 'Please fix the errors before submitting.' };
      return;
    }

    if (this.form.id) {
      this.apiService.updateCategory(this.form, this.form.id).subscribe({
        next: () => {
          this.loadCategories();
          this.message = { type: 'success', text: 'Category updated successfully!' };
        },
        error: () => {
          this.message = { type: 'error', text: 'An error occurred while updating the category.' };
        }
      });
    } else {
      this.apiService.addCategory(this.form).subscribe({
        next: () => {
          this.loadCategories();
          this.message = { type: 'success', text: 'Category added successfully!' };
        },
        error: () => {
          this.message = { type: 'error', text: 'An error occurred while adding the category.' };
        }
      });
    }
    this.form = { name: '', priority: null };
    this.isUpdating = false;
  }

  editCategory(category: any) {
    this.form = { ...category };
    this.isUpdating = true;
  }

  deleteCategory(id: any) {
    this.apiService.deleteCategory(id).subscribe({
      next: () => {
        this.loadCategories();
        this.message = { type: 'success', text: 'Category deleted successfully!' };
      },
      error: () => {
        this.message = { type: 'error', text: 'An error occurred while deleting the category.' };
      }
    });
  }
}
