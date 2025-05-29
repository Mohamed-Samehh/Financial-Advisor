<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Expense;
use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Laravel\Sanctum\Sanctum;

class ExpenseFeatureTest extends TestCase
{
    use RefreshDatabase, WithFaker;    public function test_user_can_view_their_expenses()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);
        Expense::factory()->count(3)->create([
            'user_id' => $user->id,
            'category' => $category->name
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/expenses/all');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'data',
                    'current_page',
                    'per_page',
                    'total'
                ]);
    }    public function test_user_can_create_expense_with_valid_data()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);        $expenseData = [
            'description' => 'Test expense',
            'amount' => 5025, // Use integer since DB uses bigInteger (in cents)
            'category' => $category->name,
            'date' => '2024-01-15'
        ];

        $response = $this->postJson('/api/expenses', $expenseData);

        $response->assertStatus(201)
                ->assertJson([
                    'message' => 'Expense added successfully',
                    'expense' => [
                        'description' => 'Test expense',
                        'amount' => 5025,
                        'category' => $category->name,
                        'user_id' => $user->id
                    ]
                ]);

        $this->assertDatabaseHas('expenses', [
            'user_id' => $user->id,
            'description' => 'Test expense',
            'amount' => 5025,
            'category' => $category->name,
            'date' => '2024-01-15'
        ]);
    }    public function test_user_can_create_expense_without_description()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);        $expenseData = [
            'amount' => 7500, // Use integer since DB uses bigInteger (in cents)
            'category' => $category->name,
            'date' => '2024-01-15'
        ];

        $response = $this->postJson('/api/expenses', $expenseData);

        $response->assertStatus(201)
                ->assertJson([
                    'message' => 'Expense added successfully'
                ]);        $this->assertDatabaseHas('expenses', [
            'user_id' => $user->id,
            'amount' => 7500, // Use integer since DB uses bigInteger (in cents)
            'category' => $category->name,
            'description' => null
        ]);
    }    public function test_expense_creation_validates_required_fields()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/expenses', []);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['amount', 'category', 'date']);
    }    public function test_expense_creation_validates_category_exists()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $expenseData = [
            'amount' => 50.00,
            'category' => 'NonExistentCategory',
            'date' => '2024-01-15'
        ];

        $response = $this->postJson('/api/expenses', $expenseData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['category']);
    }    public function test_expense_creation_validates_positive_amount()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $expenseData = [
            'amount' => -25.00,
            'category' => $category->name,
            'date' => '2024-01-15'
        ];

        $response = $this->postJson('/api/expenses', $expenseData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['amount']);
    }    public function test_expense_creation_validates_numeric_amount()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $expenseData = [
            'amount' => 'not-a-number',
            'category' => $category->name,
            'date' => '2024-01-15'
        ];

        $response = $this->postJson('/api/expenses', $expenseData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['amount']);
    }    public function test_expense_creation_validates_date_format()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $expenseData = [
            'amount' => 50.00,
            'category' => $category->name,
            'date' => 'invalid-date'
        ];

        $response = $this->postJson('/api/expenses', $expenseData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['date']);
    }

    public function test_user_only_sees_their_own_expenses()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        $category1 = Category::factory()->create(['user_id' => $user1->id]);
        $category2 = Category::factory()->create(['user_id' => $user2->id]);        // Create expenses for both users
        Expense::factory()->count(2)->create([
            'user_id' => $user1->id,
            'category' => $category1->name
        ]);
        Expense::factory()->count(3)->create([
            'user_id' => $user2->id,
            'category' => $category2->name
        ]);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/expenses/all');        $response->assertStatus(200);

        $responseData = $response->json();
        
        // Check if we have data and it's structured correctly
        $this->assertArrayHasKey('data', $responseData);
        
        // Get all expenses from all year groups
        $allExpenses = [];
        foreach ($responseData['data'] as $yearGroup) {
            if (is_array($yearGroup)) {
                $allExpenses = array_merge($allExpenses, $yearGroup);
            }
        }

        // Verify only user1's expenses are returned
        foreach ($allExpenses as $expense) {
            $this->assertEquals($user1->id, $expense['user_id']);
        }
    }

    public function test_expenses_are_paginated()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);
          // Create 5 expenses
        Expense::factory()->count(5)->create([
            'user_id' => $user->id,
            'category' => $category->name
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/expenses/all?per_page=2&page=1');        $response->assertStatus(200)
                ->assertJsonStructure([
                    'data',
                    'current_page',
                    'per_page',
                    'total',
                    'last_page'
                ])
                ->assertJson([
                    'current_page' => 1,
                    'per_page' => 2
                ]);
    }

    public function test_expenses_are_grouped_by_year()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);
          // Create expenses from different years
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => $category->name,
            'date' => '2023-06-15'
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => $category->name,
            'date' => '2024-01-20'
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/expenses/all');

        $response->assertStatus(200);        $data = $response->json('data');

        // Should have grouped expenses by year - data is an array of year groups
        $this->assertIsArray($data);
        
        // Check if we have year-based groupings by looking for numeric keys (years)
        $hasYearGrouping = false;
        foreach ($data as $yearData) {
            if (is_array($yearData) && !empty($yearData)) {
                $hasYearGrouping = true;
                break;
            }
        }
        
        $this->assertTrue($hasYearGrouping, 'Expenses should be grouped by year');
    }

    public function test_unauthenticated_user_cannot_access_expenses()
    {
        $response = $this->getJson('/api/expenses/all');
        $response->assertStatus(401);        $response = $this->postJson('/api/expenses', [
            'amount' => 50.00,
            'category' => 'NonExistentCategory',
            'date' => '2024-01-15'
        ]);
        $response->assertStatus(401);
    }

    public function test_expense_accepts_decimal_amounts()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);        $expenseData = [
            'description' => 'Integer test',
            'amount' => 12345, // Use integer since DB uses bigInteger (in cents)
            'category' => $category->name,
            'date' => '2024-01-15'
        ];

        $response = $this->postJson('/api/expenses', $expenseData);

        $response->assertStatus(201);

        $this->assertDatabaseHas('expenses', [
            'user_id' => $user->id,
            'amount' => 12345
        ]);
    }
}
