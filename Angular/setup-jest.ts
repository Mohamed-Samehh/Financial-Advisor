import { setupZoneTestEnv } from 'jest-preset-angular/setup-env/zone';

// Set up Angular Zone testing environment
setupZoneTestEnv();

// Global mocks for browser objects
Object.defineProperty(window, 'CSS', { value: null });
Object.defineProperty(document, 'doctype', {
  value: '<!DOCTYPE html>'
});
Object.defineProperty(document.body.style, 'transform', {
  value: () => {
    return {
      enumerable: true,
      configurable: true
    };
  }
});
