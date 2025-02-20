import { Component } from '@angular/core';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { marked } from 'marked';

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
          this.messages.push({ role: 'bot', content: this.formatResponse(response.message) });
        } else {
          this.messages.push({ role: 'bot', content: "I'm sorry, but I couldn't generate a response. Please try again or ask in a different way." });
        }
      },
      (error) => {
        this.loading = false;
        this.errorMessage = 'Failed to get a response. Please try again.';
        console.error('Error:', error);
      }
    );

    const textarea = document.querySelector('textarea');
    if (textarea) {
      textarea.style.height = "40px";
    }
  }

  adjustHeight(event: any) {
    const textarea = event.target;

    if (!textarea.value.trim()) {
      textarea.style.height = "40px";
    } else {
      textarea.style.height = "auto";
      textarea.style.height = `${textarea.scrollHeight}px`;
    }
  }

  onKeyDown(event: KeyboardEvent): void {
    if (event.ctrlKey && event.key === 'Enter') {
      this.sendMessage();
    }
  }

  formatMessage(content: string): string {
    return content.replace(/\n/g, '<br>');
  }

  // Convert Markdown to HTML using marked.js
  formatResponse(text: string): string {
    const result = marked.parse(text);
    return typeof result === 'string' ? result : '';
  }
}
