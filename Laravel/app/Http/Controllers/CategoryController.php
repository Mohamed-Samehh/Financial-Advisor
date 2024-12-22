<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Models\Category;
use Illuminate\Http\Request;

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

    // Retrieve a single category by ID
    public function show(Request $request, $id)
    {
        $category = Category::where('user_id', $request->user()->id)
                            ->where('id', $id)
                            ->first();

        if (!$category) {
            return response()->json(['error' => 'Category not found'], 404);
        }

        return response()->json($category, 200);
    }

    // Create a new category
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:categories,name,NULL,id,user_id,' . $request->user()->id,
            'priority' => 'nullable|integer|min:0|unique:categories,priority,NULL,id,user_id,' . $request->user()->id,
        ]);

        $category = Category::create([
            'user_id' => $request->user()->id,
            'name' => $request->name,
            'priority' => $request->priority ?? 0,
        ]);

        return response()->json(['message' => 'Category created successfully', 'category' => $category], 201);
    }

    // Update an existing category
    public function update(Request $request, $id)
    {
        $category = Category::where('id', $id)->where('user_id', $request->user()->id)->first();

        if (!$category) {
            return response()->json(['error' => 'Category not found'], 404);
        }

        $request->validate([
            'name' => 'sometimes|string|max:255|unique:categories,name,' . $id . ',id,user_id,' . $request->user()->id,
            'priority' => 'sometimes|integer|min:0|unique:categories,priority,' . $id . ',id,user_id,' . $request->user()->id,
        ]);

        $category->update($request->only(['name', 'priority']));

        return response()->json(['message' => 'Category updated successfully', 'category' => $category], 200);
    }

    // Delete a category
    public function destroy(Request $request, $id)
    {
        $category = Category::where('id', $id)->where('user_id', $request->user()->id)->first();

        if ($category) {
            $otherCategory = Category::firstOrCreate(
                ['name' => 'Other', 'user_id' => $request->user()->id],
                ['priority' => 0]
            );

            Expense::where('category', $category->name)
                ->update(['category' => $otherCategory->name]);

            $category->delete();

            return response()->json(['message' => 'Category deleted successfully'], 200);
        }

        return response()->json(['error' => 'Category not found'], 404);
    }
}
