import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserProfileComponent } from './user-profile.component';
import { AuthService } from '../auth.service';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { of, throwError } from 'rxjs';
import Swal from 'sweetalert2';

// Mock SweetAlert2
jest.mock('sweetalert2', () => ({
  fire: jest.fn().mockResolvedValue({ isConfirmed: true })
}));

describe('UserProfileComponent', () => {
  let component: UserProfileComponent;
  let fixture: ComponentFixture<UserProfileComponent>;
  let authServiceMock: jest.Mocked<AuthService>;
  let consoleErrorSpy: jest.SpyInstance;

  const mockUserData = {
    user: {
      id: '1',
      name: 'Test User',
      email: 'test@example.com'
    }
  };

  beforeEach(async () => {
    // Create mock for AuthService
    const authMock = {
      getProfile: jest.fn(),
      updateProfile: jest.fn(),
      updatePassword: jest.fn(),
      deleteAccount: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        ReactiveFormsModule,
        UserProfileComponent
      ],
      providers: [
        { provide: AuthService, useValue: authMock }
      ]
    }).compileComponents();

    authServiceMock = TestBed.inject(AuthService) as jest.Mocked<AuthService>;
  });

  beforeEach(() => {
    // Mock console.error to prevent error output during tests
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    
    // Set up the default return values
    authServiceMock.getProfile.mockReturnValue(of(mockUserData));
    authServiceMock.updateProfile.mockReturnValue(of({ message: 'Profile updated successfully' }));
    authServiceMock.updatePassword.mockReturnValue(of({ message: 'Password updated successfully' }));
    authServiceMock.deleteAccount.mockReturnValue(of({ message: 'Account deleted successfully' }));

    fixture = TestBed.createComponent(UserProfileComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    // Restore console.error and clear all mocks
    consoleErrorSpy.mockRestore();
    jest.clearAllMocks();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should fetch user profile on initialization', () => {
    expect(authServiceMock.getProfile).toHaveBeenCalled();
    expect(component.userData).toEqual(mockUserData.user);
    expect(component.isLoading).toBe(false);
    
    // Form should be populated with user data
    expect(component.updateInfoForm.get('name')?.value).toBe('Test User');
    expect(component.updateInfoForm.get('email')?.value).toBe('test@example.com');
  });

  it('should handle error when fetching user profile', () => {
    authServiceMock.getProfile.mockReturnValue(throwError(() => new Error('Failed to load profile')));
    
    component.fetchUserProfile();
    
    expect(component.isLoading).toBe(false);
    expect(consoleErrorSpy).toHaveBeenCalled();
  });

  it('should update user profile when form is valid', async () => {
    // Prepare the form with valid values
    component.updateInfoForm.patchValue({
      name: 'Updated Name',
      email: 'updated@example.com'
    });
    
    component.onUpdateProfile();
    
    // Wait for async operations to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(authServiceMock.updateProfile).toHaveBeenCalledWith({
      name: 'Updated Name',
      email: 'updated@example.com'
    });
    expect(component.updateInfoSuccess).toBe('Account updated successfully!');
    expect(component.updateInfoError).toBe('');
    expect(component.loadingUpdateInfo).toBe(false);
  });

  it('should handle error when updating profile with invalid data', async () => {
    // Mock the API error response
    authServiceMock.updateProfile.mockReturnValue(throwError(() => ({
      status: 400,
      error: { email: ['Email is already taken'] }
    })));
    
    component.updateInfoForm.patchValue({
      name: 'Updated Name',
      email: 'invalid@example.com'
    });
    
    component.onUpdateProfile();
    
    // Wait for async operations to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(component.updateInfoError).toBe('Email is already taken');
    expect(component.updateInfoSuccess).toBe('');
    expect(component.loadingUpdateInfo).toBe(false);
  });

  it('should not submit update profile form when invalid', () => {
    // Make the form invalid
    component.updateInfoForm.patchValue({
      name: '',
      email: 'invalid-email'
    });
    
    component.onUpdateProfile();
    
    expect(authServiceMock.updateProfile).not.toHaveBeenCalled();
    expect(component.updateInfoError).toBe('Please correct the errors in the form.');
    expect(component.loadingUpdateInfo).toBe(false);
  });

  it('should update password when form is valid', async () => {
    // Prepare the form with valid values
    component.updatePasswordForm.patchValue({
      current_password: 'currentPassword123',
      new_password: 'newPassword123',
      password_confirmation: 'newPassword123'
    });
    
    component.onUpdatePassword();
    
    // Wait for async operations to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(authServiceMock.updatePassword).toHaveBeenCalledWith({
      current_password: 'currentPassword123',
      new_password: 'newPassword123',
      password_confirmation: 'newPassword123'
    } as any);
    expect(component.updatePasswordSuccess).toBe('Password updated successfully!');
    expect(component.updatePasswordError).toBe('');
    expect(component.loadingUpdatePassword).toBe(false);
  });

  it('should handle error when updating password', async () => {
    // Mock the API error response
    authServiceMock.updatePassword.mockReturnValue(throwError(() => ({
      error: { message: 'Current password is incorrect' }
    })));
    
    component.updatePasswordForm.patchValue({
      current_password: 'wrongPassword',
      new_password: 'newPassword123',
      password_confirmation: 'newPassword123'
    });
    
    component.onUpdatePassword();
    
    // Wait for async operations to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(component.updatePasswordError).toBe('Current password is incorrect');
    expect(component.updatePasswordSuccess).toBe('');
    expect(component.loadingUpdatePassword).toBe(false);
  });

  it('should not submit update password form when invalid', () => {
    // Make the form invalid (different passwords)
    component.updatePasswordForm.patchValue({
      current_password: 'currentPassword123',
      new_password: 'newPassword123',
      password_confirmation: 'differentPassword123'
    });
    
    component.onUpdatePassword();
    
    expect(authServiceMock.updatePassword).not.toHaveBeenCalled();
    expect(component.updatePasswordError).toBe('Please correct the errors in the form.');
    expect(component.loadingUpdatePassword).toBe(false);
  });

  it('should delete account with valid password and confirmation', async () => {
    // Prepare the form with valid password
    component.deleteAccountForm.patchValue({
      password: 'password123'
    });
    
    // Mock SweetAlert confirmation
    (Swal.fire as jest.Mock).mockResolvedValueOnce({ isConfirmed: true });
    
    await component.onDeleteAccount();
    
    expect(authServiceMock.deleteAccount).toHaveBeenCalledWith('password123');
    expect(Swal.fire).toHaveBeenCalledTimes(2); // First for confirmation, second for success
    // Note: We don't test window.location.reload as it's not reliably mockable in Jest
  });

  it('should not delete account when user cancels confirmation', async () => {
    // Prepare the form with valid password
    component.deleteAccountForm.patchValue({
      password: 'password123'
    });
    
    // Mock SweetAlert cancellation
    (Swal.fire as jest.Mock).mockResolvedValueOnce({ isConfirmed: false });
    
    await component.onDeleteAccount();
    
    expect(authServiceMock.deleteAccount).not.toHaveBeenCalled();
    expect(component.loadingDeleteAccount).toBe(false);
  });

  it('should handle error when deleting account', async () => {
    // Prepare the form with valid password
    component.deleteAccountForm.patchValue({
      password: 'wrongPassword'
    });
    
    // Mock API error
    authServiceMock.deleteAccount.mockReturnValue(throwError(() => ({
      error: { message: 'Incorrect password' }
    })));
    
    // Mock SweetAlert confirmation
    (Swal.fire as jest.Mock).mockResolvedValueOnce({ isConfirmed: true });
    
    await component.onDeleteAccount();
    
    expect((component as any).deleteAccountError).toBe('Incorrect password');
    expect(component.loadingDeleteAccount).toBe(false);
  });

  it('should toggle password visibility', () => {
    // Test current password field
    expect(component.showCurrentPassword).toBe(false);
    component.togglePasswordVisibility('current');
    expect(component.showCurrentPassword).toBe(true);
    component.togglePasswordVisibility('current');
    expect(component.showCurrentPassword).toBe(false);
    
    // Test new password field
    expect(component.showNewPassword).toBe(false);
    component.togglePasswordVisibility('new');
    expect(component.showNewPassword).toBe(true);
    
    // Test confirm password field
    expect(component.showConfirmPassword).toBe(false);
    component.togglePasswordVisibility('confirm');
    expect(component.showConfirmPassword).toBe(true);
    
    // Test delete password field
    expect(component.showDeletePassword).toBe(false);
    component.togglePasswordVisibility('delete');
    expect(component.showDeletePassword).toBe(true);
  });

  it('should check password input fields', () => {
    // Create mock events
    const mockEvent = (value: string) => ({
      target: { value } as HTMLInputElement
    } as unknown as Event);
    
    // Test current password field
    component.checkPasswordInput('current', mockEvent('password123'));
    expect(component.isCurrentPasswordFilled).toBe(true);
    component.checkPasswordInput('current', mockEvent(''));
    expect(component.isCurrentPasswordFilled).toBe(false);
    
    // Test new password field
    component.checkPasswordInput('new', mockEvent('newPassword123'));
    expect(component.isNewPasswordFilled).toBe(true);
    
    // Test confirm password field
    component.checkPasswordInput('confirm', mockEvent('newPassword123'));
    expect(component.isConfirmPasswordFilled).toBe(true);
    
    // Test delete password field
    component.checkPasswordInput('delete', mockEvent('password123'));
    expect(component.isDeletePasswordFilled).toBe(true);
  });

  it('should validate password matching', () => {
    // Form with matching passwords
    const validForm = {
      get: (field: string) => {
        if (field === 'new_password') return { value: 'test123' };
        if (field === 'password_confirmation') return { value: 'test123' };
        return null;
      }
    };
    
    // Form with non-matching passwords
    const invalidForm = {
      get: (field: string) => {
        if (field === 'new_password') return { value: 'test123' };
        if (field === 'password_confirmation') return { value: 'different123' };
        return null;
      }
    };
    
    // Access the private method through reflection
    const validateMethod = (component as any).passwordMatchValidator;
    
    expect(validateMethod(validForm)).toBeNull();
    expect(validateMethod(invalidForm)).toEqual({ mismatch: true });
  });
});
