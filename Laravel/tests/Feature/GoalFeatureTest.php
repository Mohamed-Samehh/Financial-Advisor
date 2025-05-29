<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Goal;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Laravel\Sanctum\Sanctum;
use Carbon\Carbon;

class GoalFeatureTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    }

    public function test_user_can_get_all_goals()
    {
        Goal::factory()->count(3)->create(['user_id' => $this->user->id]);

        $response = $this->getJson('/api/goal/all');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'goals' => [
                        '*' => [
                            'id',
                            'user_id',
                            'name',
                            'target_amount',
                            'created_at',
                            'updated_at'
                        ]
                    ]
                ]);

        $this->assertCount(3, $response->json('goals'));
    }

    public function test_user_can_create_goal_for_current_month()
    {
        $goalData = [
            'name' => 'Emergency Fund',
            'target_amount' => 100000,
        ];

        $response = $this->postJson('/api/goal', $goalData);

        $response->assertStatus(201)
                ->assertJson([
                    'message' => 'Goal created successfully',
                    'goal' => [
                        'name' => 'Emergency Fund',
                        'target_amount' => 100000,
                        'user_id' => $this->user->id,
                    ]
                ]);

        $this->assertDatabaseHas('goals', [
            'user_id' => $this->user->id,
            'name' => 'Emergency Fund',
            'target_amount' => 100000,
        ]);
    }

    public function test_user_cannot_create_multiple_goals_for_same_month()
    {
        // Create existing goal for current month
        Goal::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => Carbon::now(),
        ]);

        $goalData = [
            'name' => 'Second Goal',
            'target_amount' => 50000,
        ];

        $response = $this->postJson('/api/goal', $goalData);

        $response->assertStatus(403)
                ->assertJson([
                    'message' => 'A goal for this month already exists. You can only add one goal per month.'
                ]);
    }

    public function test_goal_creation_validates_required_fields()
    {
        $response = $this->postJson('/api/goal', []);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['name', 'target_amount']);
    }

    public function test_goal_creation_validates_target_amount_minimum()
    {
        $goalData = [
            'name' => 'Invalid Goal',
            'target_amount' => 0,
        ];

        $response = $this->postJson('/api/goal', $goalData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['target_amount']);
    }

    public function test_goal_creation_validates_target_amount_numeric()
    {
        $goalData = [
            'name' => 'Invalid Goal',
            'target_amount' => 'not_a_number',
        ];

        $response = $this->postJson('/api/goal', $goalData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['target_amount']);
    }

    public function test_user_can_get_current_month_goal()
    {
        $goal = Goal::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => Carbon::now(),
        ]);

        $response = $this->getJson('/api/goal');

        $response->assertStatus(200)
                ->assertJson([
                    'goal' => [
                        'id' => $goal->id,
                        'name' => $goal->name,
                        'target_amount' => $goal->target_amount,
                    ]
                ]);
    }

    public function test_user_gets_404_when_no_current_month_goal()
    {
        // Create goal from previous month
        Goal::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => Carbon::now()->subMonth(),
        ]);

        $response = $this->getJson('/api/goal');

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'No goal found for this month'
                ]);
    }

    public function test_user_can_update_goal()
    {
        $goal = Goal::factory()->create(['user_id' => $this->user->id]);

        $updateData = [
            'name' => 'Updated Goal Name',
            'target_amount' => 150000,
        ];

        $response = $this->putJson("/api/goal/{$goal->id}", $updateData);

        $response->assertStatus(200)
                ->assertJson([
                    'message' => 'Goal updated successfully',
                    'goal' => [
                        'id' => $goal->id,
                        'name' => 'Updated Goal Name',
                        'target_amount' => 150000,
                    ]
                ]);

        $this->assertDatabaseHas('goals', [
            'id' => $goal->id,
            'name' => 'Updated Goal Name',
            'target_amount' => 150000,
        ]);
    }

    public function test_user_cannot_update_non_existent_goal()
    {
        $updateData = [
            'name' => 'Non-existent Goal',
            'target_amount' => 50000,
        ];

        $response = $this->putJson('/api/goal/999', $updateData);

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'Goal not found'
                ]);
    }

    public function test_user_cannot_update_other_users_goal()
    {
        $otherUser = User::factory()->create();
        $otherUserGoal = Goal::factory()->create(['user_id' => $otherUser->id]);

        $updateData = [
            'name' => 'Hacked Goal',
            'target_amount' => 99999,
        ];

        $response = $this->putJson("/api/goal/{$otherUserGoal->id}", $updateData);

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'Goal not found'
                ]);

        // Verify original goal wasn't modified
        $this->assertDatabaseHas('goals', [
            'id' => $otherUserGoal->id,
            'name' => $otherUserGoal->name,
            'target_amount' => $otherUserGoal->target_amount,
        ]);
    }

    public function test_goal_update_validates_required_fields()
    {
        $goal = Goal::factory()->create(['user_id' => $this->user->id]);

        $response = $this->putJson("/api/goal/{$goal->id}", []);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['name', 'target_amount']);
    }

    public function test_user_can_delete_goal()
    {
        $goal = Goal::factory()->create(['user_id' => $this->user->id]);

        $response = $this->deleteJson("/api/goal/{$goal->id}");

        $response->assertStatus(200)
                ->assertJson([
                    'message' => 'Goal deleted successfully'
                ]);

        $this->assertDatabaseMissing('goals', ['id' => $goal->id]);
    }

    public function test_user_cannot_delete_non_existent_goal()
    {
        $response = $this->deleteJson('/api/goal/999');

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'Goal not found'
                ]);
    }

    public function test_user_cannot_delete_other_users_goal()
    {
        $otherUser = User::factory()->create();
        $otherUserGoal = Goal::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->deleteJson("/api/goal/{$otherUserGoal->id}");

        $response->assertStatus(404)
                ->assertJson([
                    'message' => 'Goal not found'
                ]);

        // Verify goal wasn't deleted
        $this->assertDatabaseHas('goals', ['id' => $otherUserGoal->id]);
    }    public function test_unauthenticated_user_cannot_access_goal_endpoints()
    {
        // Remove authentication
        $this->app['auth']->forgetGuards();

        $this->getJson('/api/goal/all')->assertStatus(401);
        $this->getJson('/api/goal')->assertStatus(401);
        $this->postJson('/api/goal', [])->assertStatus(401);
        $this->putJson('/api/goal/1', [])->assertStatus(401);
        $this->deleteJson('/api/goal/1')->assertStatus(401);
    }

    public function test_goals_are_scoped_to_authenticated_user()
    {
        // Create goals for different users
        $otherUser = User::factory()->create();
        Goal::factory()->count(2)->create(['user_id' => $otherUser->id]);
        Goal::factory()->count(3)->create(['user_id' => $this->user->id]);

        $response = $this->getJson('/api/goal/all');

        $response->assertStatus(200);
        $goals = $response->json('goals');
        
        $this->assertCount(3, $goals);
        
        // Verify all returned goals belong to the authenticated user
        foreach ($goals as $goal) {
            $this->assertEquals($this->user->id, $goal['user_id']);
        }
    }

    public function test_goals_are_ordered_by_created_at_desc()
    {
        $goal1 = Goal::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => Carbon::now()->subDays(3)
        ]);
        $goal2 = Goal::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => Carbon::now()->subDay()
        ]);
        $goal3 = Goal::factory()->create([
            'user_id' => $this->user->id,
            'created_at' => Carbon::now()
        ]);

        $response = $this->getJson('/api/goal/all');

        $response->assertStatus(200);
        $goals = $response->json('goals');

        // Verify order (newest first)
        $this->assertEquals($goal3->id, $goals[0]['id']);
        $this->assertEquals($goal2->id, $goals[1]['id']);
        $this->assertEquals($goal1->id, $goals[2]['id']);
    }
}
