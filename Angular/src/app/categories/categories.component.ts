import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ApiService } from '../api.service';

@Component({
  selector: 'app-categories',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './categories.component.html',
  styleUrl: './categories.component.css',
})
export class CategoriesComponent implements OnInit {
  categories: any[] = [];
  form: any = { name: '', priority: null, id: null };
  isLoading: boolean = false;
  isUpdating: boolean = false;
  errorMessages: { name: string | null; priority: string | null } = {
    name: null,
    priority: null,
  };
  message: { type: string; text: string } | null = null;
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
      error: () => {
        this.categories = [];
        this.isLoading = false;
      },
    });
  }

  checkDuplicates() {
    const trimmedName = this.form.name.trim().toLowerCase();
    const duplicateName = this.categories.some(
      (category) =>
        category.name.trim().toLowerCase() === trimmedName &&
        category.id !== this.form.id
    );
    return { name: duplicateName };
  }

  onSubmit(form: any) {
    this.submitted = true;
    this.errorMessages = { name: null, priority: null };
    this.message = null;

    const duplicates = this.checkDuplicates();

    if (duplicates.name) {
      this.errorMessages.name = 'Category name already exists.';
    }

    if (this.errorMessages.name) {
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
          this.message = {
            type: 'success',
            text: 'Category updated successfully!',
          };
        },
        error: () => {
          this.message = {
            type: 'error',
            text: 'An error occurred while updating the category.',
          };
        },
      });
    }

    this.form = { name: '', priority: null };
    this.isUpdating = false;
  }

  editCategory(category: any) {
    if (this.isUpdating && this.form.id === category.id) {
      this.isUpdating = false;
      this.form = { name: '', priority: null, id: null };
    } else {
      this.form = { ...category };
      this.isUpdating = true;
    }
  }
}
