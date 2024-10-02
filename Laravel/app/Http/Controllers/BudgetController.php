<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Budget;

class BudgetController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'monthly_budget' => 'required|numeric|min:0',
        ]);

        $budget = Budget::updateOrCreate(
            ['user_id' => $user->id],
            ['monthly_budget' => $validated['monthly_budget']]
        );

        return response()->json(['message' => 'Budget saved successfully', 'budget' => $budget], 200);
    }

    public function show(Request $request)
    {
        $user = $request->user();

        $budget = Budget::where('user_id', $user->id)->first();

        if (!$budget) {
            return response()->json(['message' => 'No budget found for this user'], 404);
        }

        return response()->json(['budget' => $budget], 200);
    }
}
