import { Component, OnInit, ViewChild, ElementRef } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import Swal from 'sweetalert2';

interface ExpenseSummary {
  totalExpenses: number;
  categoryTotals: { [key: string]: number };
  dailyAverage: number;
  highestExpense: number;
  highestCategory: string;
}

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
  allExpenses: any[] = [];
  sortKey: 'date' | 'amount' = 'date';
  form: any = {};
  message: { text: string; type: 'success' | 'error' } | null = null;
  budgetSubmitted: boolean = false;
  goalSubmitted: boolean = false;
  expenseSubmitted: boolean = false;
  minDate: string;
  maxDate: string;
  isLoading: boolean = false;
  currentPage: number = 1;
  itemsPerPage: number = 12;
  paginatedExpenses: any[] = [];
  totalPages: number = 0;
  pages: number[] = [];
  categories: string[] = [];
  editingExpenseId: number | null = null;
  isEditing: boolean = false;
  selectedCategory: string = 'all';
  budget: any = { id: null, monthly_budget: 0 };
  goal: any = { id: null, name: '', target_amount: 0 };
  monthlyBudget: number = 0;
  budgetRemaining: number = 0;
  budgetPercentUsed: number = 0;
  savedAmount: number = 0;
  maxSpendLimit: number = 0;
  expenseSummary: ExpenseSummary = {
    totalExpenses: 0,
    categoryTotals: {},
    dailyAverage: 0,
    highestExpense: 0,
    highestCategory: '',
  };
  showAnalytics: boolean = false;
  showBudgetForm: boolean = false;
  showGoalForm: boolean = false;
  
  @ViewChild('budgetInput') budgetInput!: ElementRef;
  @ViewChild('categoryInput') categoryInput!: ElementRef;
  @ViewChild('goalNameInput') goalNameInput!: ElementRef;

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
    this.loadBudgetAndGoal();
  }

  getCategoryColor(categoryName: string): string {
    switch(categoryName) {
      case 'Rent & Utilities':
        return '#4caf50'; // Green
      case 'Groceries':
        return '#ff9800'; // Orange
      case 'Shopping':
        return '#e53935'; // Red
      case 'Social Activities & Entertainments':
        return '#03a9f4'; // Blue
      case 'Transportation':
        return '#9c27b0'; // Purple
      case 'Other':
        return '#607d8b'; // Blue-gray
      default:
        return '#6C63FF'; // Default purple
    }
  }

  loadBudgetAndGoal() {
    this.isLoading = true;
    this.apiService.getBudget().subscribe(
      (res) => {
        this.budget = res.budget ? { id: res.budget.id, monthly_budget: res.budget.monthly_budget } : { id: null, monthly_budget: 0 };
        this.monthlyBudget = this.budget.monthly_budget || 0;
        this.loadGoal();
      },
      (err) => {
        console.error('Failed to load budget', err);
        this.isLoading = false;
      }
    );
  }

  loadGoal() {
    this.apiService.getGoal().subscribe(
      (res) => {
        this.goal = res.goal ? { id: res.goal.id, name: res.goal.name, target_amount: res.goal.target_amount } : { id: null, name: '', target_amount: 0 };
        this.calculateBudget();
        this.isLoading = false;
      },
      (err) => {
        console.error('Failed to load goal', err);
        this.calculateBudget();
        this.isLoading = false;
      }
    );
  }

  loadExpenses() {
    this.isLoading = true;
    this.apiService.getExpenses().subscribe({
      next: (res) => {
        this.expenses = res.expenses || [];
        this.allExpenses = [...this.expenses];
        
        this.sortExpenses();
        this.totalPages = Math.ceil(this.expenses.length / this.itemsPerPage);
        this.updatePaginatedExpenses();
        this.updatePageNumbers();
        this.calculateSummary();
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

  sortExpenses() {
    this.expenses.sort((a, b) => {
      if (this.sortKey === 'date') {
        return new Date(b.date).getTime() - new Date(a.date).getTime();
      }
      if (this.sortKey === 'amount') {
        return b.amount - a.amount;
      }
      return 0;
    });
    this.updatePaginatedExpenses();
  }

  formatNumber(value: number): string {
    const formattedValue = this.decimalPipe.transform(value, '1.0-0');
    return formattedValue !== null ? formattedValue : '0';
  }

  focusCategoryInput() {
    if (this.categoryInput) {
      this.categoryInput.nativeElement.focus();
    }
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

  resetFilters() {
    this.selectedCategory = 'all';
    this.sortKey = 'date';
    this.currentPage = 1;
    this.expenses = [...this.allExpenses];
    this.totalPages = Math.ceil(this.expenses.length / this.itemsPerPage);
    this.updatePaginatedExpenses();
    this.updatePageNumbers();
  }

  onSubmit(expenseForm: any) {
    this.expenseSubmitted = true;

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
            this.expenseSubmitted = false;
            this.editingExpenseId = null;
            this.isEditing = false;
            this.loadExpenses();
            this.isLoading = false;
            this.resetFilters();
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
        this.allExpenses.unshift(tempExpense);
        this.resetFilters();
        this.updatePaginatedExpenses();
        this.calculateSummary();

        this.apiService.addExpense(tempExpense).subscribe({
          next: (res) => {
            this.message = { text: 'Expense added successfully!', type: 'success' };
            expenseForm.resetForm();
            this.form = {};
            this.expenseSubmitted = false;
            this.isLoading = false;
          },
          error: (err) => {
            console.error('Failed to add expense', err);
            this.expenses.shift();
            this.allExpenses.shift();
            this.updatePaginatedExpenses();
            this.calculateSummary();
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

  async deleteExpense(expenseId: any) {
    const expense = this.expenses.find(exp => exp.id === expenseId);
    if (expense?.isRecentlyAdded) return;

    const result = await Swal.fire({
      title: "Are you sure?",
      text: "You won't be able to revert this!",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#3085d6",
      cancelButtonColor: "#d33",
      confirmButtonText: "Yes, delete it!"
    });

    if (!result.isConfirmed) return;

    this.isLoading = true;
    this.apiService.deleteExpense(expenseId).subscribe({
      next: () => {
        this.allExpenses = this.allExpenses.filter(expense => expense.id !== expenseId);
        
        this.resetFilters();
        
        this.calculateSummary();
        this.calculateBudget();
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

  filterByCategory() {
    if (this.selectedCategory === 'all') {
      this.expenses = [...this.allExpenses];
    } else {
      this.expenses = this.allExpenses.filter(expense => expense.category === this.selectedCategory);
    }
    
    this.sortExpenses();
    
    this.totalPages = Math.ceil(this.expenses.length / this.itemsPerPage);
    this.currentPage = 1;
    this.updatePaginatedExpenses();
    this.updatePageNumbers();
  }

  calculateSummary() {
    this.expenseSummary = {
      totalExpenses: 0,
      categoryTotals: {},
      dailyAverage: 0,
      highestExpense: 0,
      highestCategory: ''
    };

    if (this.allExpenses.length === 0) return;

    this.expenseSummary.totalExpenses = this.allExpenses.reduce((sum, expense) => sum + expense.amount, 0);

    this.allExpenses.forEach(expense => {
      if (!this.expenseSummary.categoryTotals[expense.category]) {
        this.expenseSummary.categoryTotals[expense.category] = 0;
      }
      this.expenseSummary.categoryTotals[expense.category] += expense.amount;
    });

    let maxCategoryAmount = 0;
    for (const [category, total] of Object.entries(this.expenseSummary.categoryTotals)) {
      if (total > maxCategoryAmount) {
        maxCategoryAmount = total as number;
        this.expenseSummary.highestCategory = category;
      }
    }

    this.expenseSummary.highestExpense = Math.max(...this.allExpenses.map(expense => expense.amount));

    if (this.allExpenses.length > 0) {
      const sortedExpenses = [...this.allExpenses].sort((a, b) => 
        new Date(b.date).getTime() - new Date(a.date).getTime()
      );
      
      const latestExpense = sortedExpenses[0];
      const latestDate = new Date(latestExpense.date);
      
      const dayOfMonth = latestDate.getDate();
      
      this.expenseSummary.dailyAverage = this.expenseSummary.totalExpenses / dayOfMonth;
    } else {
      this.expenseSummary.dailyAverage = 0;
    }
    
    // Update budget calculations after summary is updated
    this.calculateBudget();
  }

  calculateBudget() {
    if (this.monthlyBudget > 0) {
      this.budgetRemaining = this.monthlyBudget - this.expenseSummary.totalExpenses;
      this.budgetPercentUsed = (this.expenseSummary.totalExpenses / this.monthlyBudget) * 100;
      
      // For goal-related calculations
      if (this.goal.id && this.goal.target_amount > 0) {
        // Calculate the maximum spend limit to meet the savings goal
        this.maxSpendLimit = this.monthlyBudget - this.goal.target_amount;
        this.savedAmount = Math.max(0, this.budgetRemaining);
      } else {
        this.maxSpendLimit = this.monthlyBudget;
        this.savedAmount = 0;
      }
    } else {
      this.budgetRemaining = 0;
      this.budgetPercentUsed = 0;
      this.maxSpendLimit = 0;
      this.savedAmount = 0;
    }
  }

  toggleAnalytics() {
    this.showAnalytics = !this.showAnalytics;
  }

  toggleBudgetForm() {
    this.showBudgetForm = !this.showBudgetForm;
    if (this.showBudgetForm) {
      this.showGoalForm = false;
    }
  }

  toggleGoalForm() {
    this.showGoalForm = !this.showGoalForm;
    if (this.showGoalForm) {
      this.showBudgetForm = false;
    }
  }

  onSubmitBudget(budgetForm: any) {
    this.budgetSubmitted = true;
    this.message = null;

    if (budgetForm.valid) {
      this.isLoading = true;

      // Check if goal exists and budget is less than the goal
      if (this.goal.id && this.goal.target_amount && this.budget.monthly_budget < this.goal.target_amount) {
        this.deleteGoal(this.goal.id);
      }

      if (this.budget.id) {
        // Update existing budget
        this.apiService.updateBudget(this.budget, this.budget.id).subscribe(
          (res) => {
            this.budget = { ...this.budget, ...res.budget };
            this.monthlyBudget = this.budget.monthly_budget;
            this.calculateBudget();
            this.message = { text: 'Budget updated successfully!', type: 'success' };
            this.isLoading = false;
            this.showBudgetForm = false;
          },
          (err) => {
            console.error('Failed to update budget', err);
            this.message = { text: 'Error updating budget. Please try again.', type: 'error' };
            this.isLoading = false;
          }
        );
      } else {
        // Add new budget
        this.apiService.addBudget(this.budget).subscribe(
          (res) => {
            this.budget = res.budget;
            this.monthlyBudget = this.budget.monthly_budget;
            this.calculateBudget();
            this.message = { text: 'Budget set successfully!', type: 'success' };
            this.isLoading = false;
            this.showBudgetForm = false;
          },
          (err) => {
            console.error('Failed to add budget', err);
            this.message = { text: 'Error adding budget. Please try again.', type: 'error' };
            this.isLoading = false;
          }
        );
      }
    } else {
      this.message = { text: 'Please fill in all required fields correctly.', type: 'error' };
    }
  }

  deleteBudget(budgetId: any) {
    this.isLoading = true;

    this.apiService.deleteBudget(budgetId).subscribe(
      (res) => {
        if (this.goal.id) {
          this.deleteGoal(this.goal.id);
        }
        this.budget = { id: null, monthly_budget: 0 };
        this.monthlyBudget = 0;
        this.calculateBudget();
        this.message = { text: 'Budget deleted successfully!', type: 'success' };
        this.isLoading = false;
      },
      (err) => {
        console.error('Failed to delete budget', err);
        this.message = { text: 'Error deleting budget. Please try again.', type: 'error' };
        this.isLoading = false;
      }
    );
  }

  onSubmitGoal(goalForm: any) {
    this.goalSubmitted = true;
    this.message = null;

    if (!this.budget.id) {
      this.message = { text: 'Please set a budget before setting a goal.', type: 'error' };
      return;
    }

    // Check if the goal target is less than the budget
    if (this.goal.target_amount >= this.monthlyBudget) {
      this.message = { text: 'Goal cannot be equal or more than the budget.', type: 'error' };
      return;
    }

    if (goalForm.valid) {
      this.isLoading = true;
      if (this.goal.id) {
        // Update existing goal
        this.apiService.updateGoal(this.goal, this.goal.id).subscribe(
          (res) => {
            this.goal = { ...this.goal, ...res.goal };
            this.calculateBudget();
            this.message = { text: 'Goal updated successfully!', type: 'success' };
            this.isLoading = false;
            this.showGoalForm = false;
          },
          (err) => {
            console.error('Failed to update goal', err);
            this.message = { text: 'Error updating goal. Please try again.', type: 'error' };
            this.isLoading = false;
          }
        );
      } else {
        // Add new goal
        this.apiService.addGoal(this.goal).subscribe(
          (res) => {
            this.goal = res.goal;
            this.calculateBudget();
            this.message = { text: 'Goal set successfully!', type: 'success' };
            this.isLoading = false;
            this.showGoalForm = false;
          },
          (err) => {
            console.error('Failed to add goal', err);
            this.message = { text: 'Error adding goal. Please try again.', type: 'error' };
            this.isLoading = false;
          }
        );
      }
    } else {
      this.message = { text: 'Please fill in all required fields correctly.', type: 'error' };
    }
  }

  deleteGoal(goalId: any) {
    this.isLoading = true;
    this.apiService.deleteGoal(goalId).subscribe(
      (res) => {
        this.goal = { id: null, name: '', target_amount: 0 };
        this.calculateBudget();
        this.message = { text: 'Goal deleted successfully!', type: 'success' };
        this.isLoading = false;
      },
      (err) => {
        console.error('Failed to delete goal', err);
        this.message = { text: 'Error deleting goal. Please try again.', type: 'error' };
        this.isLoading = false;
      }
    );
  }

  generatePDFReport() {
    this.message = { text: 'Generating PDF report...', type: 'success' };
    
    try {
      const pdfContent = `
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Expense Report</title>
            <style>
              @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
              :root {
                --primary: #0d6efd;
                --primary-light: rgba(13, 110, 253, 0.1);
                --secondary: #6c757d;
                --success: #198754;
                --danger: #dc3545;
                --dark: #212529;
                --light: #f8f9fa;
                --border: #dee2e6;
                --shadow: 0 5px 15px rgba(0,0,0,0.05);
              }
              * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
              }
              body {
                font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
                line-height: 1.6;
                color: var(--dark);
                background-color: white;
                padding: 40px;
                max-width: 1200px;
                margin: 0 auto;
              }
              .container {
                background-color: white;
                border-radius: 12px;
                overflow: hidden;
                box-shadow: var(--shadow);
              }
              .header {
                padding: 30px 40px;
                background: linear-gradient(135deg, var(--primary), #0b5ed7);
                color: white;
                position: relative;
                overflow: hidden;
              }
              .header::before {
                content: '';
                position: absolute;
                top: -50%;
                right: -50%;
                width: 100%;
                height: 200%;
                background: rgba(255,255,255,0.1);
                transform: rotate(30deg);
                pointer-events: none;
              }
              .report-title {
                font-size: 32px;
                font-weight: 700;
                margin-bottom: 5px;
                letter-spacing: -0.5px;
              }
              .report-subtitle {
                font-size: 16px;
                font-weight: 400;
                opacity: 0.9;
              }
              .content {
                padding: 40px;
              }
              .section {
                margin-bottom: 40px;
              }
              .section-title {
                font-size: 22px;
                font-weight: 600;
                margin-bottom: 20px;
                color: var(--dark);
                position: relative;
                padding-bottom: 10px;
              }
              .section-title::after {
                content: '';
                position: absolute;
                bottom: 0;
                left: 0;
                width: 50px;
                height: 3px;
                background-color: var(--primary);
                border-radius: 3px;
              }
              .summary-grid {
                display: flex;
                flex-wrap: wrap;
                gap: 20px;
                margin-bottom: 30px;
              }
              .summary-grid .summary-card {
                flex: 1;
                min-width: 200px;
              }
              .summary-card {
                background-color: white;
                border-radius: 10px;
                box-shadow: var(--shadow);
                padding: 20px;
                border-left: 4px solid var(--primary);
                transition: transform 0.3s ease;
              }
              .summary-card:hover {
                transform: translateY(-5px);
              }
              .summary-label {
                font-size: 14px;
                font-weight: 500;
                color: var(--secondary);
                margin-bottom: 8px;
              }
              .summary-value {
                font-size: 24px;
                font-weight: 600;
                color: var(--dark);
              }
              .summary-unit {
                font-size: 16px;
                font-weight: 400;
                color: var(--secondary);
              }
              .category-breakdown {
                margin-top: 40px;
              }
              table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 30px;
                box-shadow: var(--shadow);
                border-radius: 10px;
                overflow: hidden;
              }
              thead {
                background-color: var(--primary);
                color: white;
              }
              th {
                font-weight: 600;
                text-align: left;
                padding: 15px 20px;
                font-size: 14px;
                letter-spacing: 0.5px;
                text-transform: uppercase;
              }
              td {
                padding: 15px 20px;
                border-bottom: 1px solid var(--border);
                font-size: 14px;
              }
              tr:last-child td {
                border-bottom: none;
              }
              tr:nth-child(even) {
                background-color: rgba(0,0,0,0.02);
              }
              .amount {
                font-weight: 600;
                font-family: 'Inter', monospace;
              }
              .category-badge {
                display: inline-block;
                padding: 5px 10px;
                border-radius: 99px;
                font-size: 12px;
                font-weight: 500;
                background-color: var(--primary-light);
                color: var(--primary);
              }
              .footer {
                border-top: 1px solid var(--border);
                padding: 20px 40px;
                display: flex;
                justify-content: space-between;
                align-items: center;
                font-size: 13px;
                color: var(--secondary);
              }
              .budget-status {
                margin-top: 20px;
                background: var(--light);
                border-radius: 10px;
                padding: 25px;
              }
              .budget-header {
                display: flex;
                align-items: center;
                margin-bottom: 15px;
              }
              .budget-header i {
                color: var(--primary);
                margin-right: 10px;
                font-size: 20px;
              }
              .budget-header h3 {
                font-size: 18px;
                margin: 0;
              }
              .progress-container {
                width: 100%;
                height: 24px;
                background-color: #e9ecef;
                border-radius: 99px;
                margin-bottom: 15px;
                overflow: hidden;
              }
              .progress-bar {
                height: 100%;
                border-radius: 99px;
                text-align: center;
                font-size: 14px;
                font-weight: 600;
                color: white;
                padding-top: 3px;
              }
              .progress-success {
                background-color: var(--success);
              }
              .progress-warning {
                background-color: #ffc107;
              }
              .progress-danger {
                background-color: var(--danger);
              }
              .budget-details {
                display: flex;
                justify-content: space-between;
                font-size: 14px;
              }
              .budget-amounts {
                display: flex;
                justify-content: space-between;
                margin-top: 15px;
              }
              .budget-amount-item {
                display: flex;
                align-items: center;
              }
              .budget-amount-item i {
                margin-right: 8px;
              }
              .budget-amount-value {
                font-weight: 600;
                font-size: 16px;
                margin-left: 5px;
              }
              .savings-info {
                margin-top: 20px;
              }
              .logo {
                font-weight: 800;
                font-size: 16px;
                color: var(--primary);
                letter-spacing: -0.5px;
              }
              /* Improved styling for the savings goal section */
              .savings-info {
                margin-top: 20px;
                padding: 20px;
                background-color: var(--light);
                border-radius: 10px;
              }
              .savings-info h3 {
                font-size: 18px;
                margin-bottom: 10px;
              }
              .savings-info p {
                margin-bottom: 5px;
              }
              .savings-info .warning {
                color: var(--danger);
                font-weight: 600;
              }
              @media print {
                body {
                  padding: 0;
                }
                .container {
                  box-shadow: none;
                }
              }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1 class="report-title">Expense Report</h1>
                <p class="report-subtitle">Generated on ${new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
              </div>
              <div class="content">
                <div class="section">
                  <h2 class="section-title">Financial Summary</h2>
                  <div class="summary-grid">
                    <div class="summary-card">
                      <div class="summary-label">Total Expenses</div>
                      <div class="summary-value">E£${this.formatNumber(this.expenseSummary.totalExpenses)}</div>
                    </div>
                    <div class="summary-card">
                      <div class="summary-label">Monthly Budget</div>
                      <div class="summary-value">E£${this.formatNumber(this.monthlyBudget)}</div>
                    </div>
                    <div class="summary-card">
                      <div class="summary-label">Remaining Budget</div>
                      <div class="summary-value" style="color: ${this.budgetRemaining < 0 ? 'var(--danger)' : 'inherit'}">
                        E£${this.formatNumber(this.budgetRemaining)}
                      </div>
                    </div>
                    <div class="summary-card">
                      <div class="summary-label">Daily Average</div>
                      <div class="summary-value">E£${this.formatNumber(this.expenseSummary.dailyAverage)}</div>
                    </div>
                  </div>
                  <div class="budget-status">
                    <div class="budget-header">
                      <i class="fas fa-chart-pie"></i>
                      <h3>Budget Status</h3>
                    </div>
                    <div class="progress-container">
                      <div class="progress-bar ${
                        this.budgetPercentUsed < 75 ? 'progress-success' : 
                        this.budgetPercentUsed < 100 ? 'progress-warning' : 
                        'progress-danger'
                      }" style="width: ${Math.min(this.budgetPercentUsed, 100)}%">
                        ${this.formatNumber(this.budgetPercentUsed)}%
                      </div>
                    </div>
                    <div class="budget-amounts">
                      <div class="budget-amount-item">
                        <i class="fas fa-shopping-cart"></i>
                        <span>Spent:</span>
                        <span class="budget-amount-value">E£${this.formatNumber(this.expenseSummary.totalExpenses)}</span>
                      </div>
                      <div class="budget-amount-item">
                        <i class="fas fa-piggy-bank"></i>
                        <span>Remaining:</span>
                        <span class="budget-amount-value" style="color: ${this.budgetRemaining < 0 ? 'var(--danger)' : 'inherit'}">
                          E£${this.formatNumber(this.budgetRemaining)}
                        </span>
                      </div>
                    </div>
                  </div>
                  ${this.goal.id ? `
                  <div class="savings-info">
                    <div class="budget-header">
                      <i class="fas fa-bullseye"></i>
                      <h3>Savings Goal: ${this.goal.name}</h3>
                    </div>
                    <p><strong>Target Amount:</strong> E£${this.formatNumber(this.goal.target_amount)}</p>
                    <p><strong>Spending Limit:</strong> To reach your savings goal, you should spend no more than <strong>E£${this.formatNumber(this.maxSpendLimit)}</strong> this month.</p>
                    ${this.expenseSummary.totalExpenses > this.maxSpendLimit ? 
                      `<p class="warning">You've already exceeded this limit by <strong>E£${this.formatNumber(this.expenseSummary.totalExpenses - this.maxSpendLimit)}</strong></p>` : ''
                    }
                  </div>
                  ` : ''}
                  <div class="category-breakdown">
                    <h3 style="font-size: 18px; margin-bottom: 15px;">Category Breakdown</h3>
                    <table>
                      <thead>
                        <tr>
                          <th>Category</th>
                          <th>Amount</th>
                          <th>Percentage</th>
                        </tr>
                      </thead>
                      <tbody>
                        ${Object.entries(this.expenseSummary.categoryTotals).map(([category, amount]) => `
                          <tr>
                            <td>
                              <span class="category-badge" style="background-color: ${this.getCategoryColor(category)}20; color: ${this.getCategoryColor(category)}">
                                ${category}
                              </span>
                            </td>
                            <td class="amount">E£${this.formatNumber(amount as number)}</td>
                            <td>${this.formatNumber(((amount as number) / this.expenseSummary.totalExpenses) * 100)}%</td>
                          </tr>
                        `).join('')}
                      </tbody>
                    </table>
                  </div>
                </div>
                <div class="section">
                  <h2 class="section-title">Transaction History</h2>
                  <table>
                    <thead>
                      <tr>
                        <th>Date</th>
                        <th>Category</th>
                        <th>Description</th>
                        <th>Amount</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${this.allExpenses.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()).map(expense => `
                        <tr>
                          <td>${new Date(expense.date).toLocaleDateString()}</td>
                          <td>
                            <span class="category-badge" style="background-color: ${this.getCategoryColor(expense.category)}20; color: ${this.getCategoryColor(expense.category)}">
                              ${expense.category}
                            </span>
                          </td>
                          <td>${expense.description || 'No description'}</td>
                          <td class="amount">E£${this.formatNumber(expense.amount)}</td>
                        </tr>
                      `).join('')}
                    </tbody>
                  </table>
                </div>
              </div>
              <div class="footer">
                <div class="logo">Financial Advisor</div>
                <div>Generated on ${new Date().toLocaleString()}</div>
              </div>
            </div>
          </body>
        </html>
      `;
  
      const blob = new Blob([pdfContent], { type: 'application/pdf' });
      const documentTitle = `Expense_Report_${new Date().toISOString().slice(0, 10)}`;
      
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = documentTitle + '.html';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      this.message = { text: 'Expense report downloaded successfully!', type: 'success' };
      
      Swal.fire({
        title: 'Report Downloaded',
        html: 'Your expense report has been downloaded as an HTML file.',
        icon: 'success',
        confirmButtonText: 'Got it!'
      });
    } catch (error) {
      console.error('Error generating report:', error);
      this.message = { text: 'Error generating expense report. Please try again.', type: 'error' };
      
      Swal.fire({
        title: 'Error',
        text: 'Failed to generate expense report. Please try again.',
        icon: 'error',
        confirmButtonText: 'OK'
      });
    }
  }
}