<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Goal;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;

class GoalModelTest extends TestCase
{
    use RefreshDatabase, WithFaker;
    
    public function test_goal_can_be_created_with_valid_data()
    {
        $user = User::factory()->create();

        $goalData = [
            'user_id' => $user->id,
            'name' => 'Emergency Fund',
            'target_amount' => 5000, // Use integer since DB uses bigInteger
        ];

        $goal = Goal::create($goalData);

        $this->assertInstanceOf(Goal::class, $goal);
        $this->assertEquals($goalData['user_id'], $goal->user_id);
        $this->assertEquals($goalData['name'], $goal->name);
        $this->assertEquals($goalData['target_amount'], $goal->target_amount);
        $this->assertDatabaseHas('goals', $goalData);
    }
    
    public function test_goal_fillable_attributes()
    {
        $goal = new Goal();
        $fillable = $goal->getFillable();

        $expectedFillable = ['user_id', 'name', 'target_amount']; // Removed deadline since column doesn't exist
        
        foreach ($expectedFillable as $attribute) {
            $this->assertContains($attribute, $fillable);
        }
    }

    public function test_goal_belongs_to_user()
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $goal->user);
        $this->assertEquals($user->id, $goal->user->id);
    }
    
    public function test_goal_target_amount_is_numeric()
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'target_amount' => 2500 // Use integer since DB uses bigInteger
        ]);

        $this->assertIsNumeric($goal->target_amount);
        $this->assertEquals(2500, $goal->target_amount);
    }
    
    public function test_goal_name_is_string()
    {
        $user = User::factory()->create();
        $goalName = 'Vacation Fund';
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'name' => $goalName
        ]);

        $this->assertIsString($goal->name);
        $this->assertEquals($goalName, $goal->name);
    }

    public function test_goal_has_timestamps()
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $this->assertNotNull($goal->created_at);
        $this->assertNotNull($goal->updated_at);
        $this->assertInstanceOf(\Carbon\Carbon::class, $goal->created_at);
        $this->assertInstanceOf(\Carbon\Carbon::class, $goal->updated_at);
    }
}
