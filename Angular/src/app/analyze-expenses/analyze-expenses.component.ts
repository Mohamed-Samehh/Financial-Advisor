import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { Chart } from 'chart.js/auto';

@Component({
  selector: 'app-analyze-expenses',
  standalone: true,
  imports: [CommonModule],
  providers: [DecimalPipe],
  templateUrl: './analyze-expenses.component.html',
  styleUrls: ['./analyze-expenses.component.css']
})
export class AnalyzeExpensesComponent implements OnInit {
  analysis: any = {};
  chart: any;
  categoryChart: any;
  isLoading: boolean = true;
  errorMessage: string | null = null;

  constructor(private apiService: ApiService, private decimalPipe: DecimalPipe) {}

  ngOnInit() {
    this.apiService.analyzeExpenses().subscribe((res) => {
      this.analysis = res;
      this.createChart();
      this.isLoading = false;
    });

    this.apiService.getExpenses().subscribe(
      (response) => {
        if (Array.isArray(response.expenses)) {
          this.createPieChart(response.expenses);
        }
        this.isLoading = false;
      },
      (error) => {
        this.errorMessage = 'Failed to load expenses.';
        this.isLoading = false;
      }
    );
  }

  formatNumber(value: number): string {
    const formattedValue = this.decimalPipe.transform(value, '1.0-0');
    return formattedValue !== null ? formattedValue : '0';
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
            label: 'Remaining Budget',
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

  createPieChart(expenses: any[]) {
    const ctx = document.getElementById('categoryChart') as HTMLCanvasElement;

    const categoryMap = new Map<string, number>();

    expenses.forEach((expense: any) => {
      if (categoryMap.has(expense.category)) {
        categoryMap.set(expense.category, categoryMap.get(expense.category)! + expense.amount);
      } else {
        categoryMap.set(expense.category, expense.amount);
      }
    });

    const categories = Array.from(categoryMap.keys());
    const amounts = Array.from(categoryMap.values());

    this.categoryChart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: categories,
        datasets: [{
          data: amounts,
          backgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF', '#FF9F40'],
          hoverBackgroundColor: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF', '#FF9F40']
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'top',
          }
        }
      }
    });
  }
}
