<?php

namespace App\Http\Controllers;

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
        $previousMonth = Carbon::now()->subMonth();

        $previousMonthExpenses = Expense::where('user_id', $user->id)
            ->whereYear('date', $previousMonth->year)
            ->whereMonth('date', $previousMonth->month)
            ->get();

        if ($previousMonthExpenses->isEmpty()) {
            return response()->json(['message' => 'No suggestions available for the first month'], 200);
        }

        $categoryExpenses = $previousMonthExpenses->groupBy('category')->map(function ($expenses) {
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

        return response()->json([
            'message' => 'Category priority suggestions based on previous month expenses',
            'suggested_priorities' => $suggestedPriorities
        ], 200);
    }
}
