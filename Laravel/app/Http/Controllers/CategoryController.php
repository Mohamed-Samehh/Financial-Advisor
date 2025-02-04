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

        $lastExpense = Expense::where('user_id', $user->id)
            ->whereDate('date', '<', Carbon::now()->startOfMonth())
            ->orderBy('date', 'desc')
            ->first();

        if (!$lastExpense) {
            return response()->json(['message' => 'No expenses found for the user (excluding the current month)'], 200);
        }

        $lastExpenseYear = Carbon::parse($lastExpense->date)->year;
        $lastExpenseMonth = Carbon::parse($lastExpense->date)->month;

        $lastMonthExpenses = Expense::where('user_id', $user->id)
            ->whereYear('date', $lastExpenseYear)
            ->whereMonth('date', $lastExpenseMonth)
            ->get();

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

        $formattedDate = Carbon::create($lastExpenseYear, $lastExpenseMonth)->format('F Y');

        return response()->json([
            'last_month_suggested' => $formattedDate,
            'suggested_priorities' => $suggestedPriorities
        ], 200);
    }

    // Label Categories Importance
    public function labelCategories(Request $request)
    {
        $user = $request->user();

        $lastExpense = Expense::where('user_id', $user->id)
            ->whereDate('date', '<', Carbon::now()->startOfMonth())
            ->orderBy('date', 'desc')
            ->first();

        if (!$lastExpense) {
            return response()->json(['message' => 'No expenses found for the user (excluding the current month)'], 200);
        }

        $lastExpenseYear = Carbon::parse($lastExpense->date)->year;
        $lastExpenseMonth = Carbon::parse($lastExpense->date)->month;

        $lastMonthExpenses = Expense::where('user_id', $user->id)
            ->whereYear('date', $lastExpenseYear)
            ->whereMonth('date', $lastExpenseMonth)
            ->get();

        $lastExpensesArray = $lastMonthExpenses->map(function ($expense) {
            return [
                'amount' => $expense->amount,
                'date' => $expense->date,
                'category' => $expense->category,
            ];
        })->toArray();

        $flaskPassword = "Y7!mK4@vW9#qRp$2";
        $data = [
            'last_expenses' => $lastExpensesArray,
            'password' => $flaskPassword,
        ];

        try {
            $flaskUrl = 'http://127.0.0.1:5000/label_categories';
            $response = Http::post($flaskUrl, $data);

            if ($response->successful()) {
                $result = $response->json();
            }
        } catch (\Exception $e) {
            Log::error('Flask labeling failed: ' . $e->getMessage());
        }

        $formattedDate = Carbon::create($lastExpenseYear, $lastExpenseMonth)->format('F Y');

        return response()->json([
            'last_month_labeled' => $formattedDate,
            'labaled_categories' => $result['labaled_categories'] ?? [],
        ], 200);
    }
}
