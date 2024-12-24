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

    // Create a new category
    public function store(Request $request)
    {
        if ($request->user()->categories()->count() >= 9) {
            return response()->json(['message' => 'You can only have a maximum of 9 categories.'], 403);
        }

        $request->validate([
            'name' => 'required|string|max:255|unique:categories,name,NULL,id,user_id,' . $request->user()->id,
            'priority' => 'required|integer|min:1|max:8',
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

        $request->validate([
            'name' => 'sometimes|string|max:255|unique:categories,name,' . $id . ',id,user_id,' . $request->user()->id,
            'priority' => 'sometimes|integer|min:1|max:8',
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

    // Delete a category
    public function destroy(Request $request, $id)
    {
        $category = Category::where('id', $id)->where('user_id', $request->user()->id)->first();

        if ($category) {
            $category->delete();
            return response()->json(['message' => 'Category deleted successfully'], 200);
        }

        return response()->json(['error' => 'Category not found'], 404);
    }
}
