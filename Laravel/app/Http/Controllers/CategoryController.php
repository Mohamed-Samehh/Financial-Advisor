<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use App\Models\Expense;
use App\Models\Category;
use Illuminate\Http\Request;
use Carbon\Carbon;

class CategoryController extends Controller
{
    // Retrieve all categories for the user
    public function index(Request $request)
    {
        $categories = Category::where('user_id', $request->user()->id)
            ->orderBy('priority')
            ->get();

        return response()->json($categories, 200);
    }

    // Create a new category
    public function store(Request $request)
    {
        $maxPriority = Category::where('user_id', $request->user()->id)->count() + 1;

        $request->validate([
            'name' => 'required|string|max:255|unique:categories,name,NULL,id,user_id,' . $request->user()->id,
            'priority' => 'required|integer|min:1|max:' . $maxPriority,
        ]);

        $category = Category::create([
            'user_id' => $request->user()->id,
            'name' => $request->name,
            'priority' => $request->priority,
        ]);

        return response()->json(['message' => 'Category created successfully', 'category' => $category], 201);
    }

    // Update an existing category
    public function update(Request $request, $id)
    {
        $category = Category::where('id', $id)
                            ->where('user_id', $request->user()->id)
                            ->first();

        if (!$category) {
            return response()->json(['error' => 'Category not found'], 404);
        }

        $maxPriority = Category::where('user_id', $request->user()->id)->count();

        $request->validate([
            'name' => 'sometimes|string|max:255|unique:categories,name,' . $id . ',id,user_id,' . $request->user()->id,
            'priority' => 'sometimes|integer|min:1|max:' . $maxPriority,
        ]);

        if ($request->has('name') && $category->name !== $request->name) {
            Expense::where('user_id', $request->user()->id)
                ->where('category', $category->name)
                ->update(['category' => $request->name]);
        }

        $category->update($request->only(['name', 'priority']));

        return response()->json([
            'message' => 'Category updated successfully',
            'category' => $category
        ], 200);
    }

    // Delete a category and assign expenses to a new category
    public function destroy(Request $request, $id)
    {
        $request->validate([
            'new_category' => 'required|string',
        ]);

        $userId = $request->user()->id;
        $inputCategoryName = $request->input('new_category');

        // Find the exact match for the new category
        $existingCategory = Category::whereRaw('LOWER(`name`) = ?', [strtolower($inputCategoryName)])
            ->where('user_id', $userId)
            ->first();

        if (!$existingCategory) {
            return response()->json(['error' => 'The selected category does not exist.'], 404);
        }

        $category = Category::where('id', $id)
            ->where('user_id', $userId)
            ->first();

        if ($category) {
            if (strtolower($category->name) === strtolower($existingCategory->name)) {
                return response()->json(['error' => 'You cannot assign expenses to the same category being deleted.'], 400);
            }

            Expense::where('category', $category->name)
                ->where('user_id', $userId)
                ->update(['category' => $existingCategory->name]);

            $category->delete();

            return response()->json(['message' => 'Category deleted and expenses reassigned successfully'], 200);
        }

        return response()->json(['error' => 'Category not found'], 404);
    }

    // Suggest Category Priorities
    public function suggestCategoryPriorities(Request $request)
    {
        $user = $request->user();

        $currentYear = Carbon::now()->year;
        $currentMonth = Carbon::now()->month;
        $lastExpense = Expense::where('user_id', $user->id)
            ->where(function ($query) use ($currentYear, $currentMonth) {
                $query->whereYear('date', '<', $currentYear)
                    ->orWhere(function ($query) use ($currentYear, $currentMonth) {
                        $query->whereYear('date', $currentYear)
                                ->whereMonth('date', '<', $currentMonth);
                    });
            })
            ->orderBy('date', 'desc')
            ->first();

        if (!$lastExpense) {
            return response()->json(['message' => 'No expenses found for the user (excluding the current month)'], 200);
        }

        $lastMonthWithExpenses = Carbon::parse($lastExpense->date)->startOfMonth();
        $lastMonthExpenses = Expense::where('user_id', $user->id)
            ->whereYear('date', $lastMonthWithExpenses->year)
            ->whereMonth('date', $lastMonthWithExpenses->month)
            ->get();

        if ($lastMonthExpenses->isEmpty()) {
            return response()->json(['message' => 'No suggestions available'], 200);
        }

        $categoryExpenses = $lastMonthExpenses->groupBy('category')->map(function ($expenses) {
            return $expenses->sum('amount');
        });

        $sortedCategories = $categoryExpenses->sortDesc();

        $suggestedPriorities = [];
        $priority = 1;
        $lastAmount = null;

        foreach ($sortedCategories as $category => $totalAmount) {
            if ($totalAmount !== $lastAmount) {
                $lastAmount = $totalAmount;
            } else {
                $priority--;
            }

            $suggestedPriorities[] = [
                'category' => $category,
                'suggested_priority' => $priority,
                'total_expenses' => $totalAmount,
            ];

            $priority++;
        }

        $formattedDate = $lastMonthWithExpenses->format('F Y');

        return response()->json([
            'message' => 'Suggested category priorities based on your spending in the most recent month with expenses (excluding the current month).',
            'last_month_with_expenses' => $formattedDate,
            'suggested_priorities' => $suggestedPriorities
        ], 200);
    }

    // Classify Categories Importance
    public function classifyCategories(Request $request)
    {
        $user = $request->user();

        $all_expenses = Expense::where('user_id', $user->id)
            ->with('category')
            ->whereYear('date', '>', Carbon::now()->subYears(3)->year) // Get last 3 years' expenses
            ->get();

        $distinctMonths = $all_expenses->map(function ($expense) {
            return Carbon::parse($expense->date)->format('Y-m');
        })->unique();

        if ($distinctMonths->count() < 2) {
            return response()->json([
                'message' => 'Not enough data: At least two months of expense history required.'
            ], 400);
        }

        $allExpensesArray = $all_expenses->map(function ($all_expenses) {
            return [
                'amount' => $all_expenses->amount,
                'date' => $all_expenses->date,
                'category' => $all_expenses->category,
            ];
        })->toArray();

        $flaskPassword = "Y7!mK4@vW9#qRp$2"; // Security layer
        $data = [
            'all_expenses' => $allExpensesArray,
            'password' => $flaskPassword,
        ];

        // Call Flask API for classification
        try {
            $flaskClassificationUrl = 'http://127.0.0.1:5000/importance-classification';
            $response = Http::post($flaskClassificationUrl, $data);

            if ($response->successful()) {
                $result = $response->json();
            }
        } catch (\Exception $e) {
            Log::error('Flask classification failed: ' . $e->getMessage());
        }

        return response()->json([
            'importance_classification' => $result['importance_classification'] ?? [],
        ], 200);
    }
}
