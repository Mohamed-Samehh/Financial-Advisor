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
  budget: any = {};
  form: any = {};
  budgetSaved: boolean = false;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.apiService.getBudget().subscribe((res) => (this.budget = res));
  }

  onSubmit() {
    this.apiService.addBudget(this.form).subscribe(
      (res) => {
        this.budget = res;
        this.budgetSaved = true;
        this.form = {};
      },
      (error) => {
        console.error('Error saving budget', error);
        this.budgetSaved = false;
      }
    );
  }
}
