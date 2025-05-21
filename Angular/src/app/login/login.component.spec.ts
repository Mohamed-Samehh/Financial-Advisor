import { ComponentFixture, TestBed } from '@angular/core/testing';
import { LoginComponent } from './login.component';
import { AuthService } from '../auth.service';
import { Router } from '@angular/router';
import { FormsModule, NgForm } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { of, throwError } from 'rxjs';
import Swal from 'sweetalert2';

// Mock SweetAlert2
jest.mock('sweetalert2', () => ({
  fire: jest.fn().mockResolvedValue({})
}));

describe('LoginComponent', () => {
  let component: LoginComponent;
  let fixture: ComponentFixture<LoginComponent>;
  let authServiceMock: jest.Mocked<AuthService>;
  let routerMock: jest.Mocked<Router>;

  beforeEach(async () => {
    // Create mock for AuthService and Router
    const authMock = {
      login: jest.fn(),
      setToken: jest.fn(),
      getToken: jest.fn(),
      checkTokenExpiry: jest.fn(),
      forgotPassword: jest.fn()
    };
    
    const router = {
      navigate: jest.fn().mockReturnValue(Promise.resolve(true))
    };

    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        FormsModule,
        RouterModule,
        LoginComponent
      ],
      providers: [
        { provide: AuthService, useValue: authMock },
        { provide: Router, useValue: router }
      ]
    }).compileComponents();

    authServiceMock = TestBed.inject(AuthService) as jest.Mocked<AuthService>;
    routerMock = TestBed.inject(Router) as jest.Mocked<Router>;
  });

  beforeEach(() => {
    // Set up the default return values
    authServiceMock.login.mockReturnValue(of({ token: 'test-token' }));
    authServiceMock.getToken.mockReturnValue(null);
    authServiceMock.checkTokenExpiry.mockReturnValue(false as any);
    authServiceMock.forgotPassword.mockReturnValue(of({ message: 'Password reset email sent' }));

    // Spy on window.location.reload
    jest.spyOn(window.location, 'reload').mockImplementation(() => {});
    
    fixture = TestBed.createComponent(LoginComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should check token and redirect if already logged in', async () => {
    // Set up mocks for an existing valid token
    authServiceMock.getToken.mockReturnValue('valid-token');
    authServiceMock.checkTokenExpiry.mockReturnValue(true as any);
    
    // Trigger ngOnInit
    await component.ngOnInit();
    
    // Should show alert and redirect
    expect(Swal.fire).toHaveBeenCalled();
    expect(routerMock.navigate).toHaveBeenCalledWith(['/dashboard']);
  });

  it('should not redirect if no token or expired token', async () => {
    // No token
    authServiceMock.getToken.mockReturnValue(null);
    
    await component.ngOnInit();
    
    expect(routerMock.navigate).not.toHaveBeenCalled();
    
    // Expired token
    authServiceMock.getToken.mockReturnValue('expired-token');
    authServiceMock.checkTokenExpiry.mockReturnValue(false as any);
    
    await component.ngOnInit();
    
    expect(routerMock.navigate).not.toHaveBeenCalled();
  });

  it('should login user when form is valid', () => {
    // Set up valid form
    component.form = {
      email: 'test@example.com',
      password: 'password123'
    };
    
    const mockForm = {
      valid: true
    } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(authServiceMock.login).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123'
    });
    expect(authServiceMock.setToken).toHaveBeenCalledWith('test-token');
    expect(routerMock.navigate).toHaveBeenCalledWith(['/dashboard']);
  });

  it('should show error message for invalid login credentials', () => {
    // Set up form
    component.form = {
      email: 'test@example.com',
      password: 'wrongpassword'
    };
    
    // Mock error response for invalid credentials
    authServiceMock.login.mockReturnValue(throwError(() => new Error('Invalid credentials')));
    
    const mockForm = {
      valid: true
    } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(component.loading).toBe(false);
    expect(component.loginError).toBe('Invalid email or password. Please try again.');
  });

  it('should not submit if form is invalid', () => {
    const mockForm = {
      valid: false
    } as NgForm;
    
    component.onSubmit(mockForm);
    
    expect(authServiceMock.login).not.toHaveBeenCalled();
  });

  it('should handle forgot password request', () => {
    // Set up email
    component.forgotPasswordEmail = 'test@example.com';
    
    component.onForgotPassword();
    
    expect(authServiceMock.forgotPassword).toHaveBeenCalledWith('test@example.com');
    expect(component.forgotPasswordMessage).toBe('A new password has been sent to your email.');
    expect(component.forgotPasswordError).toBe('');
    expect(component.loadingForgotPassword).toBe(false);
  });

  it('should show error when forgotPasswordEmail is empty', () => {
    component.forgotPasswordEmail = '';
    
    component.onForgotPassword();
    
    expect(authServiceMock.forgotPassword).not.toHaveBeenCalled();
    expect(component.forgotPasswordError).toBe('Please enter a valid email.');
    expect(component.forgotPasswordMessage).toBe('');
  });

  it('should handle error in forgot password request', () => {
    // Set up email
    component.forgotPasswordEmail = 'unknown@example.com';
    
    // Mock error response
    authServiceMock.forgotPassword.mockReturnValue(throwError(() => ({
      message: 'Email not found'
    })));
    
    component.onForgotPassword();
    
    expect(component.forgotPasswordError).toBe('Email not found');
    expect(component.forgotPasswordMessage).toBe('');
    expect(component.loadingForgotPassword).toBe(false);
  });

  it('should toggle password visibility', () => {
    // Initial state
    expect(component.showPassword).toBe(false);
    
    // Toggle on
    component.togglePasswordVisibility();
    expect(component.showPassword).toBe(true);
    
    // Toggle off
    component.togglePasswordVisibility();
    expect(component.showPassword).toBe(false);
  });

  it('should toggle forgot password form visibility', () => {
    // Initial state
    expect(component.showForgotPassword).toBe(false);
    
    // Toggle on
    component.toggleForgotPassword();
    expect(component.showForgotPassword).toBe(true);
    expect(component.forgotPasswordEmail).toBe('');
    expect(component.forgotPasswordMessage).toBe('');
    expect(component.loginError).toBe('');
    
    // Toggle off
    component.toggleForgotPassword();
    expect(component.showForgotPassword).toBe(false);
  });

  it('should check if password field has content', () => {
    // Empty password
    component.form.password = '';
    component.checkPasswordInput();
    expect(component.isPasswordFilled).toBe(false);
    
    // Non-empty password
    component.form.password = 'password123';
    component.checkPasswordInput();
    expect(component.isPasswordFilled).toBe(true);
  });
});
