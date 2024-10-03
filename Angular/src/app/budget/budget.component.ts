import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-budget',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './budget.component.html',
  styleUrls: ['./budget.component.css'],
})
export class BudgetComponent implements OnInit {
  budget: any = { id: null, monthly_budget: null };
  message: { text: string; type: 'success' | 'error' } | null = null;
  submitted: boolean = false;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadBudget();
  }

  loadBudget() {
    this.apiService.getBudget().subscribe(
      (res) => {
        this.budget = res.budget ? { id: res.budget.id, monthly_budget: res.budget.monthly_budget } : { id: null, monthly_budget: null };
      },
      (err) => {
        console.error('Failed to load budget', err);
      }
    );
  }

  onSubmit(budgetForm: any) {
    this.submitted = true;

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
    }
  }

  deleteBudget(budgetId: any) {
    if (confirm('Are you sure you want to delete this budget?')) {
      this.apiService.deleteBudget(budgetId).subscribe(
        (res) => {
          this.budget = { id: null, monthly_budget: null };
          this.message = { text: 'Budget deleted successfully!', type: 'success' };
        },
        (err) => {
          console.error('Failed to delete budget', err);
          this.message = { text: 'Error deleting budget. Please try again.', type: 'error' };
        }
      );
    }
  }
}
