<?php

namespace App\Http\Controllers;

use App\Models\Goal;
use App\Models\Budget;
use App\Models\Expense;
use App\Models\Category;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

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
            'category' => 'required|exists:categories,name',
            'amount' => 'required|numeric',
            'date' => 'required|date',
            'description' => 'nullable|string',
        ]);

        $category = Category::where('name', $request->category)->first();

        $expense = Expense::create([
            'user_id' => $request->user()->id,
            'category' => $category->name,
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

        $expenses = Expense::where('user_id', $user->id)
            ->whereYear('date', Carbon::now()->year)
            ->whereMonth('date', Carbon::now()->month)
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

        $expense = Expense::where('id', $id)->where('user_id', $userId)->first();

        if (!$expense) {
            return response()->json(['error' => 'Expense not found'], 404);
        }

        $request->validate([
            'category' => 'sometimes|exists:categories,name',
            'amount' => 'sometimes|numeric',
            'date' => 'sometimes|date',
            'description' => 'nullable|string',
        ]);

        if ($request->has('category')) {
            $category = Category::where('name', $request->category)->first();
            $expense->category = $category->name;
        }

        $expense->update($request->only(['category', 'amount', 'description', 'date']));

        return response()->json([
            'message' => 'Expense updated successfully',
            'expense' => $expense
        ], 200);
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

        $categories = Category::where('user_id', $user->id)->get();

        $expenses = Expense::where('user_id', $user->id)
            ->with('category')
            ->whereYear('date', Carbon::now()->year)
            ->whereMonth('date', Carbon::now()->month)
            ->get();

        $totalSpent = $expenses->sum('amount');

        $all_expenses = Expense::where('user_id', $user->id)
            ->with('category')
            ->whereYear('date', '>=', Carbon::now()->subYears(3)->year) // Get expenses for the last 3 years only
            ->get();

        $goal = Goal::where('user_id', $user->id)
            ->whereMonth('created_at', Carbon::now()->month)
            ->whereYear('created_at', Carbon::now()->year)
            ->first();

        $goalAmount = $goal ? $goal->target_amount : 0;

        $remainingBudget = $monthlyBudget - $totalSpent;

        $dailyExpenses = $expenses->groupBy(function ($expense) {
            return Carbon::parse($expense->date)->format('d');
        })->map(function ($dayExpenses) {
            return $dayExpenses->sum('amount');
        })->sortKeys();

        $categoriesArray = $categories->map(function ($category) {
            return [
                'name' => $category->name,
                'priority' => $category->priority,
            ];
        })->toArray();

        $expensesArray = $expenses->map(function ($expense) {
            return [
                'amount' => $expense->amount,
                'date' => $expense->date,
                'category' => $expense->category,
            ];
        })->toArray();

        $allExpensesArray = $all_expenses->map(function ($all_expenses) {
            return [
                'amount' => $all_expenses->amount,
                'date' => $all_expenses->date,
                'category' => $all_expenses->category,
            ];
        })->toArray();

        $data = [
            'expenses' => $expensesArray,
            'all_expenses' => $allExpensesArray,
            'categories' => $categoriesArray,
            'monthly_budget' => $monthlyBudget,
            'goal_amount' => $goalAmount,
            'total_spent' => $totalSpent,
        ];

        $result = [
            'category_limits' => [],
            'advice' => [],
            'smart_insights' => [],
            'frequent_patterns' => [],
        ];

        // Attempt to use Flask for analysis
        $pythonAnalysisUrl = 'http://127.0.0.1:5000/analysis';
        $response = Http::post($pythonAnalysisUrl, $data);

        if ($response->successful()) {
            $result = $response->json();
        }

        return response()->json([
            'goal' => $goalAmount,
            'monthly_budget' => $monthlyBudget,
            'total_spent' => $totalSpent,
            'remaining_budget' => $remainingBudget,
            'predicted_current_month' => $result['predicted_current_month'] ?? null,
            'predicted_next_month_weighted' => $result['predicted_next_month_weighted'] ?? null,
            'predicted_next_month_linear' => $result['predicted_next_month_linear'] ?? null,
            'category_limits' => $result['category_limits'],
            'advice' => $result['advice'],
            'smart_insights' => $result['smart_insights'],
            'frequent_patterns' => $result['frequent_patterns'],
            'daily_expenses' => $dailyExpenses,
        ], 200);
    }
}
