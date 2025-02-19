<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Goal;
use Carbon\Carbon;

class GoalController extends Controller
{
    // Set Time Zone for Carbon
    public function __construct()
    {
        Carbon::setLocale('en');
        date_default_timezone_set('Africa/Cairo');
    }
    
    // Display all goals ever entered by the user (index)
    public function index(Request $request)
    {
        $user = $request->user();

        $goals = Goal::where('user_id', $user->id)->orderBy('created_at', 'desc')->get();

        return response()->json(['goals' => $goals], 200);
    }

    // Store a goal for the current month
    public function store(Request $request)
    {
        $user = $request->user();
        $currentMonth = Carbon::now()->format('Y-m');

        $existingGoal = Goal::where('user_id', $user->id)
            ->whereMonth('created_at', Carbon::now()->month)
            ->whereYear('created_at', Carbon::now()->year)
            ->first();

        if ($existingGoal) {
            return response()->json(['message' => 'A goal for this month already exists. You can only add one goal per month.'], 403);
        }

        // Validate the input
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'target_amount' => 'required|numeric|min:1',
        ]);

        $goal = Goal::create([
            'user_id' => $user->id,
            'name' => $validated['name'],
            'target_amount' => $validated['target_amount'],
        ]);

        return response()->json(['message' => 'Goal created successfully', 'goal' => $goal], 201);
    }

    // Show the goal for the current month
    public function show(Request $request)
    {
        $user = $request->user();
        $currentMonth = Carbon::now()->format('Y-m');

        $goal = Goal::where('user_id', $user->id)
            ->whereMonth('created_at', Carbon::now()->month)
            ->whereYear('created_at', Carbon::now()->year)
            ->first();

        if (!$goal) {
            return response()->json(['message' => 'No goal found for this month'], 404);
        }

        return response()->json(['goal' => $goal], 200);
    }

    // Update the goal for the current month
    public function update(Request $request, $id)
    {
        $user = $request->user();

        $goal = Goal::where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (!$goal) {
            return response()->json(['message' => 'Goal not found'], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'target_amount' => 'required|numeric|min:1',
        ]);

        $goal->update($validated);

        return response()->json(['message' => 'Goal updated successfully', 'goal' => $goal], 200);
    }

    // Delete a specific goal by ID
    public function destroy(Request $request, $id)
    {
        $user = $request->user();

        $goal = Goal::where('id', $id)->where('user_id', $user->id)->first();

        if (!$goal) {
            return response()->json(['message' => 'Goal not found'], 404);
        }

        $goal->delete();

        return response()->json(['message' => 'Goal deleted successfully'], 200);
    }
}
