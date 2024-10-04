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
  submitted = false;
  loginError: string = '';  // Variable to store the error message

  constructor(private authService: AuthService, private router: Router) {}

  onSubmit(loginForm: any): void {
    this.submitted = true;

    if (loginForm.valid) {
      this.authService.login(this.form).subscribe(
        (res) => {
          this.authService.setToken(res.token);
          this.router.navigate(['/dashboard']).then(() => window.location.reload());
        },
        (err) => {
          // Display a user-friendly error message
          this.loginError = 'Invalid email or password. Please try again.';  // Customize as needed
          console.error('Login error', err);
        }
      );
    }
  }
}
