<?php

namespace App\Http\Controllers;

use App\Models\Goal;
use App\Models\Budget;
use App\Models\Expense;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    // Retrieve all expenses for the user
    public function index(Request $request)
    {
        $expenses = Expense::where('user_id', $request->user()->id)
        ->orderBy('date', 'desc')
        ->get();
        return response()->json($expenses, 200);
    }

    // Store a new expense for the user
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

    // Show the current month's expenses
    public function show(Request $request)
    {
        $user = $request->user();
        $currentMonth = Carbon::now()->format('Y-m');

        $expenses = Expense::where('user_id', $user->id)
        ->whereYear('date', Carbon::now()->year)
        ->whereMonth('date', Carbon::now()->month)
        ->whereYear('created_at', Carbon::now()->year)
        ->whereMonth('created_at', Carbon::now()->month)
        ->orderBy('date', 'desc')
        ->get();

        if ($expenses->isEmpty()) {
            return response()->json(['message' => 'No expenses found for this month'], 404);
        }

        return response()->json(['expenses' => $expenses], 200);
    }

    // Update an existing expense for the user
    public function update(Request $request, $id)
    {
        $userId = $request->user()->id;

        $request->validate([
            'category' => 'required|string',
            'amount' => 'required|numeric',
            'date' => 'required|date',
        ]);

        $expense = Expense::where('id', $id)->where('user_id', $userId)->first();

        if (!$expense) {
            return response()->json(['error' => 'Expense not found'], 404);
        }

        $expense->update([
            'category' => $request->category,
            'amount' => $request->amount,
            'description' => $request->description,
            'date' => $request->date,
        ]);

        return response()->json(['message' => 'Expense updated successfully', 'expense' => $expense], 200);
    }

    // Delete an expense for the user
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

    // Analyze the user's expenses against their budget
    public function analyzeExpenses(Request $request)
    {
        $user = $request->user();

        $budget = Budget::where('user_id', $user->id)
            ->whereYear('created_at', Carbon::now()->year)
            ->whereMonth('created_at', Carbon::now()->month)
            ->first();

        if (!$budget) {
            return response()->json(['error' => 'No budget set for this month'], 404);
        }

        $monthlyBudget = $budget->monthly_budget;

        $expenses = Expense::where('user_id', $user->id)
            ->whereYear('date', Carbon::now()->year)
            ->whereMonth('date', Carbon::now()->month)
            ->whereYear('created_at', Carbon::now()->year)
            ->whereMonth('created_at', Carbon::now()->month)
            ->get();

        $totalSpent = 0;

        if ($expenses->isEmpty()) {
            $advice[] = 'Great job, no expenses made for the current month so far. Keep saving!';
        } else {
            $totalSpent = $expenses->sum('amount');
            $advice = [];
            if ($totalSpent > $monthlyBudget) {
                $advice[] = 'You have exceeded your monthly budget!';
            } else {
                $advice[] = 'You are within your budget.';
            }
        }

        $remainingBudget = $monthlyBudget - $totalSpent;

        $goal = Goal::where('user_id', $user->id)
            ->whereMonth('created_at', Carbon::now()->month)
            ->whereYear('created_at', Carbon::now()->year)
            ->first();

        $goalAmount = $goal ? $goal->target_amount : 0;

        $maximumSpendingGoal = $remainingBudget - $goalAmount;

        if ($goalAmount == 0) {
            $advice[] = 'No goal was set for this month.';
        } else {
            $advice = [];
            if (($totalSpent > $goalAmount) && $goalAmount !== 0) {
                $advice[] = 'You have exceeded your goal!';
            } else {
                $advice[] = 'You are within your goal.';
            }
        }

        $dailyExpenses = $expenses->groupBy(function($date) {
            return Carbon::parse($date->date)->format('d');
        })->map(function ($row) {
            return $row->sum('amount');
        })->sortKeys();

        return response()->json([
            'total_spent' => $totalSpent,
            'remaining_budget' => $remainingBudget,
            'advice' => $advice,
            'daily_expenses' => $dailyExpenses,
            'goal' => $goalAmount,
            'monthly_budget' => $monthlyBudget,
            'maximum_spending_goal' => $maximumSpendingGoal,
        ], 200);
    }
}
