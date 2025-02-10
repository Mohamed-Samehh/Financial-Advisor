<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\PersonalAccessToken;
use Illuminate\Support\Facades\Notification;
use App\Notifications\ResetPasswordNotification;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            $errors = $validator->errors();
            if ($errors->has('email')) {
                return response()->json(['error' => 'The email is already registered.'], 400);
            }
            return response()->json($errors, 400);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        // Adding default categories
        $categories = [
            ['name' => 'Rent', 'priority' => 1],
            ['name' => 'Groceries', 'priority' => 2],
            ['name' => 'Health', 'priority' => 3],
            ['name' => 'Utilities', 'priority' => 4],
            ['name' => 'Transportation', 'priority' => 5],
            ['name' => 'Shopping', 'priority' => 6],
            ['name' => 'Social Activities', 'priority' => 7],
            ['name' => 'Entertainment', 'priority' => 8],
            ['name' => 'Other', 'priority' => 9],
        ];

        $user->categories()->createMany($categories);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json(['token' => $token, 'user' => $user], 201);
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

        return response()->json(['message' => 'Password updated successfully'], 200);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $user->id,
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 400);
        }

        $user->update([
            'name' => $request->name,
            'email' => $request->email,
        ]);

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

        if (!$accessToken || $accessToken->created_at->addDay()->isPast()) {
            if ($accessToken) {
                $accessToken->delete();
            }
            return response()->json(['expired' => true], 401);
        }

        return response()->json(['expired' => false], 200);
    }

    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'Email not registered.'], 404);
        }

        $newPassword = Str::random(6);
        $user->update(['password' => Hash::make($newPassword)]);

        $user->notify(new ResetPasswordNotification($newPassword));

        return response()->json(['message' => 'A new password has been sent to your email.'], 200);
    }
}
