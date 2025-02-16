import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { AppComponent } from './app/app.component';
import { routes } from './app/app.routes';

// // Backup the original Date constructor
// const RealDate = Date;

// class MockDate extends RealDate {
//   constructor(...args: any[]) {
//     if (args.length === 0) {
//       const tempDate = new RealDate();
//       tempDate.setMonth(tempDate.getMonth() + 1); // Add one month to current date
//       super(tempDate.getTime());
//     } else {
//       super(...args as [any]);
//     }
//   }
// }

// // Override global Date (FOR TESTING ONLY)
// globalThis.Date = MockDate as unknown as DateConstructor;

bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes),
    provideHttpClient(withFetch()),
  ],
}).catch(err => console.error(err));
