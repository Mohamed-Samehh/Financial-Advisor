import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule, DecimalPipe } from '@angular/common';

@Component({
  selector: 'app-budget',
  standalone: true,
  imports: [FormsModule, CommonModule],
  providers: [DecimalPipe],
  templateUrl: './budget.component.html',
  styleUrls: ['./budget.component.css'],
})
export class BudgetComponent implements OnInit {
  budget: any = { id: null, monthly_budget: null };
  goal: any = { id: null, name: '', target_amount: null };
  message: { text: string; type: 'success' | 'error' } | null = null;
  submitted: boolean = false;
  isLoading: boolean = true;

  constructor(private apiService: ApiService, private decimalPipe: DecimalPipe) {}

  ngOnInit() {
    this.loadBudgetAndGoal();
  }

  loadBudgetAndGoal() {
    this.apiService.getBudget().subscribe(
      (res) => {
        this.budget = res.budget ? { id: res.budget.id, monthly_budget: res.budget.monthly_budget } : { id: null, monthly_budget: null };
        if (this.budget.id) {
          this.loadGoal();
        } else {
          this.isLoading = false;
        }
      },
      (err) => {
        console.error('Failed to load budget', err);
        this.isLoading = false;
      }
    );
  }

  formatNumber(value: number): string {
    const formattedValue = this.decimalPipe.transform(value, '1.0-0');
    return formattedValue !== null ? formattedValue : '0';
  }

  loadGoal() {
    this.apiService.getGoal().subscribe(
      (res) => {
        this.goal = res.goal ? { id: res.goal.id, name: res.goal.name, target_amount: res.goal.target_amount } : { id: null, name: '', target_amount: null };
        this.isLoading = false;
      },
      (err) => {
        console.error('Failed to load goal', err);
        this.isLoading = false;
      }
    );
  }

  onSubmit(budgetForm: any) {
    this.submitted = true;
    this.message = null;

    if (budgetForm.valid) {
      if (this.budget.id) {
        // Update the existing budget
        this.apiService.updateBudget(this.budget, this.budget.id).subscribe(
          (res) => {
            this.budget = { ...this.budget, ...res.budget };
            this.message = { text: 'Budget updated successfully!', type: 'success' };
          },
          (err) => {
            console.error('Failed to update budget', err);
            this.message = { text: 'Error updating budget. Please try again.', type: 'error' };
          }
        );
      } else {
        // Add a new budget
        this.apiService.addBudget(this.budget).subscribe(
          (res) => {
            this.budget = res.budget;
            this.message = { text: 'Budget set successfully!', type: 'success' };
          },
          (err) => {
            console.error('Failed to add budget', err);
            this.message = { text: 'Error adding budget. Please try again.', type: 'error' };
          }
        );
      }
    } else {
      this.message = { text: 'Please fill in all required fields correctly.', type: 'error' };
    }
  }

  deleteBudget(budgetId: any) {
    this.apiService.deleteBudget(budgetId).subscribe(
      (res) => {
        if (this.goal.id) {
          this.deleteGoal(this.goal.id);
        }
        this.budget = { id: null, monthly_budget: null };
        this.message = { text: 'Budget deleted successfully!', type: 'success' };
      },
      (err) => {
        console.error('Failed to delete budget', err);
        this.message = { text: 'Error deleting budget. Please try again.', type: 'error' };
      }
    );
  }

  deleteGoal(goalId: any) {
    this.apiService.deleteGoal(goalId).subscribe(
      (res) => {
        this.goal = { id: null, name: '', target_amount: null };
      },
      (err) => {
        console.error('Failed to delete goal', err);
      }
    );
  }

}
