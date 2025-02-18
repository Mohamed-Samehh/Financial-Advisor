import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [FormsModule, CommonModule, RouterModule],
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css']
})
export class RegisterComponent {
  form: any = {
    name: '',
    email: '',
    password: '',
    password_confirmation: ''
  };
  message: { text: string; type: 'success' | 'error' } | null = null;
  submitted = false;
  isLoading = false;
  showPassword: boolean = false;
  showConfirmPassword: boolean = false;
  isPasswordFilled: boolean = false;
  isConfirmPasswordFilled: boolean = false;

  constructor(private authService: AuthService, private router: Router) {}

  ngOnInit(): void {
    const token = this.authService.getToken();

    if (token && this.authService.checkTokenExpiry()) {
      alert("It looks like you're already logged in. Redirecting you to your dashboard.");
      this.router.navigate(['/dashboard']);
    }
  }

  togglePasswordVisibility(field: 'password' | 'confirmPassword'): void {
    if (field === 'password') {
      this.showPassword = !this.showPassword;
    } else if (field === 'confirmPassword') {
      this.showConfirmPassword = !this.showConfirmPassword;
    }
  }

  onSubmit(registrationForm: any): void {
    this.submitted = true;

    if (registrationForm.valid && this.form.password === this.form.password_confirmation) {
      this.isLoading = true;
      this.authService.register(this.form).subscribe(
        (res) => {
          this.authService.setToken(res.token);
          this.message = { text: 'Registration successful! Redirecting to dashboard...', type: 'success' };
          this.router.navigate(['/dashboard']).then(() => {
            this.isLoading = false;
            window.location.reload();
          });
        },
        (err) => {
          this.isLoading = false;
          this.message = err.error?.error === 'The email is already registered.'
            ? { text: 'This email is already registered. Please use a different one.', type: 'error' }
            : { text: 'Error occurred during registration. Please try again.', type: 'error' };
        }
      );
    } else {
      this.message = { text: 'Please fill out the form correctly.', type: 'error' };
    }
  }

  checkPasswordInput(): void {
    this.isPasswordFilled = this.form.password.length > 0;
  }

  checkConfirmPasswordInput(): void {
    this.isConfirmPasswordFilled = this.form.password_confirmation.length > 0;
  }
}
