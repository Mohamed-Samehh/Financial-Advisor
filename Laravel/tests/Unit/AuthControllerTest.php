<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Http\Controllers\AuthController;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;

class AuthControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $authController;

    protected function setUp(): void
    {
        parent::setUp();
        $this->authController = new AuthController();
        Mail::fake(); // Prevent actual emails from being sent
    }

    public function test_register_creates_user_with_valid_data()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(201, $response->getStatusCode());
        $this->assertEquals('Registration successful. Please check your email for your password.', $responseData['message']);
        
        $this->assertDatabaseHas('users', [
            'name' => $userData['name'],
            'email' => $userData['email'],
        ]);

        // Verify email was sent
        Mail::assertSent(\App\Mail\WelcomeMail::class);
    }

    public function test_register_fails_with_duplicate_email()
    {
        $existingUser = User::factory()->create();

        $userData = [
            'name' => $this->faker->name,
            'email' => $existingUser->email, // Duplicate email
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);
        $responseData = json_decode($response->getContent(), true);

        $this->assertEquals(400, $response->getStatusCode());
        $this->assertEquals('The email is already registered.', $responseData['error']);
    }

    public function test_register_validates_required_name()
    {
        $userData = [
            'email' => $this->faker->unique()->safeEmail,
            // Missing name
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);

        $this->assertEquals(400, $response->getStatusCode());
    }

    public function test_register_validates_required_email()
    {
        $userData = [
            'name' => $this->faker->name,
            // Missing email
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);

        $this->assertEquals(400, $response->getStatusCode());
    }

    public function test_register_validates_email_format()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => 'invalid-email-format',
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);

        $this->assertEquals(400, $response->getStatusCode());
    }

    public function test_register_validates_name_max_length()
    {
        $userData = [
            'name' => str_repeat('a', 256), // Too long
            'email' => $this->faker->unique()->safeEmail,
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);

        $this->assertEquals(400, $response->getStatusCode());
    }

    public function test_register_validates_email_max_length()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => str_repeat('a', 250) . '@example.com', // Too long
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);

        $this->assertEquals(400, $response->getStatusCode());
    }

    public function test_register_creates_hashed_password()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);

        $this->assertEquals(201, $response->getStatusCode());

        $user = User::where('email', $userData['email'])->first();
        $this->assertNotNull($user);
        $this->assertNotNull($user->password);
        $this->assertTrue(Hash::check($user->password, $user->password) === false); // Password should be hashed
    }

    public function test_register_generates_random_password()
    {
        $userData1 = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $userData2 = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $request1 = Request::create('/register', 'POST', $userData1);
        $request2 = Request::create('/register', 'POST', $userData2);

        $this->authController->register($request1);
        $this->authController->register($request2);

        $user1 = User::where('email', $userData1['email'])->first();
        $user2 = User::where('email', $userData2['email'])->first();

        // Different users should have different passwords
        $this->assertNotEquals($user1->password, $user2->password);
    }

    public function test_register_sends_welcome_email()
    {
        $userData = [
            'name' => $this->faker->name,
            'email' => $this->faker->unique()->safeEmail,
        ];

        $request = Request::create('/register', 'POST', $userData);

        $response = $this->authController->register($request);

        $this->assertEquals(201, $response->getStatusCode());

        // Verify welcome email was sent to the correct recipient
        Mail::assertSent(\App\Mail\WelcomeMail::class, function ($mail) use ($userData) {
            return $mail->hasTo($userData['email']);
        });
    }
}
