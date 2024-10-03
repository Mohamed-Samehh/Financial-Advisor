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
          // Handle login error if necessary, e.g., display a toast or set an error message
          console.error('Login error', err);
        }
      );
    }
  }
}
