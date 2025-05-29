<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class CategoryFactory extends Factory
{
    protected $model = Category::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => $this->faker->randomElement([
                'Food & Dining',
                'Transportation',
                'Shopping',
                'Entertainment',
                'Bills & Utilities',
                'Healthcare',
                'Travel',
                'Education',
                'Personal Care',
                'Gifts & Donations'
            ]),
            'priority' => $this->faker->numberBetween(1, 10),
        ];
    }
}
