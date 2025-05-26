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

// Suppress deprecation warnings during tests
const originalWrite = process.stderr.write;
process.stderr.write = function(string: string | Uint8Array, encoding?: BufferEncoding | ((err?: Error) => void), fd?: (err?: Error) => void): boolean {
  // Filter out punycode deprecation warnings
  if (typeof string === 'string' && string.includes('DeprecationWarning: The `punycode` module is deprecated')) {
    return true;
  }
  
  // Call the original write function for other messages
  if (typeof encoding === 'function') {
    return (originalWrite as any).call(this, string, encoding);
  } else if (typeof fd === 'function') {
    return (originalWrite as any).call(this, string, encoding, fd);
  } else {
    return (originalWrite as any).call(this, string, encoding);
  }
};
