import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-analyze-expenses',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './analyze-expenses.component.html',
  styleUrl: './analyze-expenses.component.css'
})
export class AnalyzeExpensesComponent implements OnInit {
  analysis: any = {};

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.apiService.analyzeExpenses().subscribe((res) => {
      this.analysis = res;
    });
  }
}
