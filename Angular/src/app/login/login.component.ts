import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { Router, RouterOutlet, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, RouterOutlet, RouterModule, CommonModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  form: any = {
    email: '',
    password: ''
  };
  message: { text: string; type: 'success' | 'error' } | null = null;
  submitted = false;

  constructor(private authService: AuthService, private router: Router) {}

  onSubmit(loginForm: any): void {
    this.submitted = true;

    if (loginForm.valid) {
      this.authService.login(this.form).subscribe(
        (res) => {
          this.authService.setToken(res.token);
          this.message = { text: 'Login successful! Redirecting to dashboard...', type: 'success' };
          this.router.navigate(['/dashboard']).then(() => window.location.reload());
        },
        (err) => {
          this.message = { text: 'Invalid login credentials. Please try again.', type: 'error' };
        }
      );
    } else {
      this.message = { text: 'Please fill out the form correctly.', type: 'error' };
    }
  }
}
