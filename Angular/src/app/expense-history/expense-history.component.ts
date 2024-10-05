import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-expense-history',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './expense-history.component.html',
  styleUrls: ['./expense-history.component.css']
})
export class ExpenseHistoryComponent implements OnInit {
  expensesByMonth: { [key: string]: any[] } = {};
  sortedMonths: string[] = [];
  message: { text: string; type: 'success' | 'error' } | null = null;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadExpenseHistory();
  }

  loadExpenseHistory() {
    this.apiService.getAllExpenses().subscribe({
      next: (res) => {
        this.groupExpensesByMonth(res);
      },
      error: (err) => {
        console.error('Error fetching expense history:', err);
        this.message = { text: 'Failed to load expense history. Please try again.', type: 'error' };
      }
    });
  }

  groupExpensesByMonth(expenses: any[]) {
    expenses.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    expenses.forEach(expense => {
      const expenseDate = new Date(expense.date);
      const monthYear = `${expenseDate.getFullYear()}-${String(expenseDate.getMonth() + 1).padStart(2, '0')}`;

      if (!this.expensesByMonth[monthYear]) {
        this.expensesByMonth[monthYear] = [];
      }

      this.expensesByMonth[monthYear].push(expense);
    });

    this.sortedMonths = Object.keys(this.expensesByMonth).sort((a, b) => {
      const [yearA, monthA] = a.split('-').map(Number);
      const [yearB, monthB] = b.split('-').map(Number);
      return yearB - yearA || monthB - monthA;
    });
  }
}
