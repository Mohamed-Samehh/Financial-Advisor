<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Http\Controllers\CategoryController;
use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Http\Request;

class CategoryControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $categoryController;

    protected function setUp(): void
    {
        parent::setUp();
        $this->categoryController = new CategoryController();
    }

    public function test_index_returns_user_categories_ordered_by_priority()
    {
        $user = User::factory()->create();
        
        // Create categories with different priorities
        Category::factory()->create(['user_id' => $user->id, 'priority' => 3, 'name' => 'Low Priority']);
        Category::factory()->create(['user_id' => $user->id, 'priority' => 1, 'name' => 'High Priority']);
        Category::factory()->create(['user_id' => $user->id, 'priority' => 2, 'name' => 'Medium Priority']);

        // Create category for another user (should not be returned)
        $otherUser = User::factory()->create();
        Category::factory()->create(['user_id' => $otherUser->id, 'priority' => 1]);

        $request = Request::create('/api/categories', 'GET');
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->categoryController->index($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertCount(3, $responseData);
        
        // Verify categories are ordered by priority
        $this->assertEquals('High Priority', $responseData[0]['name']);
        $this->assertEquals('Medium Priority', $responseData[1]['name']);
        $this->assertEquals('Low Priority', $responseData[2]['name']);
    }

    public function test_store_creates_category_with_valid_data()
    {
        $user = User::factory()->create();

        $categoryData = [
            'name' => 'Test Category',
            'priority' => 1,
        ];

        $request = Request::create('/api/categories', 'POST', $categoryData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $response = $this->categoryController->store($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(201, $response->getStatusCode());
        $this->assertEquals('Category created successfully', $responseData['message']);
        $this->assertEquals('Test Category', $responseData['category']['name']);
        $this->assertEquals(1, $responseData['category']['priority']);
        
        $this->assertDatabaseHas('categories', [
            'user_id' => $user->id,
            'name' => 'Test Category',
            'priority' => 1,
        ]);
    }

    public function test_store_validates_required_name()
    {
        $user = User::factory()->create();

        $categoryData = [
            'priority' => 1,
            // Missing name
        ];

        $request = Request::create('/api/categories', 'POST', $categoryData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $this->categoryController->store($request);
    }

    public function test_store_validates_required_priority()
    {
        $user = User::factory()->create();

        $categoryData = [
            'name' => 'Test Category',
            // Missing priority
        ];

        $request = Request::create('/api/categories', 'POST', $categoryData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $this->categoryController->store($request);
    }

    public function test_store_validates_unique_name_per_user()
    {
        $user = User::factory()->create();
        Category::factory()->create(['user_id' => $user->id, 'name' => 'Existing Category']);

        $categoryData = [
            'name' => 'Existing Category', // Duplicate name
            'priority' => 1,
        ];

        $request = Request::create('/api/categories', 'POST', $categoryData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $this->categoryController->store($request);
    }

    public function test_store_allows_same_name_for_different_users()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        Category::factory()->create(['user_id' => $user1->id, 'name' => 'Same Name']);

        $categoryData = [
            'name' => 'Same Name', // Same name but different user
            'priority' => 1,
        ];

        $request = Request::create('/api/categories', 'POST', $categoryData);
        $request->setUserResolver(function () use ($user2) {
            return $user2;
        });

        $response = $this->categoryController->store($request);

        $this->assertEquals(201, $response->getStatusCode());
        $this->assertDatabaseHas('categories', [
            'user_id' => $user2->id,
            'name' => 'Same Name',
        ]);
    }    public function test_store_validates_priority_range()
    {
        $user = User::factory()->create();
        
        // Create 2 existing categories with unique names, so max priority should be 3
        Category::factory()->create(['user_id' => $user->id, 'name' => 'Category One', 'priority' => 1]);
        Category::factory()->create(['user_id' => $user->id, 'name' => 'Category Two', 'priority' => 2]);

        $categoryData = [
            'name' => 'Test Category',
            'priority' => 5, // Exceeds max priority (3)
        ];

        $request = Request::create('/api/categories', 'POST', $categoryData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $this->categoryController->store($request);
    }

    public function test_store_validates_minimum_priority()
    {
        $user = User::factory()->create();

        $categoryData = [
            'name' => 'Test Category',
            'priority' => 0, // Below minimum (1)
        ];

        $request = Request::create('/api/categories', 'POST', $categoryData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $this->categoryController->store($request);
    }

    public function test_store_validates_name_max_length()
    {
        $user = User::factory()->create();

        $categoryData = [
            'name' => str_repeat('a', 256), // Exceeds 255 character limit
            'priority' => 1,
        ];

        $request = Request::create('/api/categories', 'POST', $categoryData);
        $request->setUserResolver(function () use ($user) {
            return $user;
        });

        $this->expectException(\Illuminate\Validation\ValidationException::class);
        $this->categoryController->store($request);
    }
}
