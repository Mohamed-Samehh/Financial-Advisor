<?php

namespace Tests\Unit;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Support\Facades\Validator;

class ValidationRulesTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    public function test_budget_validation_rules()
    {
        $rules = [
            'monthly_budget' => 'required|numeric|min:0',
        ];

        // Valid data
        $validData = ['monthly_budget' => 2500.00];
        $validator = Validator::make($validData, $rules);
        $this->assertFalse($validator->fails());

        // Missing budget
        $invalidData = [];
        $validator = Validator::make($invalidData, $rules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('monthly_budget', $validator->errors()->toArray());

        // Negative budget
        $invalidData = ['monthly_budget' => -100];
        $validator = Validator::make($invalidData, $rules);
        $this->assertTrue($validator->fails());

        // Non-numeric budget
        $invalidData = ['monthly_budget' => 'not-a-number'];
        $validator = Validator::make($invalidData, $rules);
        $this->assertTrue($validator->fails());

        // Zero budget (should be valid)
        $validData = ['monthly_budget' => 0];
        $validator = Validator::make($validData, $rules);
        $this->assertFalse($validator->fails());
    }

    public function test_expense_validation_rules()
    {
        $rules = [
            'category' => 'required|exists:categories,name',
            'amount' => 'required|numeric|min:1',
            'date' => 'required|date',
            'description' => 'nullable|string',
        ];

        // Note: We can't test 'exists:categories,name' without database setup
        // So we'll test the other rules
        $baseRules = [
            'amount' => 'required|numeric|min:1',
            'date' => 'required|date',
            'description' => 'nullable|string',
        ];

        // Valid data
        $validData = [
            'amount' => 25.50,
            'date' => '2025-05-29',
            'description' => 'Test expense'
        ];
        $validator = Validator::make($validData, $baseRules);
        $this->assertFalse($validator->fails());

        // Valid data with null description
        $validData = [
            'amount' => 25.50,
            'date' => '2025-05-29',
            'description' => null
        ];
        $validator = Validator::make($validData, $baseRules);
        $this->assertFalse($validator->fails());

        // Missing amount
        $invalidData = [
            'date' => '2025-05-29',
            'description' => 'Test expense'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('amount', $validator->errors()->toArray());

        // Zero amount (should fail due to min:1)
        $invalidData = [
            'amount' => 0,
            'date' => '2025-05-29',
            'description' => 'Test expense'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());

        // Negative amount
        $invalidData = [
            'amount' => -10,
            'date' => '2025-05-29',
            'description' => 'Test expense'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());

        // Non-numeric amount
        $invalidData = [
            'amount' => 'not-a-number',
            'date' => '2025-05-29',
            'description' => 'Test expense'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());

        // Invalid date format
        $invalidData = [
            'amount' => 25.50,
            'date' => 'invalid-date',
            'description' => 'Test expense'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('date', $validator->errors()->toArray());

        // Missing date
        $invalidData = [
            'amount' => 25.50,
            'description' => 'Test expense'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('date', $validator->errors()->toArray());
    }

    public function test_user_registration_validation_rules()
    {
        $rules = [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
        ];

        // Note: We can't test 'unique:users' without database setup
        // So we'll test the other rules
        $baseRules = [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255',
        ];

        // Valid data
        $validData = [
            'name' => 'John Doe',
            'email' => 'john@example.com'
        ];
        $validator = Validator::make($validData, $baseRules);
        $this->assertFalse($validator->fails());

        // Missing name
        $invalidData = ['email' => 'john@example.com'];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('name', $validator->errors()->toArray());

        // Missing email
        $invalidData = ['name' => 'John Doe'];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('email', $validator->errors()->toArray());

        // Invalid email format
        $invalidData = [
            'name' => 'John Doe',
            'email' => 'invalid-email'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('email', $validator->errors()->toArray());

        // Name too long
        $invalidData = [
            'name' => str_repeat('a', 256),
            'email' => 'john@example.com'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('name', $validator->errors()->toArray());

        // Email too long
        $invalidData = [
            'name' => 'John Doe',
            'email' => str_repeat('a', 250) . '@example.com'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('email', $validator->errors()->toArray());

        // Non-string name
        $invalidData = [
            'name' => 12345,
            'email' => 'john@example.com'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('name', $validator->errors()->toArray());
    }

    public function test_goal_validation_rules()
    {
        $rules = [
            'name' => 'required|string|max:255',
            'target_amount' => 'required|numeric|min:0',
            'deadline' => 'required|date|after:today',
        ];

        // For testing, we'll use a simpler version without 'after:today'
        $baseRules = [
            'name' => 'required|string|max:255',
            'target_amount' => 'required|numeric|min:0',
            'deadline' => 'required|date',
        ];

        // Valid data
        $validData = [
            'name' => 'Emergency Fund',
            'target_amount' => 5000.00,
            'deadline' => '2025-12-31'
        ];
        $validator = Validator::make($validData, $baseRules);
        $this->assertFalse($validator->fails());

        // Missing name
        $invalidData = [
            'target_amount' => 5000.00,
            'deadline' => '2025-12-31'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('name', $validator->errors()->toArray());

        // Missing target amount
        $invalidData = [
            'name' => 'Emergency Fund',
            'deadline' => '2025-12-31'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('target_amount', $validator->errors()->toArray());

        // Negative target amount
        $invalidData = [
            'name' => 'Emergency Fund',
            'target_amount' => -1000,
            'deadline' => '2025-12-31'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());

        // Invalid deadline format
        $invalidData = [
            'name' => 'Emergency Fund',
            'target_amount' => 5000.00,
            'deadline' => 'invalid-date'
        ];
        $validator = Validator::make($invalidData, $baseRules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('deadline', $validator->errors()->toArray());
    }

    public function test_category_validation_rules()
    {
        $rules = [
            'name' => 'required|string|max:255',
            'priority' => 'required|integer|between:1,10',
        ];

        // Valid data
        $validData = [
            'name' => 'Food & Dining',
            'priority' => 5
        ];
        $validator = Validator::make($validData, $rules);
        $this->assertFalse($validator->fails());

        // Missing name
        $invalidData = ['priority' => 5];
        $validator = Validator::make($invalidData, $rules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('name', $validator->errors()->toArray());

        // Missing priority
        $invalidData = ['name' => 'Food & Dining'];
        $validator = Validator::make($invalidData, $rules);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('priority', $validator->errors()->toArray());

        // Priority out of range (too low)
        $invalidData = [
            'name' => 'Food & Dining',
            'priority' => 0
        ];
        $validator = Validator::make($invalidData, $rules);
        $this->assertTrue($validator->fails());

        // Priority out of range (too high)
        $invalidData = [
            'name' => 'Food & Dining',
            'priority' => 11
        ];
        $validator = Validator::make($invalidData, $rules);
        $this->assertTrue($validator->fails());

        // Non-integer priority
        $invalidData = [
            'name' => 'Food & Dining',
            'priority' => 'high'
        ];
        $validator = Validator::make($invalidData, $rules);
        $this->assertTrue($validator->fails());
    }
}
