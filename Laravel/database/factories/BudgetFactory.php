<?php

namespace Database\Factories;

use App\Models\Budget;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class BudgetFactory extends Factory
{
    protected $model = Budget::class;    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'monthly_budget' => $this->faker->numberBetween(50000, 500000), // Use integer since DB uses bigInteger (in cents)
        ];
    }
}
