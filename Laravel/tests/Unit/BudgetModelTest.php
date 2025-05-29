<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Budget;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;

class BudgetModelTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    public function test_budget_can_be_created_with_valid_data()
    {
        $user = User::factory()->create();

        $budgetData = [
            'user_id' => $user->id,
            'monthly_budget' => 2500.00,
        ];

        $budget = Budget::create($budgetData);

        $this->assertInstanceOf(Budget::class, $budget);
        $this->assertEquals($budgetData['user_id'], $budget->user_id);
        $this->assertEquals($budgetData['monthly_budget'], $budget->monthly_budget);
        $this->assertDatabaseHas('budgets', $budgetData);
    }

    public function test_budget_fillable_attributes()
    {
        $budget = new Budget();
        $fillable = $budget->getFillable();

        $this->assertContains('user_id', $fillable);
        $this->assertContains('monthly_budget', $fillable);
    }

    public function test_budget_belongs_to_user()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $budget->user);
        $this->assertEquals($user->id, $budget->user->id);
    }

    public function test_budget_monthly_budget_is_numeric()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create([
            'user_id' => $user->id,
            'monthly_budget' => 1500.50
        ]);

        $this->assertIsNumeric($budget->monthly_budget);
        $this->assertEquals(1500.50, $budget->monthly_budget);
    }

    public function test_budget_can_be_zero()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create([
            'user_id' => $user->id,
            'monthly_budget' => 0
        ]);

        $this->assertEquals(0, $budget->monthly_budget);
    }

    public function test_budget_has_timestamps()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $user->id]);

        $this->assertNotNull($budget->created_at);
        $this->assertNotNull($budget->updated_at);
        $this->assertInstanceOf(\Carbon\Carbon::class, $budget->created_at);
        $this->assertInstanceOf(\Carbon\Carbon::class, $budget->updated_at);
    }
}
