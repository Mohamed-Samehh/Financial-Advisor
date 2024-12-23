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
  deleteAccount(): Observable<any> {
    return this.http.delete(`${this.apiUrl}/delete-account`, {
      headers: {
        Authorization: `Bearer ${this.getToken()}`
      }
    }).pipe(
      tap(() => {
        this.clearToken();
        this.router.navigate(['/register']);
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

  getToken(): string | null {
    return localStorage.getItem('token');
  }

  clearToken() {
    localStorage.removeItem('token');
    this.loggedIn.next(false);
  }

  handleError(error: any) {
    console.error('API Error:', error);
  }
}
