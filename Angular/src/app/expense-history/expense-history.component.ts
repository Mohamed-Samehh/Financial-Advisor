import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { forkJoin } from 'rxjs';

@Component({
  selector: 'app-expense-history',
  standalone: true,
  imports: [CommonModule],
  providers: [DecimalPipe],
  templateUrl: './expense-history.component.html',
  styleUrls: ['./expense-history.component.css']
})
export class ExpenseHistoryComponent implements OnInit {
  expensesByMonth: { [key: string]: any[] } = {};
  totalExpensesByMonth: { [key: string]: number } = {};
  budgetByMonth: { [key: string]: any } = {};
  goalByMonth: { [key: string]: any } = {};
  sortedMonths: string[] = [];
  message: { text: string; type: 'error' } | null = null;
  isLoading = true;
  currentPage = 1;
  totalPages = 1;
  monthsPerPage = 12;
  pages: number[] = [];
  currentYear = new Date().getFullYear();
  currentMonth = new Date().getMonth() + 1;

  constructor(private apiService: ApiService, private decimalPipe: DecimalPipe) {}

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

        this.assignBudgetsAndGoals(budgetsArray, goalsArray);

        this.setupPagination();

        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching data:', err);
        this.message = { text: 'Failed to load data. Please try again.', type: 'error' };
        this.isLoading = false;
      }
    });
  }

  groupExpensesByMonth(expenses: any[]) {
    expenses.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

    const yearsWithExpenses = new Set<number>();

    expenses.forEach(expense => {
      const expenseDate = new Date(expense.date);
      const year = expenseDate.getFullYear();
      const month = expenseDate.getMonth() + 1;
      const monthYear = `${year}-${String(month).padStart(2, '0')}`;

      if (year === this.currentYear && month === this.currentMonth) {
        return;
      }

      yearsWithExpenses.add(year);

      if (!this.expensesByMonth[monthYear]) {
        this.expensesByMonth[monthYear] = [];
        this.totalExpensesByMonth[monthYear] = 0;
      }

      this.expensesByMonth[monthYear].push(expense);
      this.totalExpensesByMonth[monthYear] += expense.amount;
    });

    yearsWithExpenses.forEach(year => {
      for (let month = 1; month <= 12; month++) {
        const monthYear = `${year}-${String(month).padStart(2, '0')}`;
        if (!this.expensesByMonth[monthYear]) {
          this.expensesByMonth[monthYear] = [];
          this.totalExpensesByMonth[monthYear] = 0;
        }
      }
    });

    this.sortedMonths = Object.keys(this.expensesByMonth).sort((a, b) => {
      const [yearA, monthA] = a.split('-').map(Number);
      const [yearB, monthB] = b.split('-').map(Number);
      return yearB - yearA || monthB - monthA;
    });
  }

  assignBudgetsAndGoals(budgets: any[], goals: any[]) {
    budgets.forEach(budget => {
      const budgetDate = new Date(budget.created_at);
      const monthYear = `${budgetDate.getFullYear()}-${String(budgetDate.getMonth() + 1).padStart(2, '0')}`;
      this.budgetByMonth[monthYear] = budget;
    });

    goals.forEach(goal => {
      const goalDate = new Date(goal.created_at);
      const monthYear = `${goalDate.getFullYear()}-${String(goalDate.getMonth() + 1).padStart(2, '0')}`;
      this.goalByMonth[monthYear] = goal;
    });
  }

  setupPagination() {
    this.totalPages = Math.ceil(this.sortedMonths.length / this.monthsPerPage);
    this.pages = Array.from({ length: this.totalPages }, (_, i) => i + 1);
  }

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

  formatNumber(value: number): string {
    return this.decimalPipe.transform(value, '1.0-0') || '0';
  }

  Expense_summary(monthYear: string): string {
    const budget = this.budgetByMonth[monthYear]?.monthly_budget || 0;
    const goalTarget = this.goalByMonth[monthYear]?.target_amount || 0;
    const totalExpenses = this.totalExpensesByMonth[monthYear] || 0;

    if (totalExpenses > budget) {
      return 'budget_surpassed';
    }

    if (!goalTarget || totalExpenses > (budget - goalTarget)) {
      return 'goal_not_met';
    }

    return 'goal_met';
  }

  getCurrentPageYear(): string {
    if (this.sortedMonths.length === 0) return '';
  
    const firstMonthYear = this.getMonthsForCurrentPage()[0];
    return firstMonthYear ? firstMonthYear.split('-')[0] : '';
  }

  isFutureMonth(monthYear: string): boolean {
    const [year, month] = monthYear.split('-').map(Number);
    return year > this.currentYear || (year === this.currentYear && month > this.currentMonth);
  }

  isCurrentMonth(monthYear: string): boolean {
    const [year, month] = monthYear.split('-').map(Number);
    return year === this.currentYear && month === this.currentMonth;
  }

  hasExpenseHistory(): boolean {
    return Object.values(this.expensesByMonth).some(expenses => expenses.length > 0);
  }  
}
