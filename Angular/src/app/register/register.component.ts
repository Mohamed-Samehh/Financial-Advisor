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
    email: ''
  };
  message: { text: string; } | null = null;
  submitted = false;
  isLoading = false;

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

  async onSubmit(registrationForm: any): Promise<void> {
    this.submitted = true;

    if (registrationForm.valid) {
      this.isLoading = true;
      this.authService.register(this.form).subscribe(
        async (res) => {
          this.isLoading = false;
          await Swal.fire({
            title: "Registration Successful",
            text: "A password has been sent to your email. Please check your inbox and log in to continue.",
            icon: "success",
            confirmButtonColor: "#3085d6",
            confirmButtonText: "OK"
          });
          this.router.navigate(['/login']);
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
}
