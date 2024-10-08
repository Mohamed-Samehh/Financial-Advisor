import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { AuthService } from '../auth.service';

@Component({
  selector: 'app-user-profile',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './user-profile.component.html',
  styleUrls: ['./user-profile.component.css'],
})
export class UserProfileComponent implements OnInit {
  updateInfoForm: FormGroup;
  updatePasswordForm: FormGroup;
  updateInfoSuccess: string = '';
  updatePasswordSuccess: string = '';
  updateInfoError: string = '';
  updatePasswordError: string = '';
  userData: any;
  submittedInfo = false;
  submittedPassword = false;
  isLoading = false;

  constructor(private fb: FormBuilder, private authService: AuthService) {
    this.updateInfoForm = this.fb.group({
      name: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]],
    });

    this.updatePasswordForm = this.fb.group({
      current_password: ['', Validators.required],
      new_password: ['', [Validators.required, Validators.minLength(8)]],
      password_confirmation: ['', Validators.required],
    }, { validators: this.passwordMatchValidator });
  }

  ngOnInit() {
    this.fetchUserProfile();
  }

  fetchUserProfile() {
    this.isLoading = true;
    this.authService.getProfile().subscribe({
      next: (data) => {
        this.userData = data.user;
        this.updateInfoForm.patchValue({
          name: this.userData.name,
          email: this.userData.email,
        });
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Failed to fetch user profile:', err);
        this.isLoading = false;
      },
    });
  }

  private passwordMatchValidator(form: FormGroup) {
    return form.get('new_password')?.value === form.get('password_confirmation')?.value ? null : { mismatch: true };
  }

  onUpdateProfile() {
    this.submittedInfo = true;
    this.updateInfoSuccess = '';
    this.updateInfoError = '';

    if (this.updateInfoForm.valid) {
      this.authService.updateProfile(this.updateInfoForm.value).subscribe({
        next: () => {
          this.updateInfoSuccess = 'Profile updated successfully!';
          this.updateInfoError = '';
          this.submittedInfo = false;
          this.updateInfoForm.reset();
        },
        error: (err) => {
          this.updateInfoError = err.error?.message || 'Failed to update profile. Please try again.';
          this.updateInfoSuccess = '';
        },
      });
    } else {
      this.updateInfoError = 'Please correct the errors in the form.';
    }
  }

  onUpdatePassword() {
    this.submittedPassword = true;
    this.updatePasswordSuccess = '';
    this.updatePasswordError = '';

    if (this.updatePasswordForm.valid) {
      this.authService.updatePassword(this.updatePasswordForm.value).subscribe({
        next: () => {
          this.updatePasswordSuccess = 'Password updated successfully!';
          this.updatePasswordError = '';
          this.submittedPassword = false;
          this.updatePasswordForm.reset();
        },
        error: (err) => {
          this.updatePasswordError = err.error?.message || 'Current password is incorrect.';
          this.updatePasswordSuccess = '';
        },
      });
    } else {
      this.updatePasswordError = 'Please correct the errors in the form.';
    }
  }
}
