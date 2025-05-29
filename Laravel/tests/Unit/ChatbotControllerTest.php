<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Http\Controllers\ChatbotController;
use App\Models\User;
use App\Models\Budget;
use App\Models\Goal;
use App\Models\Expense;
use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;

class ChatbotControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $chatbotController;    protected function setUp(): void
    {
        parent::setUp();
        $this->chatbotController = new ChatbotController();
        // Don't call Http::fake() here - let individual tests set it up
    }    public function test_chat_processes_user_message_and_returns_response()
    {
        // Set required environment variables
        config(['app.env' => 'testing']);
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        $user = User::factory()->create(['name' => 'John Doe']);
        
        // Create test data
        $budget = Budget::factory()->create([
            'user_id' => $user->id,
            'monthly_budget' => 200000,
            'created_at' => Carbon::now(),
        ]);
        
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'name' => 'Emergency Fund',
            'target_amount' => 500000,
            'created_at' => Carbon::now(),
        ]);

        $category = Category::factory()->create([
            'user_id' => $user->id,
            'name' => 'Groceries',
            'priority' => 1,
        ]);

        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Groceries',
            'amount' => 5000,
            'date' => Carbon::now(),
        ]);

        // Mock Flask API response
        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => 'Based on your spending, you are doing well with your budget!'
                        ]
                    ]
                ]
            ], 200)
        ]);

        $requestData = ['message' => 'How am I doing with my budget?'];
        $request = Request::create('/api/chatbot', 'POST', $requestData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->chatbotController->chat($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('Based on your spending, you are doing well with your budget!', $responseData['message']);

        // Verify Flask API was called
        Http::assertSent(function ($request) {
            return $request->url() === 'http://127.0.0.1:5000/chat';
        });
    }

    public function test_chat_handles_missing_budget_gracefully()
    {
        $user = User::factory()->create(['name' => 'Jane Doe']);

        // No budget created - should default to 0
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now(),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => 'You should set a budget first!'
                        ]
                    ]
                ]
            ], 200)
        ]);

        $requestData = ['message' => 'What should I do?'];
        $request = Request::create('/api/chatbot', 'POST', $requestData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->chatbotController->chat($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('You should set a budget first!', $responseData['message']);

        // Verify budget defaults to 0
        Http::assertSent(function ($request) {
            $data = $request->data();
            return $data['budget'] === 0;
        });
    }

    public function test_chat_handles_missing_goal_gracefully()
    {
        $user = User::factory()->create(['name' => 'Bob Smith']);

        // No goal created - should default to "Unnamed Goal" and 0 amount
        Budget::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now(),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => 'Consider setting a financial goal!'
                        ]
                    ]
                ]
            ], 200)
        ]);

        $requestData = ['message' => 'Give me advice'];
        $request = Request::create('/api/chatbot', 'POST', $requestData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->chatbotController->chat($request);

        // Verify goal defaults
        Http::assertSent(function ($request) {
            $data = $request->data();
            return $data['goal_name'] === 'Unnamed Goal' && $data['goal_amount'] === 0;
        });
    }

    public function test_chat_calculates_daily_expenses_correctly()
    {
        $user = User::factory()->create(['name' => 'Alice Johnson']);
        
        Budget::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);
        Goal::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);

        // Create expenses for different days in current month
        $today = Carbon::now();
        $yesterday = Carbon::now()->subDay();
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 3000,
            'date' => $today->format('Y-m-d'),
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 2000,
            'date' => $today->format('Y-m-d'),
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 1500,
            'date' => $yesterday->format('Y-m-d'),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Response']]]
            ], 200)
        ]);

        $request = Request::create('/api/chatbot', 'POST', ['message' => 'test']);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->chatbotController->chat($request);

        // Verify daily expenses aggregation
        Http::assertSent(function ($request) use ($today, $yesterday) {
            $data = $request->data();
            $dailyExpenses = $data['daily_expenses'];
            
            return isset($dailyExpenses[$today->format('Y-m-d')]) &&
                   $dailyExpenses[$today->format('Y-m-d')] == 5000 && // 3000 + 2000
                   isset($dailyExpenses[$yesterday->format('Y-m-d')]) &&
                   $dailyExpenses[$yesterday->format('Y-m-d')] == 1500;
        });
    }

    public function test_chat_calculates_category_totals_correctly()
    {
        $user = User::factory()->create();
        
        Budget::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);
        Goal::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);

        $groceriesCategory = Category::factory()->create([
            'user_id' => $user->id,
            'name' => 'Groceries',
            'priority' => 1,
        ]);

        $transportCategory = Category::factory()->create([
            'user_id' => $user->id,
            'name' => 'Transport',
            'priority' => 2,
        ]);

        // Create expenses in different categories
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Groceries',
            'amount' => 2500,
            'date' => Carbon::now(),
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Groceries',
            'amount' => 1500,
            'date' => Carbon::now(),
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Transport',
            'amount' => 1000,
            'date' => Carbon::now(),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Response']]]
            ], 200)
        ]);

        $request = Request::create('/api/chatbot', 'POST', ['message' => 'test']);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->chatbotController->chat($request);

        // Verify category totals
        Http::assertSent(function ($request) {
            $data = $request->data();
            $categories = $data['categories'];
            
            $groceriesTotal = collect($categories)->firstWhere('name', 'Groceries')['total_spent'] ?? 0;
            $transportTotal = collect($categories)->firstWhere('name', 'Transport')['total_spent'] ?? 0;
            
            return $groceriesTotal == 4000 && $transportTotal == 1000; // 2500 + 1500 = 4000
        });
    }

    public function test_chat_handles_flask_api_failure()
    {
        $user = User::factory()->create();
        
        Budget::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);

        // Mock Flask API failure
        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([], 500)
        ]);

        $request = Request::create('/api/chatbot', 'POST', ['message' => 'test']);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->chatbotController->chat($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(500, $response->getStatusCode());
        $this->assertEquals('Failed to fetch response', $responseData['error']);
    }

    public function test_chat_handles_malformed_flask_response()
    {
        $user = User::factory()->create();
        
        Budget::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);

        // Mock Flask API with malformed response
        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'invalid' => 'response_structure'
            ], 200)
        ]);

        $request = Request::create('/api/chatbot', 'POST', ['message' => 'test']);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->chatbotController->chat($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals("I'm sorry, but I couldn't generate a response. Please try again or ask in a different way.", $responseData['message']);
    }

    public function test_chat_includes_month_end_date()
    {
        $user = User::factory()->create();
        
        Budget::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);
        Goal::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Response']]]
            ], 200)
        ]);

        $request = Request::create('/api/chatbot', 'POST', ['message' => 'test']);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->chatbotController->chat($request);

        $expectedLastDay = Carbon::now()->endOfMonth()->format('F j, Y');

        Http::assertSent(function ($request) use ($expectedLastDay) {
            $data = $request->data();
            return $data['last_day_month'] === $expectedLastDay;
        });
    }    public function test_chat_filters_expenses_by_current_month()
    {
        // Set required environment variables
        putenv('OPENROUTER_API_KEY=test-api-key');
        putenv('flaskPassword=test-password');
        
        $user = User::factory()->create();
        
        Budget::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);
        Goal::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);
        
        // Create a category for the expenses
        Category::factory()->create([
            'user_id' => $user->id,
            'name' => 'Test Category',
            'priority' => 1,
        ]);

        // Create expenses in current month and previous month
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Test Category',
            'amount' => 2000,
            'date' => Carbon::now()->format('Y-m-d'),
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Test Category',
            'amount' => 3000,
            'date' => Carbon::now()->subMonth()->format('Y-m-d'),
        ]);

        Http::fake([
            'http://127.0.0.1:5000/chat' => Http::response([
                'choices' => [['message' => ['content' => 'Flask response']]]
            ], 200)
        ]);

        $request = Request::create('/api/chatbot', 'POST', ['message' => 'test']);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->chatbotController->chat($request);

        // Verify only current month expenses are included in total_spent
        Http::assertSent(function ($request) {
            $data = $request->data();
            return isset($data['total_spent']) && $data['total_spent'] == 2000; // Only current month expense
        });
    }
}
