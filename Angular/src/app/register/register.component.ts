import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css']
})
export class RegisterComponent {
  form: any = {};

  constructor(private authService: AuthService, private router: Router) {}

  onSubmit() {
    if (this.form.password === this.form.password_confirmation) {
      this.authService.register(this.form).subscribe(
        (res) => {
          this.authService.setToken(res.token);
          this.router.navigate(['/dashboard']).then(() => {
            window.location.reload();
          });
        },
        (err) => this.authService.handleError(err)
      );
    } else {
      console.error('Passwords do not match.');
    }
  }
}
