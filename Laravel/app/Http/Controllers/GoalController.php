<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Goal;

class GoalController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'target_amount' => 'required|numeric|min:0',
            'deadline' => 'required|date',
        ]);

        $goal = Goal::create([
            'user_id' => $user->id,
            'name' => $validated['name'],
            'target_amount' => $validated['target_amount'],
            'deadline' => $validated['deadline'],
        ]);

        return response()->json(['message' => 'Goal created successfully', 'goal' => $goal], 201);
    }

    public function index(Request $request)
    {
        $user = $request->user();

        $goals = Goal::where('user_id', $user->id)->get();

        return response()->json(['goals' => $goals], 200);
    }

    public function show(Request $request, $id)
    {
        $user = $request->user();

        $goal = Goal::where('id', $id)->where('user_id', $user->id)->first();

        if (!$goal) {
            return response()->json(['message' => 'Goal not found'], 404);
        }

        return response()->json(['goal' => $goal], 200);
    }

    public function update(Request $request, $id)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'target_amount' => 'required|numeric|min:0',
            'deadline' => 'required|date',
        ]);

        $goal = Goal::where('id', $id)->where('user_id', $user->id)->first();

        if (!$goal) {
            return response()->json(['message' => 'Goal not found'], 404);
        }

        $goal->update($validated);

        return response()->json(['message' => 'Goal updated successfully', 'goal' => $goal], 200);
    }

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
