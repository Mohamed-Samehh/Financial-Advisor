<?php

namespace App\Http\Controllers;

use App\Models\Goal;
use App\Models\Budget;
use App\Models\Expense;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'category' => 'required|string',
            'amount' => 'required|numeric',
            'date' => 'required|date',
        ]);

        $expense = Expense::create([
            'user_id' => $request->user()->id,
            'category' => $request->category,
            'amount' => $request->amount,
            'description' => $request->description,
            'date' => $request->date,
        ]);

        return response()->json([
            'message' => 'Expense added successfully',
            'expense' => $expense
        ], 201);
    }

    public function index(Request $request)
    {
        $expenses = Expense::where('user_id', $request->user()->id)->get();
        return response()->json($expenses, 200);
    }

    public function destroy(Request $request, $id)
    {
        $userId = $request->user()->id;

        $expense = Expense::where('id', $id)->where('user_id', $userId)->first();

        if ($expense) {
            $expense->delete();
            return response()->json(['message' => 'Expense deleted successfully'], 200);
        }

        return response()->json(['error' => 'Expense not found'], 404);
    }

    public function analyzeExpenses(Request $request)
    {
        $user = $request->user();

        $budget = Budget::where('user_id', $user->id)->first();

        if (!$budget) {
            return response()->json(['error' => 'No budget set for this user'], 404);
        }

        $monthlyBudget = $budget->monthly_budget;

        $expenses = Expense::where('user_id', $user->id)
                            ->whereMonth('date', now()->month)
                            ->get();

        if ($expenses->isEmpty()) {
            return response()->json([
                'error' => 'No expenses found for the current month',
                'debug' => $expenses
            ], 200);
        }

        $totalSpent = $expenses->sum('amount');
        $remainingBudget = $monthlyBudget - $totalSpent;

        $advice = [];
        if ($totalSpent > $monthlyBudget) {
            $advice[] = 'You have exceeded your monthly budget!';
        } else {
            $advice[] = 'You are within your budget.';
        }

        $goals = Goal::where('user_id', $user->id)->get();

        foreach ($goals as $goal) {
            $goalProgress = $goal->target_amount - $totalSpent;
            if ($goalProgress <= 0) {
                $advice[] = "Congratulations! You've reached your goal of '{$goal->name}'.";
            } else {
                $advice[] = "To reach your goal of '{$goal->name}', you need to save an additional \${$goalProgress}.";
            }
        }

        $categoryTotals = $expenses->groupBy('category')->map(function ($row) {
            return $row->sum('amount');
        });

        foreach ($categoryTotals as $category => $total) {
            if ($total > ($monthlyBudget * 0.3)) {
                $advice[] = "You're spending too much on {$category}. Consider cutting down.";
            }
        }

        return response()->json([
            'total_spent' => $totalSpent,
            'remaining_budget' => $remainingBudget,
            'advice' => $advice,
            'expenses_analyzed' => $expenses
        ], 200);
    }
}
