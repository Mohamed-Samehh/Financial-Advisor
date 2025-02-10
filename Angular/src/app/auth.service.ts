import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Router } from '@angular/router';
import { BehaviorSubject, Observable, throwError  } from 'rxjs';
import { tap, map, catchError } from 'rxjs/operators';
import { LoginResponse } from './login-response.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = 'http://localhost:8000/api';
  private loggedIn = new BehaviorSubject<boolean>(false);

  constructor(private http: HttpClient, private router: Router) {}

  // Register a new user
  register(data: any): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/register`, data);
  }

  // Log in an existing user
  login(data: any): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/login`, data).pipe(
      tap(response => {
        if (response.token) {
          this.setToken(response.token);
        }
      })
    );
  }

  // Delete user account
  deleteAccount(password: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/delete-account`, { password }, {
      headers: {
        Authorization: `Bearer ${this.getToken()}`
      }
    }).pipe(
      tap(() => {
        this.clearToken();
      }),
      catchError((error) => {
        return throwError(() => error);
      })
    );
  }

  // Update profile (name and email)
  updateProfile(data: { name: string; email: string }): Observable<any> {
    return this.http.put(`${this.apiUrl}/update-profile`, data, {
        headers: {
            Authorization: `Bearer ${this.getToken()}`
        }
    });
  }

  // Get user profile
  getProfile(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/profile`, {
      headers: {
        Authorization: `Bearer ${this.getToken()}`
      }
    });
  }

  // Update password
  updatePassword(data: { current_password: string; new_password: string }): Observable<any> {
    return this.http.put(`${this.apiUrl}/update-password`, data, {
        headers: {
            Authorization: `Bearer ${this.getToken()}`
        }
    });
  }

  isLoggedIn(): Observable<boolean> {
    return this.loggedIn.asObservable();
  }

  // Store the token in local storage
  setToken(token: string) {
    localStorage.setItem('token', token);
    this.loggedIn.next(true);
  }

  // Get the token from local storage
  getToken(): string | null {
    return localStorage.getItem('token');
  }

  // Remove the token from local storage
  clearToken() {
    localStorage.removeItem('token');
    this.loggedIn.next(false);
  }

  // Check if the token is expired
  checkTokenExpiry(): Observable<boolean> {
    const token = this.getToken();
    if (!token) {
      this.clearToken();
      return new BehaviorSubject(false).asObservable();
    }

    return this.http.post<{ expired: boolean }>(`${this.apiUrl}/check-token-expiry`, { token }).pipe(
      map(response => {
        if (response.expired) {
          this.clearToken();
        }
        return !response.expired;
      }),
      catchError(() => {
        this.clearToken();
        return new BehaviorSubject(false).asObservable();
      })
    );
  }

  // Forgot Password
  forgotPassword(email: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/forgot-password`, { email }).pipe(
      catchError((error) => {
        return throwError(() => new Error(error.error?.message || 'An unexpected error occurred.'));
      })
    );
  }

  // Handle errors sent from backend
  handleError(error: any) {
    console.error('API Error:', error);
  }
}
