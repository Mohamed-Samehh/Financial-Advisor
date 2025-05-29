<?php

namespace Tests\Unit;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ConfigurationTest extends TestCase
{
    use RefreshDatabase;

    public function test_phpunit_configuration_is_valid()
    {
        // Test that PHPUnit is properly configured
        $this->assertTrue(true);
    }

    public function test_database_connection_works()
    {
        // Test that we can connect to the test database
        $this->assertDatabaseCount('users', 0);
    }

    public function test_laravel_environment_is_testing()
    {
        // Ensure we're running in the testing environment
        $this->assertEquals('testing', app()->environment());
    }

    public function test_faker_is_available()
    {
        // Test that Faker is available for generating test data
        $faker = \Faker\Factory::create();
        $this->assertNotNull($faker);
        $this->assertIsString($faker->name);
        $this->assertIsString($faker->email);
    }

    public function test_factory_classes_are_loadable()
    {
        // Test that our factory classes can be loaded
        $this->assertTrue(class_exists(\Database\Factories\UserFactory::class));
        $this->assertTrue(class_exists(\Database\Factories\ExpenseFactory::class));
        $this->assertTrue(class_exists(\Database\Factories\BudgetFactory::class));
        $this->assertTrue(class_exists(\Database\Factories\GoalFactory::class));
        $this->assertTrue(class_exists(\Database\Factories\CategoryFactory::class));
    }

    public function test_model_classes_are_loadable()
    {
        // Test that our model classes can be loaded
        $this->assertTrue(class_exists(\App\Models\User::class));
        $this->assertTrue(class_exists(\App\Models\Expense::class));
        $this->assertTrue(class_exists(\App\Models\Budget::class));
        $this->assertTrue(class_exists(\App\Models\Goal::class));
        $this->assertTrue(class_exists(\App\Models\Category::class));
    }

    public function test_controller_classes_are_loadable()
    {
        // Test that our controller classes can be loaded
        $this->assertTrue(class_exists(\App\Http\Controllers\AuthController::class));
        $this->assertTrue(class_exists(\App\Http\Controllers\ExpenseController::class));
        $this->assertTrue(class_exists(\App\Http\Controllers\BudgetController::class));
        $this->assertTrue(class_exists(\App\Http\Controllers\GoalController::class));
        $this->assertTrue(class_exists(\App\Http\Controllers\CategoryController::class));
    }

    public function test_mail_classes_are_loadable()
    {
        // Test that mail classes exist (mentioned in AuthController)
        $this->assertTrue(class_exists(\App\Mail\WelcomeMail::class));
    }
}
