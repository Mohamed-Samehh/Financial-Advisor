import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';
import { RouterTestingModule } from '@angular/router/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { Component } from '@angular/core';
import { of, throwError } from 'rxjs';

// Create a dummy component for routing tests
@Component({
  template: '<div>Test Component</div>'
})
class TestComponent { }

describe('AppComponent', () => {
  let component: AppComponent;
  let fixture: ComponentFixture<AppComponent>;
  let httpClientSpy: jest.SpyInstance;
  let routerMock: Router;

  beforeEach(async () => {
    // Create localStorage mock
    const localStorageMock = {
      getItem: jest.fn(),
      setItem: jest.fn(),
      removeItem: jest.fn()
    };
    Object.defineProperty(window, 'localStorage', { value: localStorageMock });

    await TestBed.configureTestingModule({
      imports: [
        RouterTestingModule.withRoutes([
          { path: 'login', component: TestComponent },
          { path: 'dashboard', component: TestComponent },
          { path: '', redirectTo: '/login', pathMatch: 'full' }
        ]),
        HttpClientTestingModule,
        AppComponent
      ],
      declarations: [TestComponent]
    }).compileComponents();

    routerMock = TestBed.inject(Router);
    
    // Spy on router navigate method
    jest.spyOn(routerMock, 'navigate').mockResolvedValue(true);
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(AppComponent);
    component = fixture.componentInstance;
    
    // Create spy for HttpClient.post method
    httpClientSpy = jest.spyOn(component['http'], 'post');
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should create the app', () => {
    // Mock no token to avoid HTTP call
    (localStorage.getItem as jest.Mock).mockReturnValue(null);
    fixture.detectChanges();
    expect(component).toBeTruthy();
  });

  it('should have the correct title', () => {
    expect(component.title).toEqual('frontend');
  });

  it('should check token expiry on initialization if token exists', () => {
    // Mock the token
    (localStorage.getItem as jest.Mock).mockReturnValue('valid-token');
    
    // Mock successful HTTP response
    httpClientSpy.mockReturnValue(of({ expired: false }));
    
    fixture.detectChanges(); // This triggers ngOnInit
    
    expect(httpClientSpy).toHaveBeenCalledWith('http://localhost:8000/api/check-token-expiry', { token: 'valid-token' });
    expect(component.isLoggedIn).toBe(true);
    expect(routerMock.navigate).not.toHaveBeenCalled();
  });

  it('should clear token and redirect if token is expired', () => {
    // Mock expired token
    (localStorage.getItem as jest.Mock).mockReturnValue('expired-token');
    
    // Mock HTTP response indicating expired token
    httpClientSpy.mockReturnValue(of({ expired: true }));
    
    fixture.detectChanges(); // This triggers ngOnInit
    
    expect(httpClientSpy).toHaveBeenCalledWith('http://localhost:8000/api/check-token-expiry', { token: 'expired-token' });
    expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    expect(component.isLoggedIn).toBe(false);
    expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
  });

  it('should clear token and redirect on token check error', () => {
    // Mock token
    (localStorage.getItem as jest.Mock).mockReturnValue('token');
    
    // Mock HTTP error
    httpClientSpy.mockReturnValue(throwError(() => new Error('Network error')));
    
    fixture.detectChanges(); // This triggers ngOnInit
    
    expect(httpClientSpy).toHaveBeenCalledWith('http://localhost:8000/api/check-token-expiry', { token: 'token' });
    expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    expect(component.isLoggedIn).toBe(false);
    expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
  });

  it('should not check token expiry if no token exists', () => {
    // Mock no token
    (localStorage.getItem as jest.Mock).mockReturnValue(null);
    
    fixture.detectChanges(); // This triggers ngOnInit
    
    // No HTTP request should be made
    expect(httpClientSpy).not.toHaveBeenCalled();
    expect(localStorage.removeItem).toHaveBeenCalledWith('token');
    expect(component.isLoggedIn).toBe(false);
  });

  it('should toggle navbar visibility', () => {
    // Mock no token to avoid HTTP call
    (localStorage.getItem as jest.Mock).mockReturnValue(null);
    
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
    // Mock no token to avoid HTTP call
    (localStorage.getItem as jest.Mock).mockReturnValue(null);
    
    // Set navbar to visible
    component.isNavbarVisible = true;
    
    // Close navbar
    component.closeNavbar();
    expect(component.isNavbarVisible).toBe(false);
  });

  it('should logout user', () => {
    // Mock no token to avoid HTTP call
    (localStorage.getItem as jest.Mock).mockReturnValue(null);
    
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
    (localStorage.getItem as jest.Mock).mockReturnValue(token);
    
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
