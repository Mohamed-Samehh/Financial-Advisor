import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { Router, RouterOutlet, RouterModule } from '@angular/router';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, RouterOutlet, RouterModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css'
})
export class LoginComponent {
  form: any = {};

  constructor(private authService: AuthService, private router: Router) {}

  onSubmit() {
    this.authService.login(this.form).subscribe(
      (res) => {
        this.authService.setToken(res.token);
        this.router.navigate(['/dashboard']).then(() => {
          window.location.reload();
        });
      },
      (err) => this.authService.handleError(err)
    );
  }
}
