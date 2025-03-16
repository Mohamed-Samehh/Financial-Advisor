import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import Swal from 'sweetalert2';

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
  message: { text: string; } | null = null;
  submitted = false;
  isLoading = false;
  showPassword: boolean = false;
  showConfirmPassword: boolean = false;
  isPasswordFilled: boolean = false;
  isConfirmPasswordFilled: boolean = false;

  constructor(private authService: AuthService, private router: Router) {}

  async ngOnInit(): Promise<void> {
    const token = this.authService.getToken();

    if (token && this.authService.checkTokenExpiry()) {
      await Swal.fire({
        title: "Already Logged In",
        text: "It looks like you're already logged in. Redirecting you to your dashboard.",
        icon: "info",
        confirmButtonColor: "#3085d6",
        confirmButtonText: "OK"
      });
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
          this.router.navigate(['/dashboard']).then(() => {
            this.isLoading = false;
            window.location.reload();
          });
        },
        (err) => {
          this.isLoading = false;
          this.message = err.error?.error === 'The email is already registered.'
            ? { text: 'This email is already registered. Please use a different one.' }
            : { text: 'Error occurred during registration. Please try again.' };
        }
      );
    } else {
      this.message = { text: 'Please fill out the form correctly.' };
    }
  }

  checkPasswordInput(): void {
    this.isPasswordFilled = this.form.password.length > 0;
  }

  checkConfirmPasswordInput(): void {
    this.isConfirmPasswordFilled = this.form.password_confirmation.length > 0;
  }
}
