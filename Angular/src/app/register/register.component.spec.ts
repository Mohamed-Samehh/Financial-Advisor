import { ComponentFixture, TestBed } from '@angular/core/testing';
import { RegisterComponent } from './register.component';
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

describe('RegisterComponent', () => {
  let component: RegisterComponent;
  let fixture: ComponentFixture<RegisterComponent>;
  let authServiceMock: jest.Mocked<AuthService>;
  let routerMock: jest.Mocked<Router>;

  beforeEach(async () => {
    // Create mock for AuthService and Router
    const authMock = {
      register: jest.fn(),
      getToken: jest.fn(),
      checkTokenExpiry: jest.fn()
    };
    
    const router = {
      navigate: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        FormsModule,
        RouterModule,
        RegisterComponent
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
    authServiceMock.register.mockReturnValue(of({ message: 'Registration successful' }));
    authServiceMock.getToken.mockReturnValue(null);
    authServiceMock.checkTokenExpiry.mockReturnValue(false as any);

    fixture = TestBed.createComponent(RegisterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
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

  it('should register a user when form is valid', async () => {
    // Set up valid form
    component.form = {
      name: 'Test User',
      email: 'test@example.com'
    };
    
    const mockForm = {
      valid: true
    } as NgForm;
    
    await component.onSubmit(mockForm);
    
    expect(authServiceMock.register).toHaveBeenCalledWith({
      name: 'Test User',
      email: 'test@example.com'
    });
    expect(component.isLoading).toBe(false);
    expect(Swal.fire).toHaveBeenCalled();
    // Check the first argument of the first call
    const fireArgs = (Swal.fire as jest.Mock).mock.calls[0][0];
    expect(fireArgs.title).toBe("Registration Successful");
    expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
  });

  it('should show error message when email is already registered', async () => {
    // Set up form
    component.form = {
      name: 'Test User',
      email: 'existing@example.com'
    };
    
    // Mock error response for existing email
    authServiceMock.register.mockReturnValue(throwError(() => ({
      error: { error: 'The email is already registered.' }
    })));
    
    const mockForm = {
      valid: true
    } as NgForm;
    
    await component.onSubmit(mockForm);
    
    expect(component.isLoading).toBe(false);
    expect(component.message).toEqual({ 
      text: 'This email is already registered. Please use a different one.' 
    });
    expect(routerMock.navigate).not.toHaveBeenCalled();
  });

  it('should show generic error message for other registration errors', async () => {
    // Set up form
    component.form = {
      name: 'Test User',
      email: 'test@example.com'
    };
    
    // Mock generic error response
    authServiceMock.register.mockReturnValue(throwError(() => ({
      error: { error: 'Server error' }
    })));
    
    const mockForm = {
      valid: true
    } as NgForm;
    
    await component.onSubmit(mockForm);
    
    expect(component.isLoading).toBe(false);
    expect(component.message).toEqual({ 
      text: 'Error occurred during registration. Please try again.' 
    });
    expect(routerMock.navigate).not.toHaveBeenCalled();
  });

  it('should not submit if form is invalid', async () => {
    const mockForm = {
      valid: false
    } as NgForm;
    
    await component.onSubmit(mockForm);
    
    expect(authServiceMock.register).not.toHaveBeenCalled();
    expect(component.message).toEqual({ text: 'Please fill out the form correctly.' });
  });
});
