import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, RouterModule, CommonModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  form: any = { email: '', password: '' };
  submitted = false;
  loginError: string = '';
  loading = false;

  forgotPasswordEmail: string = '';
  forgotPasswordMessage: string = '';
  forgotPasswordError: string = '';
  showForgotPassword: boolean = false;
  loadingForgotPassword: boolean = false;
  showPassword: boolean = false;
  isPasswordFilled: boolean = false;

  constructor(private authService: AuthService, private router: Router) {}

  ngOnInit(): void {
    const token = this.authService.getToken();

    if (token && !this.authService.checkTokenExpiry()) {
      this.router.navigate(['/dashboard']);
    }
  }

  onSubmit(loginForm: any): void {
    this.submitted = true;

    if (loginForm.valid) {
      this.loading = true;
      this.authService.login(this.form).subscribe(
        (res) => {
          this.loginError = '';
          this.authService.setToken(res.token);
          this.loading = false;
          this.router.navigate(['/dashboard']).then(() => window.location.reload());
        },
        (err) => {
          this.loading = false;
          this.loginError = 'Invalid email or password. Please try again.';
          console.error('Login error', err);
        }
      );
    }
  }

  onForgotPassword(): void {
    if (!this.forgotPasswordEmail) {
      this.forgotPasswordError = 'Please enter a valid email.';
      this.forgotPasswordMessage = '';
      return;
    }

    this.loadingForgotPassword = true;
    this.authService.forgotPassword(this.forgotPasswordEmail).subscribe({
      next: () => {
        this.forgotPasswordMessage = 'A new password has been sent to your email.';
        this.forgotPasswordError = '';
        this.loadingForgotPassword = false;
      },
      error: (error) => {
        this.forgotPasswordError = error.message || 'Error sending email.';
        this.forgotPasswordMessage = '';
        this.loadingForgotPassword = false;
      }
    });
  }

  toggleForgotPassword(): void {
    this.showForgotPassword = !this.showForgotPassword;
    this.forgotPasswordEmail = '';
    this.forgotPasswordMessage = '';
    this.loginError = '';
  }

  togglePasswordVisibility(): void {
    this.showPassword = !this.showPassword;
  }

  checkPasswordInput(): void {
    this.isPasswordFilled = this.form.password.length > 0;
  }
}
