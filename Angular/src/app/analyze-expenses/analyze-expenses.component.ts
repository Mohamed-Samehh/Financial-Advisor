import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule } from '@angular/common';
import { Chart } from 'chart.js/auto';

@Component({
  selector: 'app-analyze-expenses',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './analyze-expenses.component.html',
  styleUrl: './analyze-expenses.component.css'
})
export class AnalyzeExpensesComponent implements OnInit {
  analysis: any = {};
  chart: any;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.apiService.analyzeExpenses().subscribe((res) => {
      this.analysis = res;
      this.createChart();
    });
  }

  createChart() {
    const ctx = document.getElementById('expensesChart') as HTMLCanvasElement;

    const sortedExpenses = Object.entries(this.analysis.daily_expenses)
      .sort(([dayA], [dayB]) => parseInt(dayA) - parseInt(dayB));

    const days = sortedExpenses.map(([day]) => `Day ${day}`);

    let cumulativeExpenses: number[] = [];
    let currentBudget: number = this.analysis.monthly_budget;

    sortedExpenses.forEach(([, expense]) => {
      currentBudget -= expense as number;
      cumulativeExpenses.push(currentBudget);
    });

    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: days,
        datasets: [
          {
            label: 'Remaining Budget (After Expenses)',
            data: cumulativeExpenses,
            borderColor: '#FF6384',
            backgroundColor: 'rgba(255,99,132,0.2)',
            fill: true,
            tension: 0.1
          },
          {
            label: 'Goal Limit',
            data: Array(days.length).fill(this.analysis.goal),
            borderColor: '#36A2EB',
            borderDash: [10, 5],
            fill: false
          },
          {
            label: 'Budget Limit',
            data: Array(days.length).fill(this.analysis.monthly_budget),
            borderColor: '#4BC0C0',
            borderDash: [10, 5],
            fill: false
          },
          {
            label: 'Zero Line',
            data: Array(days.length).fill(0),
            borderColor: '#000000',
            borderDash: [5, 5],
            fill: false
          }
        ]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'top',
          }
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'Days of the Month'
            }
          },
          y: {
            title: {
              display: true,
              text: 'Amount ($)'
            }
          }
        }
      }
    });
  }
}
