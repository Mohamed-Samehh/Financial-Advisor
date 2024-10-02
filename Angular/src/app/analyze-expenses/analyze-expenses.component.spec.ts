import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AnalyzeExpensesComponent } from './analyze-expenses.component';

describe('AnalyzeExpensesComponent', () => {
  let component: AnalyzeExpensesComponent;
  let fixture: ComponentFixture<AnalyzeExpensesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AnalyzeExpensesComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(AnalyzeExpensesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
