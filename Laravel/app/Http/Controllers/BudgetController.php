<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Budget;
use Carbon\Carbon;

class BudgetController extends Controller
{
    // List all budgets ever entered by the user
    public function index(Request $request)
    {
        $user = $request->user();

        $budgets = Budget::where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['budgets' => $budgets], 200);
    }

    // Store a budget only if one has not been entered for the current month
    public function store(Request $request)
    {
        $user = $request->user();
        $currentMonth = Carbon::now()->format('Y-m');

        $validated = $request->validate([
            'monthly_budget' => 'required|numeric|min:0',
        ]);

        $existingBudget = Budget::where('user_id', $user->id)
            ->whereYear('created_at', Carbon::now()->year)
            ->whereMonth('created_at', Carbon::now()->month)
            ->first();

        if ($existingBudget) {
            return response()->json(['message' => 'You have already added a budget for this month'], 400);
        }

        $budget = Budget::create([
            'user_id' => $user->id,
            'monthly_budget' => $validated['monthly_budget'],
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now(),
        ]);

        return response()->json(['message' => 'Budget added successfully', 'budget' => $budget], 200);
    }

    // Show the current month's budget
    public function show(Request $request)
    {
        $user = $request->user();
        $currentMonth = Carbon::now()->format('Y-m');

        $budget = Budget::where('user_id', $user->id)
            ->whereYear('created_at', Carbon::now()->year)
            ->whereMonth('created_at', Carbon::now()->month)
            ->first();

        if (!$budget) {
            return response()->json(['message' => 'No budget found for this month'], 404);
        }

        return response()->json(['budget' => $budget], 200);
    }

    // Update the current month's budget
    public function update(Request $request, $id)
    {
        $user = $request->user();

        $validated = $request->validate([
            'monthly_budget' => 'required|numeric|min:0',
        ]);

        $budget = Budget::where('id', $id)->where('user_id', $user->id)->first();

        if (!$budget) {
            return response()->json(['message' => 'Budget not found or you do not have permission to update it'], 404);
        }

        $budget->monthly_budget = $validated['monthly_budget'];
        $budget->save();

        return response()->json(['message' => 'Budget updated successfully', 'budget' => $budget], 200);
    }

    // Delete budget
    public function destroy(Request $request, $id)
    {
        $user = $request->user();

        $budget = Budget::where('id', $id)->where('user_id', $user->id)->first();

        if (!$budget) {
            return response()->json(['message' => 'Budget not found or you do not have permission to delete it'], 404);
        }

        $budget->delete();

        return response()->json(['message' => 'Budget deleted successfully'], 200);
    }
}
