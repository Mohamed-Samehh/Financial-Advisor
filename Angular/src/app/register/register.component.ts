import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { Router, RouterOutlet, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [FormsModule, CommonModule, RouterOutlet, RouterModule],
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

  constructor(private authService: AuthService, private router: Router) {}

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
          this.message = { text: 'Error occurred during registration. Please try again.', type: 'error' };
        }
      );
    } else {
      this.message = { text: 'Please fill out the form correctly.', type: 'error' };
    }
  }
}
