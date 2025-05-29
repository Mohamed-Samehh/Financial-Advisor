<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Expense;
use App\Models\User;
use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;

class ExpenseModelTest extends TestCase
{
    use RefreshDatabase, WithFaker;    public function test_expense_can_be_created_with_valid_data()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create();

        $expenseData = [
            'user_id' => $user->id,
            'category' => $category->name,
            'amount' => 15075, // Use integer since DB uses bigInteger (in cents)
            'description' => $this->faker->sentence,
            'date' => now()->format('Y-m-d'),
        ];

        $expense = Expense::create($expenseData);

        $this->assertInstanceOf(Expense::class, $expense);
        $this->assertEquals($expenseData['user_id'], $expense->user_id);
        $this->assertEquals($expenseData['amount'], $expense->amount);
        $this->assertEquals($expenseData['description'], $expense->description);
        $this->assertDatabaseHas('expenses', $expenseData);
    }

    public function test_expense_fillable_attributes()
    {
        $expense = new Expense();
        $fillable = $expense->getFillable();

        $expectedFillable = ['user_id', 'category', 'amount', 'description', 'date'];
        
        foreach ($expectedFillable as $attribute) {
            $this->assertContains($attribute, $fillable);
        }
    }

    public function test_expense_belongs_to_user()
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $expense->user);
        $this->assertEquals($user->id, $expense->user->id);
    }

    public function test_expense_belongs_to_category()
    {
        $category = Category::factory()->create();
        $expense = Expense::factory()->create();

        // Since we're testing the relationship, we need to ensure the category method works
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $expense->category());
    }    public function test_expense_amount_is_numeric()
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 9999 // Use integer since DB uses bigInteger (in cents)
        ]);

        $this->assertIsNumeric($expense->amount);
        $this->assertEquals(9999, $expense->amount);
    }

    public function test_expense_date_format()
    {
        $user = User::factory()->create();
        $date = '2025-05-29';
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'date' => $date
        ]);

        $this->assertEquals($date, $expense->date);
    }

    public function test_expense_can_have_null_description()
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'description' => null
        ]);

        $this->assertNull($expense->description);
    }
}
