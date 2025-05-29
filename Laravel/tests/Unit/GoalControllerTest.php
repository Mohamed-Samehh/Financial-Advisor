<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Http\Controllers\GoalController;
use App\Models\Goal;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Http\Request;
use Carbon\Carbon;

class GoalControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $goalController;

    protected function setUp(): void
    {
        parent::setUp();
        $this->goalController = new GoalController();
    }

    public function test_index_returns_user_goals_ordered_by_created_at()
    {
        $user = User::factory()->create();
        
        // Create goals with different creation dates
        $goal1 = Goal::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()->subDays(2)]);
        $goal2 = Goal::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()->subDay()]);
        $goal3 = Goal::factory()->create(['user_id' => $user->id, 'created_at' => Carbon::now()]);

        // Create goal for another user (should not be returned)
        $otherUser = User::factory()->create();
        Goal::factory()->create(['user_id' => $otherUser->id]);

        $request = Request::create('/api/goal/all', 'GET');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->index($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertCount(3, $responseData['goals']);
        
        // Verify goals are ordered by created_at desc (newest first)
        $this->assertEquals($goal3->id, $responseData['goals'][0]['id']);
        $this->assertEquals($goal2->id, $responseData['goals'][1]['id']);
        $this->assertEquals($goal1->id, $responseData['goals'][2]['id']);
    }

    public function test_store_creates_goal_for_current_month()
    {
        $user = User::factory()->create();
        $goalData = [
            'name' => 'Save for vacation',
            'target_amount' => 50000,
        ];

        $request = Request::create('/api/goal', 'POST', $goalData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->store($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(201, $response->getStatusCode());
        $this->assertEquals('Goal created successfully', $responseData['message']);
        $this->assertEquals('Save for vacation', $responseData['goal']['name']);
        $this->assertEquals(50000, $responseData['goal']['target_amount']);
        $this->assertEquals($user->id, $responseData['goal']['user_id']);

        // Verify goal was saved to database
        $this->assertDatabaseHas('goals', [
            'user_id' => $user->id,
            'name' => 'Save for vacation',
            'target_amount' => 50000,
        ]);
    }

    public function test_store_prevents_multiple_goals_for_same_month()
    {
        $user = User::factory()->create();
        
        // Create existing goal for current month
        Goal::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now(),
        ]);

        $goalData = [
            'name' => 'Another goal',
            'target_amount' => 30000,
        ];

        $request = Request::create('/api/goal', 'POST', $goalData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->store($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(403, $response->getStatusCode());
        $this->assertEquals('A goal for this month already exists. You can only add one goal per month.', $responseData['message']);
    }

    public function test_store_validates_required_fields()
    {
        $user = User::factory()->create();

        $request = Request::create('/api/goal', 'POST', []);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $this->goalController->store($request);
    }

    public function test_store_validates_target_amount_minimum()
    {
        $user = User::factory()->create();
        $goalData = [
            'name' => 'Invalid goal',
            'target_amount' => 0,
        ];

        $request = Request::create('/api/goal', 'POST', $goalData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $this->goalController->store($request);
    }

    public function test_show_returns_current_month_goal()
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now(),
        ]);

        // Create goal from previous month (should not be returned)
        Goal::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now()->subMonth(),
        ]);

        $request = Request::create('/api/goal', 'GET');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->show($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals($goal->id, $responseData['goal']['id']);
        $this->assertEquals($goal->name, $responseData['goal']['name']);
    }

    public function test_show_returns_404_when_no_current_month_goal()
    {
        $user = User::factory()->create();

        // Create goal from previous month
        Goal::factory()->create([
            'user_id' => $user->id,
            'created_at' => Carbon::now()->subMonth(),
        ]);

        $request = Request::create('/api/goal', 'GET');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->show($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(404, $response->getStatusCode());
        $this->assertEquals('No goal found for this month', $responseData['message']);
    }

    public function test_update_modifies_existing_goal()
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $updateData = [
            'name' => 'Updated goal name',
            'target_amount' => 75000,
        ];

        $request = Request::create("/api/goal/{$goal->id}", 'PUT', $updateData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->update($request, $goal->id);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('Goal updated successfully', $responseData['message']);
        $this->assertEquals('Updated goal name', $responseData['goal']['name']);
        $this->assertEquals(75000, $responseData['goal']['target_amount']);

        // Verify database was updated
        $this->assertDatabaseHas('goals', [
            'id' => $goal->id,
            'name' => 'Updated goal name',
            'target_amount' => 75000,
        ]);
    }

    public function test_update_returns_404_for_non_existent_goal()
    {
        $user = User::factory()->create();
        $updateData = [
            'name' => 'Updated goal',
            'target_amount' => 50000,
        ];

        $request = Request::create('/api/goal/999', 'PUT', $updateData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->update($request, 999);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(404, $response->getStatusCode());
        $this->assertEquals('Goal not found', $responseData['message']);
    }

    public function test_update_prevents_access_to_other_users_goals()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherUserGoal = Goal::factory()->create(['user_id' => $otherUser->id]);

        $updateData = [
            'name' => 'Hacked goal',
            'target_amount' => 99999,
        ];

        $request = Request::create("/api/goal/{$otherUserGoal->id}", 'PUT', $updateData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->update($request, $otherUserGoal->id);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(404, $response->getStatusCode());
        $this->assertEquals('Goal not found', $responseData['message']);
    }

    public function test_destroy_deletes_goal()
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $request = Request::create("/api/goal/{$goal->id}", 'DELETE');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->destroy($request, $goal->id);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('Goal deleted successfully', $responseData['message']);

        // Verify goal was deleted from database
        $this->assertDatabaseMissing('goals', ['id' => $goal->id]);
    }

    public function test_destroy_returns_404_for_non_existent_goal()
    {
        $user = User::factory()->create();

        $request = Request::create('/api/goal/999', 'DELETE');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->destroy($request, 999);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(404, $response->getStatusCode());
        $this->assertEquals('Goal not found', $responseData['message']);
    }

    public function test_destroy_prevents_access_to_other_users_goals()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherUserGoal = Goal::factory()->create(['user_id' => $otherUser->id]);

        $request = Request::create("/api/goal/{$otherUserGoal->id}", 'DELETE');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->goalController->destroy($request, $otherUserGoal->id);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(404, $response->getStatusCode());
        $this->assertEquals('Goal not found', $responseData['message']);

        // Verify goal was not deleted
        $this->assertDatabaseHas('goals', ['id' => $otherUserGoal->id]);
    }
}
