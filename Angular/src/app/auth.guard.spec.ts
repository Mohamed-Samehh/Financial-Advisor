import { TestBed } from '@angular/core/testing';
import { Router, ActivatedRouteSnapshot, RouterStateSnapshot } from '@angular/router';
import { AuthGuard } from './auth.guard';
import { AuthService } from './auth.service';
import { of, BehaviorSubject } from 'rxjs';
import Swal from 'sweetalert2';

// Mock SweetAlert2
jest.mock('sweetalert2', () => ({
  fire: jest.fn().mockResolvedValue({})
}));

describe('AuthGuard', () => {
  let authGuard: AuthGuard;
  let authServiceMock: jest.Mocked<AuthService>;
  let routerMock: jest.Mocked<Router>;
  let route: ActivatedRouteSnapshot;
  let state: RouterStateSnapshot;
  
  // Mock session expired subject
  const sessionExpiredSubject = new BehaviorSubject<boolean>(false);

  beforeEach(() => {
    // Create mocks
    const authMock = {
      checkTokenExpiry: jest.fn(),
      getSessionExpired: jest.fn().mockReturnValue(sessionExpiredSubject.asObservable())
    };
    
    const router = {
      navigate: jest.fn().mockReturnValue(Promise.resolve(true))
    };

    // Mock window.location.reload
    Object.defineProperty(window, 'location', {
      value: { reload: jest.fn() },
      writable: true
    });

    TestBed.configureTestingModule({
      providers: [
        AuthGuard,
        { provide: AuthService, useValue: authMock },
        { provide: Router, useValue: router }
      ]
    });

    authGuard = TestBed.inject(AuthGuard);
    authServiceMock = TestBed.inject(AuthService) as jest.Mocked<AuthService>;
    routerMock = TestBed.inject(Router) as jest.Mocked<Router>;

    // Create mock route and state
    route = {} as ActivatedRouteSnapshot;
    state = {} as RouterStateSnapshot;
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  it('should be created', () => {
    expect(authGuard).toBeTruthy();
  });

  it('should allow access if token is valid', (done) => {
    // Token is valid
    authServiceMock.checkTokenExpiry.mockReturnValue(of(true));

    (authGuard.canActivate(route, state) as any).subscribe((result: boolean) => {
      expect(result).toBe(true);
      expect(routerMock.navigate).not.toHaveBeenCalled();
      done();
    });
  });

  it('should redirect to login if token is invalid but not expired', (done) => {
    // Token is invalid
    authServiceMock.checkTokenExpiry.mockReturnValue(of(false));
    // Session is not explicitly expired
    sessionExpiredSubject.next(false);

    (authGuard.canActivate(route, state) as any).subscribe((result: boolean) => {
      expect(result).toBe(false);
      expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
      expect(window.location.reload).toHaveBeenCalled();
      expect(Swal.fire).not.toHaveBeenCalled(); // No alert for regular invalid token
      done();
    });
  });

  it('should show session expired alert if session is explicitly expired', (done) => {
    // Token is invalid
    authServiceMock.checkTokenExpiry.mockReturnValue(of(false));
    // Session is explicitly expired
    sessionExpiredSubject.next(true);

    (authGuard.canActivate(route, state) as any).subscribe((result: boolean) => {
      expect(result).toBe(false);
      expect(Swal.fire).toHaveBeenCalled();
      // Check the first argument of the first call
      const fireArgs = (Swal.fire as jest.Mock).mock.calls[0][0];
      expect(fireArgs.title).toBe("Session Expired");
      expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
      expect(window.location.reload).toHaveBeenCalled();
      done();
    });
  });
});
