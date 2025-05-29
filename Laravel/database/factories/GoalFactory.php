<?php

namespace Database\Factories;

use App\Models\Goal;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class GoalFactory extends Factory
{
    protected $model = Goal::class;    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => $this->faker->randomElement([
                'Emergency Fund',
                'Vacation Fund',
                'New Car',
                'House Down Payment',
                'Retirement Savings',
                'Home Renovation'
            ]),
            'target_amount' => $this->faker->numberBetween(1000, 50000), // Use integer since DB uses bigInteger
        ];
    }
}
