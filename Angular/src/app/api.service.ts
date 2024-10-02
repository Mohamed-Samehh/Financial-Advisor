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

  getBudget(): Observable<any> {
    return this.http.get(`${this.apiUrl}/budget`, { headers: this.getHeaders() });
  }

  addBudget(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/budget`, data, { headers: this.getHeaders() });
  }

  getGoals(): Observable<any> {
    return this.http.get(`${this.apiUrl}/goals`, { headers: this.getHeaders() });
  }

  addGoal(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/goals`, data, { headers: this.getHeaders() });
  }

  getExpenses(): Observable<any> {
    return this.http.get(`${this.apiUrl}/expenses`, { headers: this.getHeaders() });
  }

  addExpense(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/expenses`, data, { headers: this.getHeaders() });
  }

  analyzeExpenses(): Observable<any> {
    return this.http.get(`${this.apiUrl}/analyze-expenses`, { headers: this.getHeaders() });
  }
}
