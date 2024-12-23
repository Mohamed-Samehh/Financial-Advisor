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
  loadingUpdateInfo = false;
  loadingUpdatePassword = false;

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
    this.loadingUpdateInfo = true;

    if (this.updateInfoForm.valid) {
      this.authService.updateProfile(this.updateInfoForm.value).subscribe({
        next: () => {
          this.updateInfoSuccess = 'Profile updated successfully!';
          this.updateInfoError = '';
          this.submittedInfo = false;
          this.updateInfoForm.reset();
          this.loadingUpdateInfo = false;
        },
        error: (err) => {
          if (err.status === 400) {
            const errors = err.error;
            if (errors.email) {
              this.updateInfoError = errors.email[0];
            } else if (errors.name) {
              this.updateInfoError = errors.name[0];
            } else {
              this.updateInfoError = 'Validation failed. Please check your input.';
            }
          } else {
            this.updateInfoError = 'Failed to update profile. Please try again.';
          }
          this.updateInfoSuccess = '';
          this.loadingUpdateInfo = false;
        },
      });
    } else {
      this.updateInfoError = 'Please correct the errors in the form.';
      this.loadingUpdateInfo = false;
    }
  }

  onUpdatePassword() {
    this.submittedPassword = true;
    this.updatePasswordSuccess = '';
    this.updatePasswordError = '';
    this.loadingUpdatePassword = true;

    if (this.updatePasswordForm.valid) {
      this.authService.updatePassword(this.updatePasswordForm.value).subscribe({
        next: () => {
          this.updatePasswordSuccess = 'Password updated successfully!';
          this.updatePasswordError = '';
          this.submittedPassword = false;
          this.updatePasswordForm.reset();
          this.loadingUpdatePassword = false;
        },
        error: (err) => {
          this.updatePasswordError = err.error?.message || 'Current password is incorrect.';
          this.updatePasswordSuccess = '';
          this.loadingUpdatePassword = false;
        },
      });
    } else {
      this.updatePasswordError = 'Please correct the errors in the form.';
      this.loadingUpdatePassword = false;
    }
  }

  onDeleteAccount() {
    if (confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
      this.authService.deleteAccount().subscribe({
        next: () => {
          alert('Account deleted successfully. You will now be logged out.');
          window.location.reload();
        },
        error: (err) => {
          alert(err.error?.message || 'Failed to delete account. Please try again.');
        },
      });
    }
  }
}
