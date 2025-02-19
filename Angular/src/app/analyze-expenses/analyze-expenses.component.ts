import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../api.service';
import { CommonModule, DecimalPipe } from '@angular/common';
import { Chart } from 'chart.js/auto';

@Component({
  selector: 'app-analyze-expenses',
  standalone: true,
  imports: [CommonModule, FormsModule],
  providers: [DecimalPipe],
  templateUrl: './analyze-expenses.component.html',
  styleUrls: ['./analyze-expenses.component.css']
})
export class AnalyzeExpensesComponent implements OnInit {
  analysis: any = {};
  chart: any;
  categoryChart: any;
  selectedPredictionType: string = 'Total';
  selectedMonths: number = 6;
  isSpendingClusteringView: boolean = true;
  isFrequencyClusteringView: boolean = false;
  isAssociationRulesView: boolean = false;
  isLoading: boolean = true;
  errorMessage: string | null = null;
  categoryTotals: { [category: string]: number } = {};

  constructor(private apiService: ApiService, private decimalPipe: DecimalPipe) {}

  ngOnInit() {
    this.apiService.analyzeExpenses().subscribe((res) => {
      this.analysis = res;
      this.createChart();
      this.isLoading = false;

      if((!this.analysis.spending_clustering || this.analysis.spending_clustering.length == 0)){
        this.isSpendingClusteringView = false;
        this.isFrequencyClusteringView = true;
      }

      if((!this.analysis.frequency_clustering || this.analysis.frequency_clustering.length == 0)){
        this.isFrequencyClusteringView = false;
        this.isAssociationRulesView = true;
      }

      if (this.analysis.category_limits) {
        this.analysis.category_limits.sort((a: any, b: any) => {
          if (a.name === "Goal") return -1;
          if (b.name === "Goal") return 1;
          return b.limit - a.limit;
        });
      }

      if (this.analysis?.association_rules) {
        this.analysis.association_rules.sort((a: any, b: any) => b.confidence - a.confidence);
      }
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

  getAccuracy(): number {
    let accuracy = this.selectedPredictionType === 'Total' 
      ? this.analysis?.predictions?.[0]?.accuracy 
      : this.analysis?.category_predictions?.[this.selectedPredictionType]?.[0]?.accuracy;
  
    return accuracy ? accuracy * 100 : 0;
  }

  getCategoryKeys(): string[] {
    return this.analysis.category_predictions ? Object.keys(this.analysis.category_predictions) : [];
  }

  goToPrevView() {
    if (this.isAssociationRulesView) {
      this.isAssociationRulesView = false;
      this.isFrequencyClusteringView = true;
    }

    else if (this.isFrequencyClusteringView) {
      this.isFrequencyClusteringView = false;
      this.isSpendingClusteringView = true;
    }
  }

  goToNextView() {
    if (this.isSpendingClusteringView) {
      this.isSpendingClusteringView = false;
      this.isFrequencyClusteringView = true;
    }

    else if (this.isFrequencyClusteringView) {
      this.isFrequencyClusteringView = false;
      this.isAssociationRulesView = true;
    }
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
            tension: 0.4,
            pointRadius: window.innerWidth < 768 ? 3 : 5,
            pointHoverRadius: window.innerWidth < 768 ? 5 : 7,
            pointBackgroundColor: '#FF6384',
            borderWidth: 2,
          },
          {
            label: 'Goal Limit',
            data: Array(days.length).fill(this.analysis.goal),
            borderColor: '#36A2EB',
            borderDash: [10, 5],
            fill: false,
            borderWidth: 2,
          },
          {
            label: 'Budget Limit',
            data: Array(days.length).fill(this.analysis.monthly_budget),
            borderColor: '#4BC0C0',
            borderDash: [10, 5],
            fill: false,
            borderWidth: 2,
          },
          {
            label: 'Zero Line',
            data: Array(days.length).fill(0),
            borderColor: '#000000',
            borderDash: [5, 5],
            fill: false,
            borderWidth: 1,
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
            labels: {
              font: {
                size: window.innerWidth < 768 ? 16 : 14,
              }
            }
          },
          tooltip: {
            enabled: true,
            mode: 'index',
            intersect: false,
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            titleFont: { size: window.innerWidth < 768 ? 16 : 14 },
            bodyFont: { size: window.innerWidth < 768 ? 14 : 12 },
            padding: 8,
          }
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'Days of the Month',
              font: {
                size: window.innerWidth < 768 ? 16 : 14,
              }
            },
            ticks: {
              font: {
                size: window.innerWidth < 768 ? 14 : 12,
              }
            }
          },
          y: {
            title: {
              display: true,
              text: 'Amount (EGP)',
              font: {
                size: window.innerWidth < 768 ? 16 : 14,
              }
            },
            ticks: {
              font: {
                size: window.innerWidth < 768 ? 14 : 12,
              }
            }
          }
        },
        animation: {
          duration: 1000,
          easing: 'easeInOutQuart',
        },
        interaction: {
          mode: 'nearest',
          intersect: false,
        },
        devicePixelRatio: window.devicePixelRatio || 1,
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

    categoryMap.forEach((totalExpense, category) => {
      this.categoryTotals[category] = totalExpense;
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
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
            labels: {
              font: {
                size: window.innerWidth < 768 ? 16 : 14,
              }
            }
          },
          tooltip: {
            enabled: true,
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            titleFont: { size: window.innerWidth < 768 ? 16 : 14 },
            bodyFont: { size: window.innerWidth < 768 ? 14 : 12 },
            padding: 8,
          }
        },
        animation: {
          duration: 1000,
          easing: 'easeInOutQuart',
        },
        devicePixelRatio: window.devicePixelRatio || 1,
      }
    });
  }
}
