<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Laravel\Sanctum\PersonalAccessToken;
use Illuminate\Support\Facades\Config;
use Carbon\Carbon;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Mail;
use App\Mail\WelcomeMail;
use App\Mail\ResetPasswordMail;
use App\Mail\GoodbyeMail;
use App\Mail\PasswordChangedMail;
use App\Mail\EmailUpdatedMail;

class AuthController extends Controller
{   
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
        ]);

        if ($validator->fails()) {
            $errors = $validator->errors();
            if ($errors->has('email')) {
                return response()->json(['error' => 'The email is already registered.'], 400);
            }
            return response()->json($errors, 400);
        }

        // Generate a random password
        $randomPassword = Str::random(8);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($randomPassword),
        ]);

        // Send welcome email with the random password
        Mail::to($user->email)->send(new WelcomeMail($user, $randomPassword));

        return response()->json(['message' => 'Registration successful. Please check your email for your password.'], 201);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 400);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['error' => 'Invalid credentials'], 401);
        }

        // Add default categories when verified
        if (is_null($user->email_verified_at)) {
            $user->email_verified_at = Carbon::now();
            $user->save();

            $categories = [
                ['name' => 'Rent & Utilities', 'priority' => 1],
                ['name' => 'Groceries', 'priority' => 2],
                ['name' => 'Shopping', 'priority' => 3],
                ['name' => 'Social Activities & Entertainment', 'priority' => 4],
                ['name' => 'Transportation', 'priority' => 5],
                ['name' => 'Other', 'priority' => 6],
            ];

            $user->categories()->createMany($categories);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json(['token' => $token, 'user' => $user], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();
        return response()->json(['message' => 'Logged out'], 200);
    }

    public function updatePassword(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 400);
        }

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json(['error' => 'Current password is incorrect'], 400);
        }

        $user->update([
            'password' => Hash::make($request->new_password),
        ]);

        // Force delete all tokens for the user
        $currentToken = $request->bearerToken();
        $activeToken = PersonalAccessToken::findToken($currentToken);

        if ($activeToken) {
            PersonalAccessToken::where('tokenable_id', $user->id)
                ->where('tokenable_type', get_class($user))
                ->where('id', '!=', $activeToken->id) // Exclude the current token by ID
                ->delete();
        }

        // Send password change mail
        // Mail::to($user->email)->send(new PasswordChangedMail($user));
        return response()->json(['message' => 'Password updated successfully'], 200);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        $oldEmail = $user->email;

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $user->id,
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 400);
        }

        $emailChanged = $request->has('email') && $request->email !== $oldEmail;

        $user->update([
            'name' => $request->name,
            'email' => $request->email,
        ]);

        // Send email change mail
        // if ($emailChanged) {
        //     Mail::to($oldEmail)->send(new EmailUpdatedMail($user, $oldEmail));
        // }

        return response()->json(['message' => 'Profile updated successfully', 'user' => $user], 200);
    }

    public function getProfile(Request $request) {
        return response()->json(['user' => $request->user()], 200);
    }

    public function deleteAccount(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'password' => 'required|string',
        ]);

        if (!Hash::check($request->password, $user->password)) {
            return response()->json(['error' => 'Incorrect password'], 403);
        }

        try {
            // Send goodbye mail
            // Mail::to($user->email)->send(new GoodbyeMail($user));
            
            $user->tokens()->delete();
            $user->delete();

            return response()->json(['message' => 'Account deleted successfully'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Failed to delete account. Please try again.'], 500);
        }
    }

    public function checkTokenExpiry(Request $request)
    {
        $token = $request->input('token');

        if (!$token) {
            return response()->json(['expired' => true], 401);
        }

        $accessToken = PersonalAccessToken::findToken($token);

        if (!$accessToken) {
            return response()->json(['expired' => true], 401);
        }

        $expirationMinutes = Config::get('sanctum.expiration');

        if ($expirationMinutes !== null) {
            $expiresAt = $accessToken->created_at->addMinutes($expirationMinutes);
            if (Carbon::now()->greaterThan($expiresAt)) {
                $accessToken->delete();
                return response()->json(['expired' => true], 401);
            }
        }

        return response()->json(['expired' => false], 200);
    }

    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'The email is not registered.'], 404);
        }

        // Generate a new password
        $newPassword = Str::random(8);
        $user->update(['password' => Hash::make($newPassword)]);

        // Force delete all tokens for the user
        $currentToken = $request->bearerToken();
        $activeToken = PersonalAccessToken::findToken($currentToken);

        if ($activeToken) {
            PersonalAccessToken::where('tokenable_id', $user->id)
                ->where('tokenable_type', get_class($user))
                ->where('id', '!=', $activeToken->id) // Exclude the current token by ID
                ->delete();
        } else {
            // If no active token, delete all tokens
            PersonalAccessToken::where('tokenable_id', $user->id)
                ->where('tokenable_type', get_class($user))
                ->delete();
        }

        // Send password reset mail
        Mail::to($user->email)->send(new ResetPasswordMail($user, $newPassword));

        return response()->json(['message' => 'A new password has been sent to your email.'], 200);
    }
}
