import { Routes } from '@angular/router';
import { AuthGuard } from './auth.guard';
import { RegisterComponent } from './register/register.component';
import { LoginComponent } from './login/login.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { CategoriesComponent } from './categories/categories.component';
import { ExpensesComponent } from './expenses/expenses.component';
import { BudgetComponent } from './budget/budget.component';
import { GoalsComponent } from './goals/goals.component';
import { AnalyzeExpensesComponent } from './analyze-expenses/analyze-expenses.component';
import { InvestComponent } from './invest/invest.component';
import { ChatbotComponent } from './chatbot/chatbot.component';
import { UserProfileComponent } from './user-profile/user-profile.component';
import { ExpenseHistoryComponent } from './expense-history/expense-history.component';
import { NotFoundComponent } from './not-found/not-found.component';

export const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent, canActivate: [AuthGuard] },
  { path: 'budget', component: BudgetComponent, canActivate: [AuthGuard] },
  { path: 'goal', component: GoalsComponent, canActivate: [AuthGuard] },
  { path: 'categories', component: CategoriesComponent, canActivate: [AuthGuard] },
  { path: 'expenses', component: ExpensesComponent, canActivate: [AuthGuard] },
  { path: 'analyze', component: AnalyzeExpensesComponent, canActivate: [AuthGuard] },
  { path: 'invest', component: InvestComponent, canActivate: [AuthGuard] },
  { path: 'history', component: ExpenseHistoryComponent, canActivate: [AuthGuard] },
  { path: 'chat', component: ChatbotComponent, canActivate: [AuthGuard] },
  { path: 'account', component: UserProfileComponent, canActivate: [AuthGuard] },
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: '**', component: NotFoundComponent }
];
