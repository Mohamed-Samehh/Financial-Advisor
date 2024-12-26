import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-expenses',
  standalone: true,
  imports: [CommonModule, FormsModule],
  providers: [DecimalPipe],
  templateUrl: './expenses.component.html',
  styleUrls: ['./expenses.component.css']
})
export class ExpensesComponent implements OnInit {
  expenses: any[] = [];
  form: any = {};
  message: { text: string; type: 'success' | 'error' } | null = null;
  submitted: boolean = false;
  minDate: string;
  maxDate: string;
  isLoading: boolean = false;
  currentPage: number = 1;
  itemsPerPage: number = 8;
  paginatedExpenses: any[] = [];
  totalPages: number = 0;
  pages: number[] = [];
  categories: string[] = [];
  editingExpenseId: number | null = null;
  isEditing: boolean = false;

  constructor(private apiService: ApiService, private decimalPipe: DecimalPipe) {
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth();

    this.minDate = `${year}-${String(month + 1).padStart(2, '0')}-01`;
    this.maxDate = this.setLastDayOfMonth(month, year);
  }

  ngOnInit() {
    this.loadExpenses();
    this.loadCategories();
  }

  loadExpenses() {
    this.isLoading = true;
    this.apiService.getExpenses().subscribe({
      next: (res) => {
        this.expenses = res.expenses || [];
        this.totalPages = Math.ceil(this.expenses.length / this.itemsPerPage);
        this.updatePaginatedExpenses();
        this.updatePageNumbers();
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching expenses:', err);
        this.expenses = [];
        this.isLoading = false;
      }
    });
  }

  loadCategories() {
    this.isLoading = true;
    this.apiService.getCategories().subscribe({
      next: (res) => {
        this.categories = res.map((category: any) => category.name);
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching categories:', err);
        this.categories = [];
        this.isLoading = false;
      }
    });
  }

  formatNumber(value: number): string {
    const formattedValue = this.decimalPipe.transform(value, '1.0-0');
    return formattedValue !== null ? formattedValue : '0';
  }

  setLastDayOfMonth(month: number, year: number): string {
    let lastDay: number;

    if (month === 1) { // February
      lastDay = (year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0)) ? 29 : 28;
    } else if ([3, 5, 8, 10].includes(month)) { // April, June, September, November
      lastDay = 30;
    } else { // January, March, May, July, August, October, December
      lastDay = 31;
    }

    return `${year}-${String(month + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
  }

  validateDate(date: string): { [key: string]: boolean } | null {
    const selectedDate = new Date(date);
    const today = new Date();

    const firstDay = new Date(today.getFullYear(), today.getMonth(), 1);

    if (isNaN(selectedDate.getTime())) {
      return { invalid: true };
    }

    if (selectedDate < firstDay) {
      return { min: true };
    }

    if (selectedDate > new Date(this.maxDate)) {
      return { max: true };
    }

    return null;
  }

  onSubmit(expenseForm: any) {
    this.submitted = true;

    if (expenseForm.valid) {
      this.isLoading = true;

      const dateValidationError = this.validateDate(this.form.date);
      if (dateValidationError) {
        this.message = { text: 'Date must be within the current month.', type: 'error' };
        this.isLoading = false;
        return;
      }

      const tempExpense = {
        id: this.editingExpenseId,
        category: this.form.category || 'No category',
        amount: this.form.amount || 0,
        date: this.form.date || new Date().toISOString().split('T')[0],
        description: this.form.description || 'No description',
        isRecentlyAdded: true
      };

      if (this.editingExpenseId) {
        // If editing an existing expense, update it
        this.apiService.updateExpense(tempExpense, this.editingExpenseId).subscribe({
          next: (res) => {
            this.message = { text: 'Expense updated successfully!', type: 'success' };
            expenseForm.resetForm();
            this.form = {};
            this.submitted = false;
            this.editingExpenseId = null;
            this.isEditing = false;
            this.loadExpenses();
            this.isLoading = false;
          },
          error: (err) => {
            console.error('Failed to update expense', err);
            this.message = { text: 'Error updating expense. Please try again.', type: 'error' };
            this.isLoading = false;
          }
        });
      } else {
        // Add new expense if not editing
        this.expenses.unshift(tempExpense);
        this.updatePaginatedExpenses();

        this.apiService.addExpense(tempExpense).subscribe({
          next: (res) => {
            this.message = { text: 'Expense added successfully!', type: 'success' };
            expenseForm.resetForm();
            this.form = {};
            this.submitted = false;
            this.isLoading = false;
          },
          error: (err) => {
            console.error('Failed to add expense', err);
            this.expenses.shift();
            this.updatePaginatedExpenses();
            this.message = { text: 'Error adding expense. Please try again.', type: 'error' };
            this.isLoading = false;
          }
        });
      }
    } else {
      this.message = { text: 'Please fill out all required fields correctly.', type: 'error' };
    }
  }

  editExpense(expense: any) {
    if (expense.isRecentlyAdded) return;

    if (this.isEditing && this.editingExpenseId === expense.id) {
      this.isEditing = false;
      this.editingExpenseId = null;
      this.form = {};
    } else {
      this.isEditing = true;
      this.editingExpenseId = expense.id;
      this.form = {
        category: expense.category,
        amount: expense.amount,
        date: expense.date,
        description: expense.description
      };
    }
  }

  deleteExpense(expenseId: any) {
    const expense = this.expenses.find(exp => exp.id === expenseId);
    if (expense?.isRecentlyAdded) return;

    this.isLoading = true;
    this.apiService.deleteExpense(expenseId).subscribe({
      next: () => {
        this.expenses = this.expenses.filter(expense => expense.id !== expenseId);
        this.updatePaginatedExpenses();
        this.message = { text: 'Expense deleted successfully!', type: 'success' };
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Failed to delete expense', err);
        this.message = { text: 'Error deleting expense. Please try again.', type: 'error' };
        this.isLoading = false;
      }
    });
  }

  updatePaginatedExpenses() {
    const start = (this.currentPage - 1) * this.itemsPerPage;
    this.paginatedExpenses = this.expenses.slice(start, start + this.itemsPerPage);
  }

  updatePageNumbers() {
    this.pages = Array.from({ length: this.totalPages }, (_, i) => i + 1);
  }

  changePage(page: number) {
    if (page < 1 || page > this.totalPages) return;
    this.currentPage = page;
    this.updatePaginatedExpenses();
  }

  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.updatePaginatedExpenses();
    }
  }

  prevPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.updatePaginatedExpenses();
    }
  }
}
