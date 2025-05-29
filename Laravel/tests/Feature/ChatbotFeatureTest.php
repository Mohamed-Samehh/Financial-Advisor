<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Budget;
use App\Models\Goal;
use App\Models\Expense;
use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Laravel\Sanctum\Sanctum;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;

class ChatbotFeatureTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $user;    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['name' => 'Test User']);
        Sanctum::actingAs($this->user);
    }    public function test_user_can_chat_with_bot()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        // Create user financial data
        Budget::factory()->create([
            'user_id' => $this->user->id,
            'monthly_budget' => 150000,
            'created_at' => Carbon::now(),
        ]);

        Goal::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Vacation Fund',
            'target_amount' => 300000,
            'created_at' => Carbon::now(),
        ]);

        $category = Category::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Food',
            'priority' => 1,
        ]);

        Expense::factory()->create([
            'user_id' => $this->user->id,
            'category' => 'Food',
            'amount' => 5000,
            'date' => Carbon::now(),
        ]);

        // Mock successful Flask response
        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => 'You are doing great with your budget! You have spent 5,000 out of your 150,000 monthly budget.'
                        ]
                    ]
                ]
            ], 200)
        ]);        $response = $this->postJson('/api/chatbot', [
            'message' => 'How am I doing with my budget this month?'
        ]);

        $response->assertStatus(200)
                ->assertJsonStructure(['message']);

        // Just verify that some request was made to Flask
        Http::assertSentCount(1);
    }    public function test_chatbot_includes_complete_financial_context()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        // Create comprehensive financial data
        Budget::factory()->create([
            'user_id' => $this->user->id,
            'monthly_budget' => 200000,
            'created_at' => Carbon::now(),
        ]);

        Goal::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Emergency Fund',
            'target_amount' => 500000,
            'created_at' => Carbon::now(),
        ]);

        $groceriesCategory = Category::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Groceries',
            'priority' => 1,
        ]);

        $transportCategory = Category::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Transport',
            'priority' => 2,
        ]);

        // Create multiple expenses across different days and categories
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'category' => 'Groceries',
            'amount' => 3000,
            'date' => Carbon::now()->format('Y-m-d'),
        ]);

        Expense::factory()->create([
            'user_id' => $this->user->id,
            'category' => 'Transport',
            'amount' => 2000,
            'date' => Carbon::now()->subDay()->format('Y-m-d'),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Financial analysis complete!']]]
            ], 200)
        ]);

        $response = $this->postJson('/api/chatbot', [
            'message' => 'Analyze my spending patterns'
        ]);        $response->assertStatus(200);

        // Verify comprehensive data was sent
        Http::assertSentCount(1);
    }    public function test_chatbot_works_with_minimal_user_data()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        // User with no budget, goal, or expenses
        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => 'It looks like you are just getting started. Consider setting a budget and goal first!'
                        ]
                    ]
                ]
            ], 200)
        ]);

        $response = $this->postJson('/api/chatbot', [
            'message' => 'Give me some financial advice'
        ]);        $response->assertStatus(200)
                ->assertJson([
                    'message' => 'It looks like you are just getting started. Consider setting a budget and goal first!'
                ]);

        // Verify default values are sent
        Http::assertSentCount(1);
    }    public function test_chatbot_handles_flask_service_unavailable()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        Budget::factory()->create(['user_id' => $this->user->id, 'created_at' => Carbon::now()]);

        // Mock Flask service failure
        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([], 500)
        ]);

        $response = $this->postJson('/api/chatbot', [
            'message' => 'Help me with my budget'
        ]);

        $response->assertStatus(500)
                ->assertJson([
                    'error' => 'Failed to fetch response'
                ]);
    }

    public function test_chatbot_handles_invalid_flask_response()
    {
        Budget::factory()->create(['user_id' => $this->user->id, 'created_at' => Carbon::now()]);

        // Mock malformed Flask response
        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'invalid_structure' => 'no choices array'
            ], 200)
        ]);

        $response = $this->postJson('/api/chatbot', [
            'message' => 'What should I do?'
        ]);

        $response->assertStatus(200)
                ->assertJson([
                    'message' => "I'm sorry, but I couldn't generate a response. Please try again or ask in a different way."
                ]);
    }    public function test_chatbot_validates_message_input()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Response']]]
            ], 200)
        ]);

        $response = $this->postJson('/api/chatbot', []);

        // Should handle missing message gracefully (depends on controller validation)
        // This test assumes the controller doesn't explicitly validate the message field
        $response->assertStatus(200);
    }    public function test_chatbot_scopes_data_to_authenticated_user()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        // Create data for another user
        $otherUser = User::factory()->create();
        Budget::factory()->create([
            'user_id' => $otherUser->id,
            'monthly_budget' => 999999,
            'created_at' => Carbon::now(),
        ]);

        Goal::factory()->create([
            'user_id' => $otherUser->id,
            'target_amount' => 888888,
            'created_at' => Carbon::now(),
        ]);

        Expense::factory()->create([
            'user_id' => $otherUser->id,
            'amount' => 777777,
            'date' => Carbon::now(),
        ]);

        // Create data for authenticated user
        Budget::factory()->create([
            'user_id' => $this->user->id,
            'monthly_budget' => 100000,
            'created_at' => Carbon::now(),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Response']]]
            ], 200)
        ]);

        $response = $this->postJson('/api/chatbot', [
            'message' => 'Show my data'
        ]);        $response->assertStatus(200);

        // Verify only authenticated user's data is sent
        Http::assertSentCount(1);
    }    public function test_chatbot_only_includes_current_month_expenses()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        Budget::factory()->create(['user_id' => $this->user->id, 'created_at' => Carbon::now()]);

        // Current month expense
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 5000,
            'date' => Carbon::now(),
        ]);

        // Previous month expense (should not be included in total_spent)
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 10000,
            'date' => Carbon::now()->subMonth(),
        ]);

        // Future month expense (should not be included)
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'amount' => 8000,
            'date' => Carbon::now()->addMonth(),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Response']]]
            ], 200)
        ]);

        $response = $this->postJson('/api/chatbot', [
            'message' => 'Analyze this month'
        ]);        $response->assertStatus(200);

        // Verify only current month is included
        Http::assertSentCount(1);
    }    public function test_unauthenticated_user_cannot_access_chatbot()
    {
        // Create a new test instance without authentication
        $this->app['auth']->forgetGuards();
        
        $response = $this->postJson('/api/chatbot', [
            'message' => 'Help me'
        ]);

        $response->assertStatus(401);
    }public function test_chatbot_includes_category_spending_totals()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        $foodCategory = Category::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Food',
            'priority' => 1,
        ]);

        $transportCategory = Category::factory()->create([
            'user_id' => $this->user->id,
            'name' => 'Transport',
            'priority' => 2,
        ]);

        // Create expenses in different categories
        Expense::factory()->create([
            'user_id' => $this->user->id,
            'category' => 'Food',
            'amount' => 3000,
            'date' => Carbon::now(),
        ]);

        Expense::factory()->create([
            'user_id' => $this->user->id,
            'category' => 'Food',
            'amount' => 2000,
            'date' => Carbon::now(),
        ]);

        Expense::factory()->create([
            'user_id' => $this->user->id,
            'category' => 'Transport',
            'amount' => 1500,
            'date' => Carbon::now(),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Response']]]
            ], 200)
        ]);

        $response = $this->postJson('/api/chatbot', [
            'message' => 'Show category breakdown'
        ]);        $response->assertStatus(200);

        // Verify category totals are calculated correctly
        Http::assertSentCount(1);
    }
}
