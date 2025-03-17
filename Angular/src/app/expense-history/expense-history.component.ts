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
  expensesByYear: { [key: string]: any[] } = {};
  totalExpensesByMonth: { [key: string]: number | undefined } = {};
  budgetByMonth: { [key: string]: any } = {};
  goalByMonth: { [key: string]: any } = {};
  sortedYears: string[] = [];
  message: { text: string } | null = null;
  isLoading = true;
  currentPage = 1;
  totalPages = 1;
  yearsPerPage = 1;
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
      expenses: this.apiService.getAllExpenses(this.currentPage, this.yearsPerPage),
      budgets: this.apiService.getAllBudgets(),
      goals: this.apiService.getAllGoals(),
    }).subscribe({
      next: (res) => {
        const { expenses, budgets, goals } = res;
        const budgetsArray = budgets.budgets || [];
        const goalsArray = goals.goals || [];

        this.groupExpensesByYear(expenses.data);
        this.assignBudgetsAndGoals(budgetsArray, goalsArray);
        this.setupPagination(expenses);

        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching data:', err);
        this.message = { text: 'Failed to load data. Please try again.' };
        this.isLoading = false;
      }
    });
  }

  groupExpensesByYear(expensesByYear: any[]) {
    this.expensesByYear = {};
    this.totalExpensesByMonth = {};
    this.sortedYears = [];

    expensesByYear.forEach((yearExpenses: any[]) => {
      const year = yearExpenses[0]?.date.split('-')[0] || this.currentYear.toString();
      this.sortedYears = [year];

      yearExpenses.forEach(expense => {
        const expenseDate = new Date(expense.date);
        const month = expenseDate.getMonth() + 1;
        const monthYear = `${year}-${String(month).padStart(2, '0')}`;

        if (this.isCurrentMonth(monthYear)) {
          this.totalExpensesByMonth[monthYear] = undefined;
        } else {
          if (!this.expensesByYear[year]) {
            this.expensesByYear[year] = [];
          }
          this.expensesByYear[year].push(expense);

          if (!this.totalExpensesByMonth[monthYear]) {
            this.totalExpensesByMonth[monthYear] = 0;
          }
          this.totalExpensesByMonth[monthYear]! += expense.amount;
        }
      });
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

  setupPagination(expensesResponse: any) {
    this.currentPage = expensesResponse.current_page;
    this.totalPages = expensesResponse.last_page;
    this.pages = Array.from({ length: this.totalPages }, (_, i) => i + 1);
  }

  getMonthsForCurrentPage(): string[] {
    const currentYear = this.sortedYears[0] || this.currentYear.toString();
    return Array.from({ length: 12 }, (_, i) => 
      `${currentYear}-${String(i + 1).padStart(2, '0')}`
    );
  }

  filterByMonth(expenses: any[], monthYear: string): any[] {
    if (!expenses || !monthYear || this.isCurrentMonth(monthYear)) return [];
    
    const [year, month] = monthYear.split('-').map(Number);
    return expenses.filter(expense => {
      const expenseDate = new Date(expense.date);
      return expenseDate.getFullYear() === year && 
             (expenseDate.getMonth() + 1) === month;
    });
  }

  goToPage(page: number) {
    this.currentPage = page;
    this.loadExpenseHistory();
  }

  previousPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.loadExpenseHistory();
    }
  }

  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.loadExpenseHistory();
    }
  }

  formatNumber(value: number): string {
    return this.decimalPipe.transform(value, '1.0-0') || '0';
  }

  Expense_summary(monthYear: string): string {
    if (this.isCurrentMonth(monthYear)) return '';

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
    return this.sortedYears[0] || this.currentYear.toString();
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
    return Object.values(this.expensesByYear).some(expenses => expenses.length > 0);
  }
}
