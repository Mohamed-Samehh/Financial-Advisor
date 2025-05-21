import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ChatbotComponent } from './chatbot.component';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { of, throwError } from 'rxjs';
import { marked } from 'marked';

// Mock marked library
jest.mock('marked', () => ({
  parse: jest.fn().mockImplementation((text) => `<p>${text}</p>`)
}));

describe('ChatbotComponent', () => {
  let component: ChatbotComponent;
  let fixture: ComponentFixture<ChatbotComponent>;
  let apiServiceMock: jest.Mocked<ApiService>;

  beforeEach(async () => {
    // Create mock for ApiService
    const apiMock = {
      sendChatMessage: jest.fn()
    };

    await TestBed.configureTestingModule({
      imports: [
        FormsModule, 
        CommonModule,
        ChatbotComponent
      ],
      providers: [
        { provide: ApiService, useValue: apiMock }
      ]
    }).compileComponents();

    apiServiceMock = TestBed.inject(ApiService) as jest.Mocked<ApiService>;
    apiServiceMock.sendChatMessage.mockReturnValue(of({ message: 'This is a response from the chatbot' }));

    fixture = TestBed.createComponent(ChatbotComponent);
    component = fixture.componentInstance;
    
    // Create mock textarea for adjustHeight test
    const mockTextarea = document.createElement('textarea');
    document.body.appendChild(mockTextarea);
    
    fixture.detectChanges();
  });

  afterEach(() => {
    const textarea = document.querySelector('textarea');
    if (textarea) {
      document.body.removeChild(textarea);
    }
    
    // Reset the timers
    jest.useRealTimers();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should not send empty messages', () => {
    component.userMessage = '   ';
    component.sendMessage();
    expect(apiServiceMock.sendChatMessage).not.toHaveBeenCalled();
    expect(component.messages.length).toBe(0);
  });

  it('should send user message and display bot response', () => {
    component.userMessage = 'Hello bot';
    component.sendMessage();
    
    expect(apiServiceMock.sendChatMessage).toHaveBeenCalledWith('Hello bot');
    expect(component.messages.length).toBe(2);
    expect(component.messages[0]).toEqual({ role: 'user', content: 'Hello bot' });
    expect(component.messages[1]).toEqual({ 
      role: 'bot', 
      content: '<p>This is a response from the chatbot</p>' 
    });
    expect(component.loading).toBe(false);
    expect(component.userMessage).toBe('');
  });

  it('should handle error when sending message', () => {
    apiServiceMock.sendChatMessage.mockReturnValue(
      throwError(() => new Error('Error sending message'))
    );
    
    component.userMessage = 'Hello bot';
    component.sendMessage();
    
    expect(apiServiceMock.sendChatMessage).toHaveBeenCalledWith('Hello bot');
    expect(component.messages.length).toBe(1); // Only user message remains
    expect(component.loading).toBe(false);
    expect(component.errorMessage).toBe('Failed to get a response. Please try again.');
  });

  it('should handle empty response from API', () => {
    apiServiceMock.sendChatMessage.mockReturnValue(of({}));
    
    component.userMessage = 'Hello bot';
    component.sendMessage();
    
    expect(apiServiceMock.sendChatMessage).toHaveBeenCalledWith('Hello bot');
    expect(component.messages.length).toBe(2);
    expect(component.messages[1].content).toContain("I'm sorry, but I couldn't generate a response");
  });

  it('should format messages correctly', () => {
    const result = component.formatMessage('Hello\nWorld');
    expect(result).toBe('Hello<br>World');
  });

  it('should format responses using marked parser', () => {
    const result = component.formatResponse('# Hello World');
    expect(marked.parse).toHaveBeenCalledWith('# Hello World');
    expect(result).toBe('<p># Hello World</p>');
  });

  it('should adjust textarea height when content changes', () => {
    const textarea = document.querySelector('textarea') as HTMLTextAreaElement;
    const event = { target: textarea };
    
    // Test with empty content
    textarea.value = '';
    component.adjustHeight(event);
    expect(textarea.style.height).toBe('40px');
    
    // Test with non-empty content
    textarea.value = 'Hello World';
    Object.defineProperty(textarea, 'scrollHeight', { value: 100 });
    component.adjustHeight(event);
    expect(textarea.style.height).toBe('100px');
  });

  it('should send message on Ctrl+Enter', () => {
    const sendMessageSpy = jest.spyOn(component, 'sendMessage').mockImplementation(() => {});
    
    // Not Ctrl+Enter
    const regularEvent = new KeyboardEvent('keydown', { key: 'Enter' });
    component.onKeyDown(regularEvent);
    expect(sendMessageSpy).not.toHaveBeenCalled();
    
    // Ctrl+Enter
    const ctrlEnterEvent = new KeyboardEvent('keydown', { 
      key: 'Enter', 
      ctrlKey: true 
    });
    component.onKeyDown(ctrlEnterEvent);
    expect(sendMessageSpy).toHaveBeenCalled();
  });

  it('should scroll to bottom when messages are added', () => {
    // Mock timers
    jest.useFakeTimers();
    
    // Create a mock chat element
    const chatMock = document.createElement('div');
    chatMock.classList.add('chat');
    document.body.appendChild(chatMock);
    
    // Set up the spy on scrollTop
    Object.defineProperty(chatMock, 'scrollHeight', { value: 1000 });
    
    component.scrollToBottom();
    
    // Use setTimeout to allow the setTimeout in the component to execute
    jest.runAllTimers();
    
    expect(chatMock.scrollTop).toBe(1000);
    
    // Clean up
    document.body.removeChild(chatMock);
  });
});
