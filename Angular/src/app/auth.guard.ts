import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class AuthGuard implements CanActivate {
  constructor(private authService: AuthService, private router: Router) {}

  canActivate(): boolean {
    if (!this.authService.getToken()) {
      // If not logged in, redirect to login
      this.router.navigate(['/login']);
      return false;
    }
    // Allow access if logged in
    return true;
  }
}
