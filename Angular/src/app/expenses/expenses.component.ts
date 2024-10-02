import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-expenses',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './expenses.component.html',
  styleUrls: ['./expenses.component.css']
})
export class ExpensesComponent implements OnInit {
  expenses: any[] = [];
  form: any = {};
  expenseAdded: boolean = false;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.apiService.getExpenses().subscribe((res) => {
      this.expenses = res;
    });
  }

  onSubmit() {
    this.apiService.addExpense(this.form).subscribe((res) => {
      this.expenses.push(res);
      this.form = {};
      this.expenseAdded = true;
      setTimeout(() => this.expenseAdded = false, 3000);
    });
  }
}
