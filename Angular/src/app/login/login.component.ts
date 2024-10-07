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
  loginError: string = '';
  loading = false;

  constructor(private authService: AuthService, private router: Router) {}

  onSubmit(loginForm: any): void {
    this.submitted = true;

    if (loginForm.valid) {
      this.loading = true;
      this.authService.login(this.form).subscribe(
        (res) => {
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
}
