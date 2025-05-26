import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ChatbotComponent } from './chatbot.component';
import { ApiService } from '../api.service';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { of, throwError } from 'rxjs';
import { marked } from 'marked';

// Mock marked library with proper structure
jest.mock('marked', () => ({
  marked: {
    parse: jest.fn().mockImplementation((text) => `<p>${text}</p>`)
  }
}));

describe('ChatbotComponent', () => {
  let component: ChatbotComponent;
  let fixture: ComponentFixture<ChatbotComponent>;
  let apiServiceMock: jest.Mocked<ApiService>;
  let consoleErrorSpy: jest.SpyInstance;

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

    // Mock console.error to prevent error output during tests
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

    apiServiceMock = TestBed.inject(ApiService) as jest.Mocked<ApiService>;
    apiServiceMock.sendChatMessage.mockReturnValue(of({ message: 'This is a response from the chatbot' }));

    fixture = TestBed.createComponent(ChatbotComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    // Restore console.error after each test
    consoleErrorSpy.mockRestore();
    
    // Clean up any textarea elements that might exist
    const textareas = document.querySelectorAll('textarea');
    textareas.forEach(textarea => {
      if (textarea.parentNode) {
        textarea.parentNode.removeChild(textarea);
      }
    });
    
    // Clean up any chat elements
    const chatElements = document.querySelectorAll('.chat');
    chatElements.forEach(chat => {
      if (chat.parentNode) {
        chat.parentNode.removeChild(chat);
      }
    });
    
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

  it('should send user message and display bot response', async () => {
    component.userMessage = 'Hello bot';
    
    // Call sendMessage and wait for async operations
    component.sendMessage();
    
    // Wait for the observable to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
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

  it('should handle error when sending message', async () => {
    apiServiceMock.sendChatMessage.mockReturnValue(
      throwError(() => new Error('Error sending message'))
    );
    
    component.userMessage = 'Hello bot';
    component.sendMessage();
    
    // Wait for the observable to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
    expect(apiServiceMock.sendChatMessage).toHaveBeenCalledWith('Hello bot');
    expect(component.messages.length).toBe(1); // Only user message remains
    expect(component.loading).toBe(false);
    expect((component as any).errorMessage).toBe('Failed to get a response. Please try again.');
    
    // Verify console.error was called
    expect(consoleErrorSpy).toHaveBeenCalled();
  });

  it('should handle empty response from API', async () => {
    apiServiceMock.sendChatMessage.mockReturnValue(of({}));
    
    component.userMessage = 'Hello bot';
    component.sendMessage();
    
    // Wait for the observable to complete
    await new Promise(resolve => setTimeout(resolve, 0));
    
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
    // Create a real textarea element for this test
    const textarea = document.createElement('textarea');
    document.body.appendChild(textarea);
    
    const event = { target: textarea };
    
    // Test with empty content
    textarea.value = '';
    component.adjustHeight(event);
    expect(textarea.style.height).toBe('40px');
    
    // Test with non-empty content
    textarea.value = 'Hello World';
    Object.defineProperty(textarea, 'scrollHeight', { 
      value: 100,
      configurable: true 
    });
    component.adjustHeight(event);
    expect(textarea.style.height).toBe('100px');
    
    // Clean up
    document.body.removeChild(textarea);
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
    
    // Restore the spy
    sendMessageSpy.mockRestore();
  });

  it('should scroll to bottom when messages are added', () => {
    // Mock timers
    jest.useFakeTimers();
    
    // Create a mock chat element
    const chatMock = document.createElement('div');
    chatMock.classList.add('chat');
    document.body.appendChild(chatMock);
    
    // Mock scrollTop as writable property
    let scrollTopValue = 0;
    Object.defineProperty(chatMock, 'scrollTop', { 
      get: () => scrollTopValue,
      set: (value) => { scrollTopValue = value; },
      configurable: true
    });
    
    Object.defineProperty(chatMock, 'scrollHeight', { 
      value: 1000,
      configurable: true 
    });
    
    // Mock document.querySelector to return our mock element
    const originalQuerySelector = document.querySelector;
    document.querySelector = jest.fn().mockImplementation((selector) => {
      if (selector === '.chat') {
        return chatMock;
      }
      return originalQuerySelector.call(document, selector);
    });
    
    // Call scrollToBottom
    component.scrollToBottom();
    
    // Advance timers to trigger the setTimeout callback
    jest.advanceTimersByTime(1);
    
    expect(scrollTopValue).toBe(1000);
    
    // Restore original querySelector
    document.querySelector = originalQuerySelector;
    
    // Clean up
    document.body.removeChild(chatMock);
    jest.useRealTimers();
  });
});
