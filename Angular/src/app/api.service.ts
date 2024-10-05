import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  getHeaders() {
    const token = localStorage.getItem('token');
    return new HttpHeaders({
      Authorization: `Bearer ${token}`
    });
  }

  // Budget
  getBudget(): Observable<any> {
    return this.http.get(`${this.apiUrl}/budget`, { headers: this.getHeaders() });
  }

  addBudget(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/budget`, data, { headers: this.getHeaders() });
  }

  updateBudget(data: any, budgetId: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/budget/${budgetId}`, data, { headers: this.getHeaders() });
  }

  deleteBudget(budgetId: any): Observable<any> {
    return this.http.delete(`${this.apiUrl}/budget/${budgetId}`, { headers: this.getHeaders() });
  }

  // Goals
  getGoal(): Observable<any> {
    return this.http.get(`${this.apiUrl}/goals`, { headers: this.getHeaders() });
  }

  addGoal(data: any): Observable<any> {
      return this.http.post(`${this.apiUrl}/goals`, data, { headers: this.getHeaders() });
  }

  updateGoal(data: any, goalId: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/goals/${goalId}`, data, { headers: this.getHeaders() });
  }

  deleteGoal(goalId: any): Observable<any> {
    return this.http.delete(`${this.apiUrl}/goals/${goalId}`, { headers: this.getHeaders() });
  }

  // Expenses
  getExpenses(): Observable<any> {
    return this.http.get(`${this.apiUrl}/expenses`, { headers: this.getHeaders() });
  }

  getAllExpenses(): Observable<any> {
    return this.http.get(`${this.apiUrl}/expenses/all`, { headers: this.getHeaders() });
  }

  addExpense(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/expenses`, data, { headers: this.getHeaders() });
  }

  updateExpense(data: any, id: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/expenses/${id}`, data, { headers: this.getHeaders() });
  }

  deleteExpense(id: any): Observable<any> {
      return this.http.delete(`${this.apiUrl}/expenses/${id}`, { headers: this.getHeaders() });
  }

  analyzeExpenses(): Observable<any> {
    return this.http.get(`${this.apiUrl}/analyze-expenses`, { headers: this.getHeaders() });
  }
}
