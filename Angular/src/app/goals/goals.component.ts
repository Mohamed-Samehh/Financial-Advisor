import { Component, OnInit } from '@angular/core';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-goals',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './goals.component.html',
  styleUrls: ['./goals.component.css'],
})
export class GoalsComponent implements OnInit {
  goals: any[] = [];
  goal: any = { name: '', target_amount: null, time_frame: null };
  goalSaved: boolean = false;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.apiService.getGoals().subscribe((res) => (this.goals = res));
  }

  onSubmit() {
    this.apiService.addGoal(this.goal).subscribe((res) => {
      this.goals.push(res);
      this.goalSaved = true;
      this.goal = { name: '', target_amount: null, time_frame: null };
    });
  }
}
