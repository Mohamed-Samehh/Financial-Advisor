<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Http\Controllers\BudgetController;
use App\Models\Budget;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Http\Request;
use Carbon\Carbon;

class BudgetControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $budgetController;

    protected function setUp(): void
    {
        parent::setUp();
        $this->budgetController = new BudgetController();
    }

    public function test_index_returns_all_user_budgets()
    {
        $user = User::factory()->create();
        $budgets = Budget::factory()->count(3)->create(['user_id' => $user->id]);

        $request = Request::create('/budgets', 'GET');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->budgetController->index($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertArrayHasKey('budgets', $responseData);
        $this->assertCount(3, $responseData['budgets']);
    }

    public function test_store_creates_budget_successfully()
    {
        $user = User::factory()->create();
        
        $request = Request::create('/budgets', 'POST', [
            'monthly_budget' => 2500.00
        ]);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        // Mock the validator
        $this->mock(\Illuminate\Validation\Factory::class, function ($mock) {
            $mock->shouldReceive('make')
                ->andReturn(new class {
                    public function validate() {
                        return ['monthly_budget' => 2500.00];
                    }
                });
        });

        $response = $this->budgetController->store($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('Budget added successfully', $responseData['message']);
        $this->assertDatabaseHas('budgets', [
            'user_id' => $user->id,
            'monthly_budget' => 2500.00
        ]);
    }

    public function test_store_fails_when_budget_exists_for_current_month()
    {
        $user = User::factory()->create();
        
        // Create existing budget for current month
        Budget::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now()
        ]);

        $request = Request::create('/budgets', 'POST', [
            'monthly_budget' => 2500.00
        ]);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->budgetController->store($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(400, $response->getStatusCode());
        $this->assertEquals('You have already added a budget for this month', $responseData['message']);
    }

    public function test_show_returns_current_month_budget()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now()
        ]);

        $request = Request::create('/budgets/current', 'GET');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->budgetController->show($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertArrayHasKey('budget', $responseData);
        $this->assertEquals($budget->id, $responseData['budget']['id']);
    }

    public function test_show_returns_404_when_no_budget_for_current_month()
    {
        $user = User::factory()->create();

        $request = Request::create('/budgets/current', 'GET');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->budgetController->show($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(404, $response->getStatusCode());
        $this->assertEquals('No budget found for this month', $responseData['message']);
    }

    public function test_update_modifies_budget_successfully()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $user->id]);

        $request = Request::create('/budgets/' . $budget->id, 'PUT', [
            'monthly_budget' => 3000.00
        ]);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->budgetController->update($request, $budget->id);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('Budget updated successfully', $responseData['message']);
        $this->assertDatabaseHas('budgets', [
            'id' => $budget->id,
            'monthly_budget' => 3000.00
        ]);
    }

    public function test_update_returns_404_for_unauthorized_budget()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $otherUser->id]);

        $request = Request::create('/budgets/' . $budget->id, 'PUT', [
            'monthly_budget' => 3000.00
        ]);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->budgetController->update($request, $budget->id);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(404, $response->getStatusCode());
        $this->assertEquals('Budget not found or you do not have permission to update it', $responseData['message']);
    }

    public function test_destroy_deletes_budget_successfully()
    {
        $user = User::factory()->create();
        $budget = Budget::factory()->create(['user_id' => $user->id]);

        $request = Request::create('/budgets/' . $budget->id, 'DELETE');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->budgetController->destroy($request, $budget->id);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertDatabaseMissing('budgets', ['id' => $budget->id]);
    }
}
