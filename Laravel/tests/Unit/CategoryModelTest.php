<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Category;
use App\Models\User;
use App\Models\Expense;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;

class CategoryModelTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    public function test_category_can_be_created_with_valid_data()
    {
        $user = User::factory()->create();

        $categoryData = [
            'user_id' => $user->id,
            'name' => 'Food & Dining',
            'priority' => 1,
        ];

        $category = Category::create($categoryData);

        $this->assertInstanceOf(Category::class, $category);
        $this->assertEquals($categoryData['user_id'], $category->user_id);
        $this->assertEquals($categoryData['name'], $category->name);
        $this->assertEquals($categoryData['priority'], $category->priority);
        $this->assertDatabaseHas('categories', $categoryData);
    }

    public function test_category_fillable_attributes()
    {
        $category = new Category();
        $fillable = $category->getFillable();

        $expectedFillable = ['user_id', 'name', 'priority'];
        
        foreach ($expectedFillable as $attribute) {
            $this->assertContains($attribute, $fillable);
        }
    }

    public function test_category_belongs_to_user()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $category->user);
        $this->assertEquals($user->id, $category->user->id);
    }

    public function test_category_has_many_expenses()
    {
        $category = Category::factory()->create();
        $expense = Expense::factory()->create();

        // Test the relationship method exists
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class, $category->expenses());
    }

    public function test_category_priority_is_integer()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create([
            'user_id' => $user->id,
            'priority' => 5
        ]);

        $this->assertIsInt($category->priority);
        $this->assertEquals(5, $category->priority);
    }

    public function test_category_name_is_string()
    {
        $user = User::factory()->create();
        $categoryName = 'Transportation';
        $category = Category::factory()->create([
            'user_id' => $user->id,
            'name' => $categoryName
        ]);

        $this->assertIsString($category->name);
        $this->assertEquals($categoryName, $category->name);
    }

    public function test_category_has_timestamps()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create(['user_id' => $user->id]);

        $this->assertNotNull($category->created_at);
        $this->assertNotNull($category->updated_at);
        $this->assertInstanceOf(\Carbon\Carbon::class, $category->created_at);
        $this->assertInstanceOf(\Carbon\Carbon::class, $category->updated_at);
    }
}
