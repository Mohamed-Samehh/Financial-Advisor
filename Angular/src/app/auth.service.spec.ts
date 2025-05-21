import { TestBed } from '@angular/core/testing';
import { AuthService } from './auth.service';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { Router } from '@angular/router';

describe('AuthService', () => {
  let service: AuthService;
  let httpMock: HttpTestingController;
  let routerMock: jest.Mocked<Router>;

  beforeEach(() => {
    // Create router mock
    const router = {
      navigate: jest.fn()
    };

    // Create localStorage mock
    const localStorageMock = {
      getItem: jest.fn(),
      setItem: jest.fn(),
      removeItem: jest.fn()
    };
    Object.defineProperty(window, 'localStorage', { value: localStorageMock });
    
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        AuthService,
        { provide: Router, useValue: router }
      ]
    });
    
    service = TestBed.inject(AuthService);
    httpMock = TestBed.inject(HttpTestingController);
    routerMock = TestBed.inject(Router) as jest.Mocked<Router>;
  });

  afterEach(() => {
    httpMock.verify();
    jest.resetAllMocks();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  describe('Token management', () => {
    it('should set token in localStorage', () => {
      const token = 'test-token';
      service.setToken(token);
      expect(localStorage.setItem).toHaveBeenCalledWith('token', token);
    });

    it('should get token from localStorage', () => {
      localStorage.getItem = jest.fn().mockReturnValue('test-token');
      const result = service.getToken();
      expect(localStorage.getItem).toHaveBeenCalledWith('token');
      expect(result).toBe('test-token');
    });

    it('should clear token from localStorage', () => {
      service.clearToken();
      expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    });
  });

  describe('Authentication methods', () => {
    it('should register a new user', () => {
      const userData = { name: 'Test User', email: 'test@example.com' };
      const mockResponse = { message: 'Registration successful' };
      
      service.register(userData).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/register`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(userData);
      req.flush(mockResponse);
    });

    it('should login a user and set token', () => {
      const loginData = { email: 'test@example.com', password: 'password123' };
      const mockResponse = { token: 'test-token' };
      
      service.login(loginData).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/login`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(loginData);
      req.flush(mockResponse);
      
      // Should have set the token
      expect(localStorage.setItem).toHaveBeenCalledWith('token', 'test-token');
    });

    it('should check token expiry and return true if valid', () => {
      localStorage.getItem = jest.fn().mockReturnValue('valid-token');
      const mockResponse = { expired: false };
      
      service.checkTokenExpiry().subscribe(isValid => {
        expect(isValid).toBe(true);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/check-token-expiry`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ token: 'valid-token' });
      req.flush(mockResponse);
    });

    it('should check token expiry and return false if expired', () => {
      localStorage.getItem = jest.fn().mockReturnValue('expired-token');
      const mockResponse = { expired: true };
      
      service.checkTokenExpiry().subscribe(isValid => {
        expect(isValid).toBe(false);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/check-token-expiry`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ token: 'expired-token' });
      req.flush(mockResponse);
      
      // Should have cleared the token and updated session expired subject
      expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    });

    it('should return false if no token exists', () => {
      localStorage.getItem = jest.fn().mockReturnValue(null);
      
      service.checkTokenExpiry().subscribe(isValid => {
        expect(isValid).toBe(false);
      });
      
      // No HTTP request should be made
      httpMock.expectNone(`${(service as any).apiUrl}/check-token-expiry`);
      
      // Should have cleared the token
      expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    });

    it('should handle error in token check', () => {
      localStorage.getItem = jest.fn().mockReturnValue('valid-token');
      
      service.checkTokenExpiry().subscribe(isValid => {
        expect(isValid).toBe(false);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/check-token-expiry`);
      req.error(new ErrorEvent('Network error'));
      
      // Should have cleared the token and updated session expired subject
      expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    });
  });

  describe('User profile methods', () => {
    it('should get user profile', () => {
      localStorage.getItem = jest.fn().mockReturnValue('test-token');
      const mockResponse = { user: { id: '1', name: 'Test User', email: 'test@example.com' } };
      
      service.getProfile().subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/profile`);
      expect(req.request.method).toBe('GET');
      expect(req.request.headers.get('Authorization')).toBe('Bearer test-token');
      req.flush(mockResponse);
    });

    it('should update user profile', () => {
      localStorage.getItem = jest.fn().mockReturnValue('test-token');
      const profileData = { name: 'Updated Name', email: 'updated@example.com' };
      const mockResponse = { message: 'Profile updated successfully' };
      
      service.updateProfile(profileData).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/update-profile`);
      expect(req.request.method).toBe('PUT');
      expect(req.request.headers.get('Authorization')).toBe('Bearer test-token');
      expect(req.request.body).toEqual(profileData);
      req.flush(mockResponse);
    });

    it('should update password', () => {
      localStorage.getItem = jest.fn().mockReturnValue('test-token');
      const passwordData = { current_password: 'oldPassword', new_password: 'newPassword' };
      const mockResponse = { message: 'Password updated successfully' };
      
      service.updatePassword(passwordData).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/update-password`);
      expect(req.request.method).toBe('PUT');
      expect(req.request.headers.get('Authorization')).toBe('Bearer test-token');
      expect(req.request.body).toEqual(passwordData);
      req.flush(mockResponse);
    });

    it('should delete account', () => {
      localStorage.getItem = jest.fn().mockReturnValue('test-token');
      const password = 'password123';
      const mockResponse = { message: 'Account deleted successfully' };
      
      service.deleteAccount(password).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/delete-account`);
      expect(req.request.method).toBe('POST');
      expect(req.request.headers.get('Authorization')).toBe('Bearer test-token');
      expect(req.request.body).toEqual({ password });
      req.flush(mockResponse);
      
      // Should have cleared the token
      expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    });
  });

  describe('Password recovery', () => {
    it('should send forgot password request', () => {
      const email = 'test@example.com';
      const mockResponse = { message: 'Password reset email sent' };
      
      service.forgotPassword(email).subscribe(response => {
        expect(response).toEqual(mockResponse);
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/forgot-password`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ email });
      req.flush(mockResponse);
    });

    it('should handle errors in forgot password request', () => {
      const email = 'unknown@example.com';
      const errorResponse = { message: 'Email not found' };
      
      service.forgotPassword(email).subscribe({
        next: () => fail('Should have failed with error'),
        error: (error) => {
          expect(error.message).toBe(errorResponse.message);
        }
      });
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/forgot-password`);
      expect(req.request.method).toBe('POST');
      req.flush({ message: errorResponse.message }, { status: 404, statusText: 'Not Found' });
    });
  });

  describe('Session expired observer', () => {
    it('should provide observable for session expired status', () => {
      // Initial value should be false
      service.getSessionExpired().subscribe(expired => {
        expect(expired).toBe(false);
      });
      
      // When token expires, value should be true
      localStorage.getItem = jest.fn().mockReturnValue('expired-token');
      const mockResponse = { expired: true };
      
      service.checkTokenExpiry().subscribe();
      
      const req = httpMock.expectOne(`${(service as any).apiUrl}/check-token-expiry`);
      req.flush(mockResponse);
      
      service.getSessionExpired().subscribe(expired => {
        expect(expired).toBe(true);
      });
    });
  });
});
