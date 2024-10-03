import { Component, OnInit } from '@angular/core';
import { RouterOutlet, RouterModule, Router } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterModule, CommonModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {
  title = 'frontend';
  isLoggedIn = false;

  constructor(private router: Router) {}

  ngOnInit(): void {
    const token = this.getToken();
    this.isLoggedIn = !!token;

    if (!token) {
      this.router.navigate(['/login']);
    }
  }

  logout() {
    if (confirm('Are you sure you want to logout?')) {
      this.clearToken();
      this.router.navigate(['/login']);
    }
  }

  // Token management
  getToken(): string | null {
    return localStorage.getItem('token');
  }

  clearToken() {
    localStorage.removeItem('token');
    this.isLoggedIn = false;
  }
}
