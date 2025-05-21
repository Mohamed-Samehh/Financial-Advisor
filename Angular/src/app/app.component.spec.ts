import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';
import { RouterTestingModule } from '@angular/router/testing';
import { CommonModule } from '@angular/common';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { HttpClientModule } from '@angular/common/http';
import { Router } from '@angular/router';

describe('AppComponent', () => {
  let component: AppComponent;
  let fixture: ComponentFixture<AppComponent>;
  let httpMock: HttpTestingController;
  let routerMock: jest.Mocked<Router>;

  beforeEach(async () => {
    // Create localStorage mock
    const localStorageMock = {
      getItem: jest.fn(),
      setItem: jest.fn(),
      removeItem: jest.fn()
    };
    Object.defineProperty(window, 'localStorage', { value: localStorageMock });

    // Create router mock
    const router = {
      navigate: jest.fn()
    };
    
    await TestBed.configureTestingModule({
      imports: [
        CommonModule,
        RouterTestingModule,
        HttpClientModule,
        HttpClientTestingModule,
        AppComponent
      ],
      providers: [
        { provide: Router, useValue: router }
      ]
    }).compileComponents();

    httpMock = TestBed.inject(HttpTestingController);
    routerMock = TestBed.inject(Router) as jest.Mocked<Router>;
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(AppComponent);
    component = fixture.componentInstance;
  });

  afterEach(() => {
    httpMock.verify();
    jest.resetAllMocks();
  });

  it('should create the app', () => {
    expect(component).toBeTruthy();
  });

  it('should have the correct title', () => {
    expect(component.title).toEqual('frontend');
  });

  it('should check token expiry on initialization if token exists', () => {
    // Mock the token
    localStorage.getItem = jest.fn().mockReturnValue('valid-token');
    component.ngOnInit();
    
    const req = httpMock.expectOne('http://localhost:8000/api/check-token-expiry');
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({ token: 'valid-token' });
    req.flush({ expired: false });
    
    expect(component.isLoggedIn).toBe(true);
    expect(routerMock.navigate).not.toHaveBeenCalled();
  });

  it('should clear token and redirect if token is expired', () => {
    // Mock expired token
    localStorage.getItem = jest.fn().mockReturnValue('expired-token');
    component.ngOnInit();
    
    const req = httpMock.expectOne('http://localhost:8000/api/check-token-expiry');
    expect(req.request.method).toBe('POST');
    req.flush({ expired: true });
    
    expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    expect(component.isLoggedIn).toBe(false);
    expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
  });

  it('should clear token and redirect on token check error', () => {
    // Mock token
    localStorage.getItem = jest.fn().mockReturnValue('token');
    component.ngOnInit();
    
    const req = httpMock.expectOne('http://localhost:8000/api/check-token-expiry');
    expect(req.request.method).toBe('POST');
    req.error(new ErrorEvent('Network error'));
    
    expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    expect(component.isLoggedIn).toBe(false);
    expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
  });

  it('should not check token expiry if no token exists', () => {
    // Mock no token
    localStorage.getItem = jest.fn().mockReturnValue(null);
    component.ngOnInit();
    
    // No HTTP request should be made
    httpMock.expectNone('http://localhost:8000/api/check-token-expiry');
    
    expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    expect(component.isLoggedIn).toBe(false);
  });

  it('should toggle navbar visibility', () => {
    // Initial state
    expect(component.isNavbarVisible).toBe(false);
    
    // Toggle on
    component.toggleNavbar();
    expect(component.isNavbarVisible).toBe(true);
    
    // Toggle off
    component.toggleNavbar();
    expect(component.isNavbarVisible).toBe(false);
  });

  it('should close navbar', () => {
    // Set navbar to visible
    component.isNavbarVisible = true;
    
    // Close navbar
    component.closeNavbar();
    expect(component.isNavbarVisible).toBe(false);
  });

  it('should logout user', () => {
    // Mock logged-in state
    component.isLoggedIn = true;
    
    // Logout
    component.logout();
    
    expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    expect(component.isLoggedIn).toBe(false);
    expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
  });

  it('should get token from localStorage', () => {
    // Mock token
    const token = 'test-token';
    localStorage.getItem = jest.fn().mockReturnValue(token);
    
    const result = component.getToken();
    
    expect(localStorage.getItem).toHaveBeenCalledWith('token');
    expect(result).toBe(token);
  });

  it('should clear token from localStorage', () => {
    component.clearToken();
    
    expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    expect(component.isLoggedIn).toBe(false);
  });
});
