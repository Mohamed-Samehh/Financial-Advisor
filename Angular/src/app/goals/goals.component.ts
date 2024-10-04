import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-goals',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './goals.component.html',
  styleUrls: ['./goals.component.css'],
})
export class GoalsComponent implements OnInit {
  goal: any = { id: null, name: '', target_amount: null };
  message: { text: string; type: 'success' | 'error' } | null = null;
  submitted: boolean = false;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadGoal();
  }

  loadGoal() {
    this.apiService.getGoal().subscribe(
      (res) => {
        this.goal = res.goal ? { id: res.goal.id, name: res.goal.name, target_amount: res.goal.target_amount } : { id: null, name: '', target_amount: null };
      },
      (err) => {
        console.error('Failed to load goal', err);
      }
    );
  }

  onSubmit(goalForm: any) {
    this.submitted = true;

    if (goalForm.valid) {
      if (this.goal.id) {
        // Update the existing goal
        this.apiService.updateGoal(this.goal, this.goal.id).subscribe(
          (res) => {
            this.goal = { ...this.goal, ...res.goal };
            this.message = { text: 'Goal updated successfully!', type: 'success' };
          },
          (err) => {
            console.error('Failed to update goal', err);
            this.message = { text: 'Error updating goal. Please try again.', type: 'error' };
          }
        );
      } else {
        // Add a new goal
        this.apiService.addGoal(this.goal).subscribe(
          (res) => {
            this.goal = res.goal;
            this.message = { text: 'Goal set successfully!', type: 'success' };
          },
          (err) => {
            console.error('Failed to add goal', err);
            this.message = { text: 'Error adding goal. Please try again.', type: 'error' };
          }
        );
      }
    }
  }

  deleteGoal(goalId: any) {
    this.apiService.deleteGoal(goalId).subscribe(
      (res) => {
        this.goal = { id: null, name: '', target_amount: null };
        this.message = { text: 'Goal deleted successfully!', type: 'success' };
      },
      (err) => {
        console.error('Failed to delete goal', err);
        this.message = { text: 'Error deleting goal. Please try again.', type: 'error' };
      }
    );
  }
}
