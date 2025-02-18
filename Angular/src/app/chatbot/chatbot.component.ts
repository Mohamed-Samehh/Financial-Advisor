import { Component } from '@angular/core';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-chatbot',
  standalone: true,
  imports: [FormsModule, CommonModule],
  templateUrl: './chatbot.component.html',
  styleUrl: './chatbot.component.css'
})
export class ChatbotComponent {
  messages: { role: string, content: string }[] = [];
  userMessage: string = '';
  errorMessage: string | null = null;
  loading: boolean = false;

  constructor(private apiService: ApiService) {}

  sendMessage() {
    if (!this.userMessage.trim()) return;

    this.messages.push({ role: 'user', content: this.userMessage });
    const messageToSend = this.userMessage;
    this.userMessage = '';
    
    this.loading = true;

    this.apiService.sendChatMessage(messageToSend).subscribe(
      (response) => {
        this.loading = false;
        if (response.message) {
          this.messages.push({ role: 'bot', content: response.message });
        } else {
          this.messages.push({ role: 'bot', content: 'No response received.' });
        }
      },
      (error) => {
        this.loading = false;
        this.errorMessage = 'Failed to get a response. Please try again.';
        console.error('Error:', error);
      }
    );
  }
}
