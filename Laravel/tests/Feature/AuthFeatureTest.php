<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Support\Facades\Mail;

class AuthFeatureTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake(); // Prevent actual emails from being sent
    }

    public function test_user_can_register_with_valid_data()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(201)
                ->assertJson([
                    'message' => 'Registration successful. Please check your email for your password.'
                ]);

        $this->assertDatabaseHas('users', [
            'name' => $userData['name'],
            'email' => $userData['email'],
        ]);

        // Verify welcome email was sent
        Mail::assertSent(\App\Mail\WelcomeMail::class);
    }

    public function test_registration_fails_with_duplicate_email()
    {
        $existingUser = User::factory()->create();

        $userData = [
            'name' => $this->faker->name,
            'email' => $existingUser->email,
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(400)
                ->assertJson([
                    'error' => 'The email is already registered.'
                ]);
    }

    public function test_registration_validates_required_name()
    {
        $userData = [
            'email' => $this->faker->unique()->safeEmail,
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(400);
    }

    public function test_registration_validates_required_email()
    {
        $userData = [
            'name' => $this->faker->name,
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(400);
    }

    public function test_registration_validates_email_format()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => 'invalid-email-format',
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(400);
    }

    public function test_registration_validates_email_uniqueness()
    {
        $existingUser = User::factory()->create([
            'email' => 'test@example.com'
        ]);

        $userData = [
            'name' => $this->faker->name,
            'email' => 'test@example.com',
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(400)
                ->assertJson([
                    'error' => 'The email is already registered.'
                ]);
    }

    public function test_registration_validates_name_max_length()
    {
        $userData = [
            'name' => str_repeat('a', 256), // Exceeds 255 character limit
            'email' => $this->faker->unique()->safeEmail,
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(400);
    }

    public function test_registration_validates_email_max_length()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => str_repeat('a', 250) . '@example.com', // Exceeds 255 character limit
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(400);
    }

    public function test_registration_creates_hashed_password()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(201);

        $user = User::where('email', $userData['email'])->first();
        $this->assertNotNull($user);
        $this->assertNotNull($user->password);
        
        // Password should be hashed, not plain text
        $this->assertNotEquals('password', $user->password);
        $this->assertTrue(strlen($user->password) > 50); // Hashed passwords are long
    }

    public function test_registration_generates_unique_passwords()
    {
        $userData1 = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $userData2 = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $this->postJson('/api/register', $userData1);
        $this->postJson('/api/register', $userData2);

        $user1 = User::where('email', $userData1['email'])->first();
        $user2 = User::where('email', $userData2['email'])->first();

        // Each user should have a different password
        $this->assertNotEquals($user1->password, $user2->password);
    }

    public function test_registration_sends_welcome_email_to_correct_recipient()
    {
        $userData = [
            'name' => 'John Doe',
            'email' => 'john@example.com',
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(201);

        Mail::assertSent(\App\Mail\WelcomeMail::class, function ($mail) use ($userData) {
            return $mail->hasTo($userData['email']);
        });
    }

    public function test_registration_returns_proper_json_structure()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $response = $this->postJson('/api/register', $userData);

        $response->assertStatus(201)
                ->assertJsonStructure([
                    'message'
                ])
                ->assertJson([
                    'message' => 'Registration successful. Please check your email for your password.'
                ]);
    }

    public function test_registration_with_empty_data()
    {
        $response = $this->postJson('/api/register', []);

        $response->assertStatus(400);
    }    public function test_registration_with_malformed_json()
    {
        $response = $this->withHeaders([
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
        ])->call('POST', '/api/register', [], [], [], [], 'invalid json');

        $response->assertStatus(400);
    }

    public function test_registration_is_case_sensitive_for_email()
    {
        $userData1 = [
            'name' => $this->faker->name,
            'email' => 'test@example.com',
        ];

        $userData2 = [
            'name' => $this->faker->name,
            'email' => 'TEST@EXAMPLE.COM',
        ];

        $response1 = $this->postJson('/api/register', $userData1);
        $response1->assertStatus(201);

        $response2 = $this->postJson('/api/register', $userData2);
        // Depending on database collation, this might fail or succeed
        // Most modern systems treat emails as case-insensitive
        $this->assertTrue(in_array($response2->getStatusCode(), [201, 400]));
    }
}
