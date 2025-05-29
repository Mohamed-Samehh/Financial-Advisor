<?php

namespace Database\Factories;

use App\Models\Expense;
use App\Models\User;
use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;

class ExpenseFactory extends Factory
{
    protected $model = Expense::class;    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'category' => $this->faker->randomElement(['Food & Dining', 'Transportation', 'Shopping', 'Entertainment', 'Bills & Utilities']),
            'amount' => $this->faker->numberBetween(100, 50000), // Use integer since DB uses bigInteger (in cents)
            'description' => $this->faker->optional()->sentence(),
            'date' => $this->faker->date(),
        ];
    }
}
