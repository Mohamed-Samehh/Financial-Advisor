<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Request;
use Carbon\Carbon;
use App\Models\Goal;
use App\Models\Budget;
use App\Models\Expense;
use App\Models\Category;

class ExpenseController extends Controller
{
    // Set Time Zone for Carbon
    public function __construct()
    {
        Carbon::setLocale('en');
        date_default_timezone_set('Africa/Cairo');
    }

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
            'amount' => 'required|numeric|min:1',
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
            'amount' => 'sometimes|numeric|min:1',
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
            ->get();

        $goal = Goal::where('user_id', $user->id)
            ->whereMonth('created_at', Carbon::now()->month)
            ->whereYear('created_at', Carbon::now()->year)
            ->first();

        $goalAmount = $goal ? $goal->target_amount : 0;

        $remainingBudget = $monthlyBudget - $totalSpent;

        $dailyExpenses = [];
        $dailyExpenses['00'] = 0;
        $groupedExpenses = $expenses->groupBy(function ($expense) {
            return Carbon::parse($expense->date)->format('d');
        });
        foreach ($groupedExpenses as $day => $dayExpenses) {
            $dayFormatted = str_pad((string) $day, 2, '0', STR_PAD_LEFT); // Days to be of 2 digits
            $dailyExpenses[$dayFormatted] = $dayExpenses->sum('amount');
        }
        ksort($dailyExpenses);

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

        $flaskPassword = env('flaskPassword');
        $data = [
            'password' => $flaskPassword,
            'expenses' => $expensesArray,
            'all_expenses' => $allExpensesArray,
            'categories' => $categoriesArray,
            'monthly_budget' => $monthlyBudget,
            'goal_amount' => $goalAmount,
            'total_spent' => $totalSpent,
        ];

        // Call Flask API for analysis
        try {
            $flaskUrl = 'http://127.0.0.1:5000/analysis';
            $response = Http::post($flaskUrl, $data);

            if ($response->successful()) {
                $result = $response->json();
            }
        } catch (\Exception $e) {
            Log::error('Flask analysis failed: ' . $e->getMessage()); // Handle the error and continue the process
        }

        return response()->json([
            'goal' => $goalAmount,
            'monthly_budget' => $monthlyBudget,
            'total_spent' => $totalSpent,
            'remaining_budget' => $remainingBudget,
            'predicted_current_month' => $result['predicted_current_month'] ?? null,
            'predictions' => $result['predictions'] ?? [],
            'category_predictions' => $result['category_predictions'] ?? [],
            'category_limits' => $result['category_limits'] ?? [],
            'advice' => $result['advice'] ?? [],
            'smart_insights' => $result['smart_insights'] ?? [],
            'expenses_clustering' => $result['expenses_clustering'] ?? [],
            'spending_clustering' => $result['spending_clustering'] ?? [],
            'frequency_clustering' => $result['frequency_clustering'] ?? [],
            'association_rules'=> $result['association_rules'] ?? [],
            'daily_expenses' => $dailyExpenses,
        ], 200);
    }
}
