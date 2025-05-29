<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Budget;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Laravel\Sanctum\Sanctum;
use Carbon\Carbon;

class BudgetFeatureTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    public function test_user_can_view_their_budgets()
    {
        $user = User::factory()->create();
        $budgets = Budget::factory()->count(3)->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/budget/all');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'budgets' => [
                        '*' => [
                            'id',
                            'user_id',
                            'monthly_budget',
                            'created_at',
                            'updated_at'
                        ]
                    ]
                ])
                ->assertJsonCount(3, 'budgets');
    }

    public function test_user_can_create_budget_for_current_month()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $budgetData = [
            'monthly_budget' => 2500.00
        ];

        $response = $this->postJson('/api/budget', $budgetData);

        $response->assertStatus(200)
                ->assertJson([
                    'message' => 'Budget added successfully'
                ])
                ->assertJsonStructure([
                    'message',
                    'budget' => [
                        'id',
                        'user_id',
                        'monthly_budget',
                        'created_at',
                        'updated_at'
                    ]
                ]);

        $this->assertDatabaseHas('budgets', [
            'user_id' => $user->id,
            'monthly_budget' => 2500.00
        ]);
    }

    public function test_user_cannot_create_duplicate_budget_for_current_month()
    {
        $user = User::factory()->create();
        Budget::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now()
        ]);

        Sanctum::actingAs($user);

        $budgetData = [
            'monthly_budget' => 2500.00
        ];

        $response = $this->postJson('/api/budget', $budgetData);

        $response->assertStatus(400)
                ->assertJson([
                    'message' => 'You have already added a budget for this month'
                ]);
    }

    public function test_user_can_view_current_month_budget()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now()
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/budget');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'budget' => [
                        'id',
                        'user_id',
                        'monthly_budget',
                        'created_at',
                        'updated_at'
                    ]
                ])
                ->assertJson([
                    'budget' => [
                        'id' => $budget->id,
                        'user_id' => $user->id
                    ]
                ]);
    }

    public function test_user_gets_404_when_no_current_month_budget()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/budget');

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'No budget found for this month'
                ]);
    }

    public function test_user_can_update_their_budget()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $updateData = [
            'monthly_budget' => 3000.00
        ];

        $response = $this->putJson("/api/budget/{$budget->id}", $updateData);

        $response->assertStatus(200)
                ->assertJson([
                    'message' => 'Budget updated successfully'
                ])
                ->assertJsonFragment([
                    'monthly_budget' => 3000.00
                ]);

        $this->assertDatabaseHas('budgets', [
            'id' => $budget->id,
            'monthly_budget' => 3000.00
        ]);
    }

    public function test_user_cannot_update_other_users_budget()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $otherUser->id]);

        Sanctum::actingAs($user);

        $updateData = [
            'monthly_budget' => 3000.00
        ];

        $response = $this->putJson("/api/budget/{$budget->id}", $updateData);

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'Budget not found or you do not have permission to update it'
                ]);
    }

    public function test_user_can_delete_their_budget()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $response = $this->deleteJson("/api/budget/{$budget->id}");

        $response->assertStatus(200);

        $this->assertDatabaseMissing('budgets', [
            'id' => $budget->id
        ]);
    }

    public function test_user_cannot_delete_other_users_budget()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $otherUser->id]);

        Sanctum::actingAs($user);

        $response = $this->deleteJson("/api/budget/{$budget->id}");

        $response->assertStatus(404);

        $this->assertDatabaseHas('budgets', [
            'id' => $budget->id
        ]);
    }

    public function test_budget_creation_validates_required_fields()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/budget', []);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['monthly_budget']);
    }

    public function test_budget_creation_validates_positive_amount()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/budget', [
            'monthly_budget' => -100
        ]);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['monthly_budget']);
    }

    public function test_unauthenticated_user_cannot_access_budgets()
    {
        $response = $this->getJson('/api/budget/all');
        $response->assertStatus(401);

        $response = $this->postJson('/api/budget', ['monthly_budget' => 2500]);
        $response->assertStatus(401);
    }
}
