import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule } from '@angular/common';
import { forkJoin } from 'rxjs';

@Component({
  selector: 'app-expense-history',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './expense-history.component.html',
  styleUrls: ['./expense-history.component.css']
})
export class ExpenseHistoryComponent implements OnInit {
  expensesByMonth: { [key: string]: any[] } = {};
  totalExpensesByMonth: { [key: string]: number } = {};
  budgetByMonth: { [key: string]: any } = {};
  goalByMonth: { [key: string]: any } = {};
  sortedMonths: string[] = [];
  message: { text: string; type: 'success' | 'error' } | null = null;
  isLoading = true;
  currentPage = 1;
  totalPages = 3;
  monthsPerPage = 12;
  pages = Array.from({ length: this.totalPages }, (_, i) => i + 1);
  currentYear = new Date().getFullYear();

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadExpenseHistory();
  }

  loadExpenseHistory() {
    this.isLoading = true;
    forkJoin({
      expenses: this.apiService.getAllExpenses(),
      budgets: this.apiService.getAllBudgets(),
      goals: this.apiService.getAllGoals(),
    }).subscribe({
      next: (res) => {
        const { expenses, budgets, goals } = res;

        const budgetsArray = budgets.budgets || [];
        const goalsArray = goals.goals || [];

        this.groupExpensesByMonth(expenses);

        // Get the current month and year
        const currentMonth = new Date().getMonth() + 1; // getMonth() is zero-based
        const currentYear = new Date().getFullYear();

        // Filter to include all months up to the current month of the current year
        this.sortedMonths = this.sortedMonths.filter(monthYear => {
          const [year, month] = monthYear.split('-').map(Number);
          return year < currentYear || (year === currentYear && month <= currentMonth);
        });

        this.assignBudgetsAndGoals(budgetsArray, goalsArray);

        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching data:', err);
        this.message = { text: 'Failed to load data. Please try again.', type: 'error' };
        this.isLoading = false;
      }
    });
  }

  // Grouping expenses by month
  groupExpensesByMonth(expenses: any[]) {
    expenses.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    for (let year = this.currentYear - 2; year <= this.currentYear; year++) {
      for (let month = 1; month <= 12; month++) {
        const monthYear = `${year}-${String(month).padStart(2, '0')}`;
        if (!this.expensesByMonth[monthYear]) {
          this.expensesByMonth[monthYear] = [];
          this.totalExpensesByMonth[monthYear] = 0;
        }
      }
    }

    expenses.forEach(expense => {
      const expenseDate = new Date(expense.date);
      const monthYear = `${expenseDate.getFullYear()}-${String(expenseDate.getMonth() + 1).padStart(2, '0')}`;

      if (!this.expensesByMonth[monthYear]) {
        this.expensesByMonth[monthYear] = [];
        this.totalExpensesByMonth[monthYear] = 0;
      }

      this.expensesByMonth[monthYear].push(expense);
      this.totalExpensesByMonth[monthYear] += expense.amount;
    });

    this.sortedMonths = Object.keys(this.expensesByMonth).sort((a, b) => {
      const [yearA, monthA] = a.split('-').map(Number);
      const [yearB, monthB] = b.split('-').map(Number);
      return yearB - yearA || monthB - monthA;
    });
  }

  // Assign budgets and goals to each month
  assignBudgetsAndGoals(budgets: any[], goals: any[]) {
    budgets.forEach(budget => {
      const budgetDate = new Date(budget.created_at);
      const monthYear = `${budgetDate.getFullYear()}-${String(budgetDate.getMonth() + 1).padStart(2, '0')}`;
      this.budgetByMonth[monthYear] = budget;
    });

    // Match goals based on their creation month
    goals.forEach(goal => {
      const goalDate = new Date(goal.created_at);
      const monthYear = `${goalDate.getFullYear()}-${String(goalDate.getMonth() + 1).padStart(2, '0')}`;
      this.goalByMonth[monthYear] = goal;
    });
  }

  // Pagination controls
  getMonthsForCurrentPage(): string[] {
    const startIndex = (this.currentPage - 1) * this.monthsPerPage;
    return this.sortedMonths.slice(startIndex, startIndex + this.monthsPerPage);
  }

  goToPage(page: number) {
    this.currentPage = page;
  }

  previousPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
    }
  }

  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
    }
  }
}
