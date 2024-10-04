import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-expenses',
  standalone: true,
  imports: [CommonModule, FormsModule],
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

  constructor(private apiService: ApiService) {
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth();

    this.minDate = `${year}-${String(month + 1).padStart(2, '0')}-01`;
    this.maxDate = this.setLastDayOfMonth(month, year);
  }

  ngOnInit() {
    this.loadExpenses();
  }

  loadExpenses() {
    this.apiService.getExpenses().subscribe({
      next: (res) => {
        this.expenses = res.expenses || [];
      },
      error: (err) => {
        console.error('Error fetching expenses:', err);
        this.expenses = [];
      }
    });
  }

  setLastDayOfMonth(month: number, year: number): string {
    let lastDay: number;

    if (month === 1) {
      lastDay = (year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0)) ? 29 : 28;
    } else if ([3, 5, 8, 10].includes(month)) {
      lastDay = 30;
    } else {
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
      const dateValidationError = this.validateDate(this.form.date);
      if (dateValidationError) {
        this.message = { text: 'Date must be within the current month.', type: 'error' };
        return;
      }

      const tempExpense = {
        category: this.form.category || 'No category',
        amount: this.form.amount || 0,
        date: this.form.date || new Date().toISOString().split('T')[0],
        description: this.form.description || 'No description'
      };

      this.expenses.unshift(tempExpense);

      this.form = {};
      this.submitted = false;

      this.apiService.addExpense(tempExpense).subscribe({
        next: (res) => {
          this.message = { text: 'Expense added successfully!', type: 'success' };
          expenseForm.resetForm();
        },
        error: (err) => {
          console.error('Failed to add expense', err);
          this.expenses.shift();
          this.message = { text: 'Error adding expense. Please try again.', type: 'error' };
        }
      });
    } else {
      this.message = { text: 'Please fill out all required fields correctly.', type: 'error' };
    }
  }

  deleteExpense(expenseId: any) {
    this.apiService.deleteExpense(expenseId).subscribe({
      next: () => {
        this.expenses = this.expenses.filter(expense => expense.id !== expenseId);
        this.message = { text: 'Expense deleted successfully!', type: 'success' };
      },
      error: (err) => {
        console.error('Failed to delete expense', err);
        this.message = { text: 'Error deleting expense. Please try again.', type: 'error' };
      }
    });
  }
}
