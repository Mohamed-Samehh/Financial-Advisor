import { Component, OnInit, Renderer2 } from '@angular/core';
import { RouterOutlet, RouterModule, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterModule, CommonModule, HttpClientModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {
  title = 'frontend';
  isLoggedIn = false;
  isNavbarVisible: boolean = false;
  private apiUrl = 'http://localhost:8000/api/check-token-expiry';

  constructor(
    private router: Router, 
    private http: HttpClient,
    private renderer: Renderer2
  ) {}

  ngOnInit(): void {
    const token = this.getToken();

    if (token) {
      this.checkTokenExpiry(token);
    } else {
      this.clearToken();
    }
  }

  toggleNavbar() {
    this.isNavbarVisible = !this.isNavbarVisible;
    
    if (this.isNavbarVisible) {
      this.renderer.addClass(document.body, 'menu-open');
    } else {
      this.renderer.removeClass(document.body, 'menu-open');
    }
  }

  closeNavbar() {
    this.isNavbarVisible = false;
    this.renderer.removeClass(document.body, 'menu-open');
  }

  logout() {
    this.clearToken();
    this.router.navigate(['/login']);
  }

  getToken(): string | null {
    return localStorage.getItem('token');
  }

  clearToken() {
    localStorage.removeItem('token');
    this.isLoggedIn = false;
  }

  checkTokenExpiry(token: string) {
    this.http.post<{ expired: boolean }>(this.apiUrl, { token }).subscribe(
      (response) => {
        if (response.expired) {
          this.clearToken();
          this.router.navigate(['/login']);
        } else {
          this.isLoggedIn = true;
        }
      },
      () => {
        this.clearToken();
        this.router.navigate(['/login']);
      }
    );
  }
}
