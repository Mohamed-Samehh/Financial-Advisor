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
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json'
    });
  }

   // Send chat message to chatbot
   sendChatMessage(message: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/chatbot`, { message }, { headers: this.getHeaders() });
  }

  // Budget
  getAllBudgets(): Observable<any> {
    return this.http.get(`${this.apiUrl}/budget/all`, { headers: this.getHeaders() });
  }

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
  getAllGoals(): Observable<any> {
    return this.http.get(`${this.apiUrl}/goal/all`, { headers: this.getHeaders() });
  }

  getGoal(): Observable<any> {
    return this.http.get(`${this.apiUrl}/goal`, { headers: this.getHeaders() });
  }

  addGoal(data: any): Observable<any> {
      return this.http.post(`${this.apiUrl}/goal`, data, { headers: this.getHeaders() });
  }

  updateGoal(data: any, goalId: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/goal/${goalId}`, data, { headers: this.getHeaders() });
  }

  deleteGoal(goalId: any): Observable<any> {
    return this.http.delete(`${this.apiUrl}/goal/${goalId}`, { headers: this.getHeaders() });
  }

  // Expenses
  getAllExpenses(): Observable<any> {
    return this.http.get(`${this.apiUrl}/expenses/all`, { headers: this.getHeaders() });
  }

  getExpenses(): Observable<any> {
    return this.http.get(`${this.apiUrl}/expenses`, { headers: this.getHeaders() });
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

  // Categories
  getCategories(): Observable<any> {
    return this.http.get(`${this.apiUrl}/categories`, { headers: this.getHeaders() });
  }

  addCategory(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/categories`, data, { headers: this.getHeaders() });
  }

  updateCategory(data: any, id: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/categories/${id}`, data, { headers: this.getHeaders() });
  }

  deleteCategory(id: any, newCategory: string): Observable<any> {
    const body = { new_category: newCategory };
    return this.http.delete(`${this.apiUrl}/categories/${id}`, {
      headers: this.getHeaders(),
      body: body
    });
  }

  getCategorySuggestions(): Observable<any> {
    return this.http.get(`${this.apiUrl}/categories/suggest`, { headers: this.getHeaders() });
  }

  getCategoryLabels(): Observable<any> {
    return this.http.get(`${this.apiUrl}/categories/label`, { headers: this.getHeaders() });
  }
}
