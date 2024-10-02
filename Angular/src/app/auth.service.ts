import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { LoginResponse } from './login-response.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = 'http://localhost:8000/api';
  private loggedIn = new BehaviorSubject<boolean>(false);

  constructor(private http: HttpClient, private router: Router) {}

  // Register a new user
  register(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/register`, data);
  }

  // Log in an existing user and store the token
  login(data: any): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, data).pipe(
      tap(response => {
        if (response.token) {
          this.setToken(response.token);
        }
      })
    );
  }

  // Log out the user and clear the token
  logout(): Observable<any> {
    return this.http.post(`${this.apiUrl}/logout`, {}).pipe(
      tap(() => {
        this.clearToken();
        this.router.navigate(['/login']);
      })
    );
  }

  // Check if user is logged in (used for guards)
  isLoggedIn(): Observable<boolean> {
    return this.loggedIn.asObservable();
  }

  // Store token in local storage and update logged-in status
  setToken(token: string) {
    localStorage.setItem('token', token);
    this.loggedIn.next(true);
  }

  // Get token from local storage
  getToken(): string | null {
    return localStorage.getItem('token');
  }

  // Clear token from local storage and update logged-in status
  clearToken() {
    localStorage.removeItem('token');
    this.loggedIn.next(false);
  }

  // Handle any API errors
  handleError(error: any) {
    console.error('API Error:', error);
  }
}
