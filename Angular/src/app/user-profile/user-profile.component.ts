import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { AuthService } from '../auth.service';
import Swal from 'sweetalert2';

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
  deleteAccountForm: FormGroup;
  updateInfoSuccess = '';
  updatePasswordSuccess = '';
  deleteAccountSuccess = '';
  updateInfoError = '';
  updatePasswordError = '';
  deleteAccountError = '';
  userData: any;
  submittedInfo = false;
  submittedPassword = false;
  submittedDelete = false;
  isLoading = false;
  loadingUpdateInfo = false;
  loadingUpdatePassword = false;
  loadingDeleteAccount = false;
  showCurrentPassword: boolean = false;
  showNewPassword: boolean = false;
  showConfirmPassword: boolean = false;
  showDeletePassword: boolean = false;
  isCurrentPasswordFilled: boolean = false;
  isNewPasswordFilled: boolean = false;
  isConfirmPasswordFilled: boolean = false;
  isDeletePasswordFilled: boolean = false;

  constructor(private fb: FormBuilder, private authService: AuthService) {
    this.updateInfoForm = this.fb.group({
      name: ['', [Validators.required, Validators.minLength(2)]],
      email: ['', [Validators.required, Validators.email]],
    });

    this.updatePasswordForm = this.fb.group(
      {
        current_password: ['', Validators.required],
        new_password: ['', [Validators.required, Validators.minLength(8)]],
        password_confirmation: ['', Validators.required],
      },
      { validators: this.passwordMatchValidator }
    );

    this.deleteAccountForm = this.fb.group({
      password: ['', Validators.required],
    });
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
        console.error('Failed to fetch user account:', err);
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
          this.updateInfoSuccess = 'Account updated successfully!';
          this.updateInfoError = '';
          this.submittedInfo = false;
          const updatedValues = this.updateInfoForm.value;

          this.updateInfoForm.reset();

          this.userData = { ...updatedValues };

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
            this.updateInfoError = 'Failed to update account. Please try again.';
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
          this.isCurrentPasswordFilled = false;
          this.isNewPasswordFilled = false;
          this.isConfirmPasswordFilled = false;
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

  async onDeleteAccount() {
    this.submittedDelete = true;
    this.deleteAccountError = '';
    this.loadingDeleteAccount = true;
  
    if (this.deleteAccountForm.valid) {
      const password = this.deleteAccountForm.value.password?.toString().trim();
  
      if (!password) {
        this.deleteAccountError = 'Please enter your password.';
        this.loadingDeleteAccount = false;
        return;
      }
  
      const confirmation = await Swal.fire({
        title: "Are you sure?",
        text: "This will permanently delete your account.",
        icon: "warning",
        showCancelButton: true,
        confirmButtonColor: "#3085d6",
        cancelButtonColor: "#d33",
        confirmButtonText: "Yes, delete it!"
      });
  
      if (confirmation.isConfirmed) {
        try {
          await this.authService.deleteAccount(password).toPromise();
          await Swal.fire({
            title: "Account Deleted",
            text: "Account deleted successfully. You will now be logged out.",
            icon: "success",
            confirmButtonColor: "#3085d6",
            confirmButtonText: "OK"
          });
          this.submittedDelete = false;
          this.deleteAccountForm.reset();
          this.loadingDeleteAccount = false;
          window.location.reload();
        } catch (err: any) {
          this.deleteAccountError = err.error?.message || 'Incorrect password. Please try again.';
          this.loadingDeleteAccount = false;
        }
      } else {
        this.loadingDeleteAccount = false;
      }
    } else {
      this.deleteAccountError = 'Please enter your password to proceed.';
      this.loadingDeleteAccount = false;
    }
  }

  togglePasswordVisibility(field: 'current' | 'new' | 'confirm' | 'delete'): void {
    if (field === 'current') {
      this.showCurrentPassword = !this.showCurrentPassword;
    } else if (field === 'new') {
      this.showNewPassword = !this.showNewPassword;
    } else if (field === 'confirm') {
      this.showConfirmPassword = !this.showConfirmPassword;
    } else if (field === 'delete') {
      this.showDeletePassword = !this.showDeletePassword;
    }
  }

  checkPasswordInput(field: 'current' | 'new' | 'confirm' | 'delete', event: Event): void {
    const target = event.target as HTMLInputElement;
    if (!target) return;

    const value = target.value;

    if (field === 'current') {
      this.isCurrentPasswordFilled = value.length > 0;
    } else if (field === 'new') {
      this.isNewPasswordFilled = value.length > 0;
    } else if (field === 'confirm') {
      this.isConfirmPasswordFilled = value.length > 0;
    } else if (field === 'delete') {
      this.isDeletePasswordFilled = value.length > 0;
    }
  }
}
