import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';
import { switchMap, take } from 'rxjs/operators';
import Swal from 'sweetalert2';

@Injectable({
  providedIn: 'root',
})
export class AuthGuard implements CanActivate {
  constructor(private authService: AuthService, private router: Router) {}

  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): Observable<boolean> | Promise<boolean> | boolean {
    return this.authService.checkTokenExpiry().pipe(
      switchMap(isValid => {
        if (!isValid) {
          return this.authService.getSessionExpired().pipe(
            take(1),
            switchMap(async expired => {
              if (expired) {
                await Swal.fire({
                  title: "Session Expired",
                  text: "Your session has expired. Please log in again to continue.",
                  icon: "warning",
                  confirmButtonColor: "#3085d6",
                  confirmButtonText: "OK"
                });
                await this.router.navigate(['/login']);
                window.location.reload();
                return false;
              }
              // If token is invalid but not explicitly expired, redirect without dialog
              await this.router.navigate(['/login']);
              window.location.reload();
              return false;
            })
          );
        }
        return [true]; // Token is valid, allow access
      })
    );
  }
}