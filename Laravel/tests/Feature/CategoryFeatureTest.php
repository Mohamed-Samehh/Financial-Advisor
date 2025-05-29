<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Laravel\Sanctum\Sanctum;

class CategoryFeatureTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    public function test_user_can_view_their_categories()
    {
        $user = User::factory()->create();
        Category::factory()->count(3)->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/categories');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    '*' => [
                        'id',
                        'user_id',
                        'name',
                        'priority',
                        'created_at',
                        'updated_at'
                    ]
                ]);
    }

    public function test_user_can_create_category_with_valid_data()
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $categoryData = [
            'name' => 'Test Category',
            'priority' => 1,
        ];

        $response = $this->postJson('/api/categories', $categoryData);

        $response->assertStatus(201)
                ->assertJson([
                    'message' => 'Category created successfully',
                    'category' => [
                        'name' => 'Test Category',
                        'priority' => 1,
                        'user_id' => $user->id
                    ]
                ]);

        $this->assertDatabaseHas('categories', [
            'user_id' => $user->id,
            'name' => 'Test Category',
            'priority' => 1,
        ]);
    }

    public function test_category_creation_validates_required_fields()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/categories', []);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['name', 'priority']);
    }

    public function test_category_creation_validates_unique_name_per_user()
    {
        $user = User::factory()->create();
        Category::factory()->create(['user_id' => $user->id, 'name' => 'Existing Category']);

        Sanctum::actingAs($user);

        $categoryData = [
            'name' => 'Existing Category',
            'priority' => 1,
        ];

        $response = $this->postJson('/api/categories', $categoryData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['name']);
    }

    public function test_category_creation_validates_priority_range()
    {
        $user = User::factory()->create();
        Category::factory()->count(2)->create(['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $categoryData = [
            'name' => 'Test Category',
            'priority' => 5, // Exceeds max allowed priority (should be 3)
        ];

        $response = $this->postJson('/api/categories', $categoryData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['priority']);
    }

    public function test_category_creation_validates_minimum_priority()
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $categoryData = [
            'name' => 'Test Category',
            'priority' => 0, // Below minimum
        ];

        $response = $this->postJson('/api/categories', $categoryData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['priority']);
    }

    public function test_category_creation_validates_name_max_length()
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $categoryData = [
            'name' => str_repeat('a', 256), // Exceeds 255 character limit
            'priority' => 1,
        ];

        $response = $this->postJson('/api/categories', $categoryData);

        $response->assertStatus(422)
                ->assertJsonValidationErrors(['name']);
    }    public function test_user_only_sees_their_own_categories()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        // Create categories for both users with unique names
        Category::factory()->create(['user_id' => $user1->id, 'name' => 'User1 Category 1']);
        Category::factory()->create(['user_id' => $user1->id, 'name' => 'User1 Category 2']);
        Category::factory()->create(['user_id' => $user2->id, 'name' => 'User2 Category 1']);
        Category::factory()->create(['user_id' => $user2->id, 'name' => 'User2 Category 2']);
        Category::factory()->create(['user_id' => $user2->id, 'name' => 'User2 Category 3']);

        Sanctum::actingAs($user1);

        $response = $this->getJson('/api/categories');

        $response->assertStatus(200);

        $categories = $response->json();
        
        // Verify only user1's categories are returned
        $this->assertCount(2, $categories);
        foreach ($categories as $category) {
            $this->assertEquals($user1->id, $category['user_id']);
        }
    }

    public function test_categories_are_ordered_by_priority()
    {
        $user = User::factory()->create();
        
        // Create categories with different priorities
        Category::factory()->create(['user_id' => $user->id, 'priority' => 3, 'name' => 'Low Priority']);
        Category::factory()->create(['user_id' => $user->id, 'priority' => 1, 'name' => 'High Priority']);
        Category::factory()->create(['user_id' => $user->id, 'priority' => 2, 'name' => 'Medium Priority']);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/categories');

        $response->assertStatus(200);

        $categories = $response->json();
        
        // Verify categories are ordered by priority (ascending)
        $this->assertEquals('High Priority', $categories[0]['name']);
        $this->assertEquals('Medium Priority', $categories[1]['name']);
        $this->assertEquals('Low Priority', $categories[2]['name']);
    }

    public function test_same_category_name_allowed_for_different_users()
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();
        
        // User1 creates a category
        Category::factory()->create(['user_id' => $user1->id, 'name' => 'Same Name']);

        // User2 should be able to create category with same name
        Sanctum::actingAs($user2);

        $categoryData = [
            'name' => 'Same Name',
            'priority' => 1,
        ];

        $response = $this->postJson('/api/categories', $categoryData);

        $response->assertStatus(201);
        
        $this->assertDatabaseHas('categories', [
            'user_id' => $user2->id,
            'name' => 'Same Name',
        ]);
    }

    public function test_unauthenticated_user_cannot_access_categories()
    {
        $response = $this->getJson('/api/categories');
        $response->assertStatus(401);

        $response = $this->postJson('/api/categories', [
            'name' => 'Test Category',
            'priority' => 1,
        ]);
        $response->assertStatus(401);
    }
}
