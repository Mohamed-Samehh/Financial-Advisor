import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule, DecimalPipe } from '@angular/common';

@Component({
  selector: 'app-goals',
  standalone: true,
  imports: [FormsModule, CommonModule],
  providers: [DecimalPipe],
  templateUrl: './goals.component.html',
  styleUrls: ['./goals.component.css'],
})
export class GoalsComponent implements OnInit {
  goal: any = { id: null, name: '', target_amount: null };
  message: { text: string; type: 'success' | 'error' } | null = null;
  submitted: boolean = false;
  isLoading: boolean = true;
  budget: number | null = null;

  constructor(private apiService: ApiService, private decimalPipe: DecimalPipe) {}

  ngOnInit() {
    this.loadBudgetAndGoal();
  }

  loadBudgetAndGoal() {
    this.apiService.getBudget().subscribe(
      (res) => {
        this.budget = res.budget ? res.budget.monthly_budget : null;
        this.loadGoal();
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

  onSubmit(goalForm: any) {
    this.submitted = true;
    this.message = null;

    if (!this.budget) {
      this.message = { text: 'Please set a budget before setting a goal.', type: 'error' };
      return;
    }

    // Check if the goal is less than 100% of the budget
    if (this.goal.target_amount >= this.budget) {
      this.message = { text: 'Goal cannot be equal or more than the budget.', type: 'error' };
      return;
    }

    if (goalForm.valid) {
      this.isLoading = true;
      if (this.goal.id) {
        this.apiService.updateGoal(this.goal, this.goal.id).subscribe(
          (res) => {
            this.goal = { ...this.goal, ...res.goal };
            this.message = { text: 'Goal updated successfully!', type: 'success' };
            this.isLoading = false;
          },
          (err) => {
            console.error('Failed to update goal', err);
            this.message = { text: 'Error updating goal. Please try again.', type: 'error' };
            this.isLoading = false;
          }
        );
      } else {
        this.apiService.addGoal(this.goal).subscribe(
          (res) => {
            this.goal = res.goal;
            this.message = { text: 'Goal set successfully!', type: 'success' };
            this.isLoading = false;
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
        this.goal = { id: null, name: '', target_amount: null };
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
}
