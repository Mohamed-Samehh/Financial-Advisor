<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\BudgetController;
use App\Http\Controllers\GoalController;
use App\Http\Controllers\CategoryController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::put('/update-password', [AuthController::class, 'updatePassword']);
    Route::put('/update-profile', [AuthController::class, 'updateProfile']);
    Route::get('/profile', [AuthController::class, 'getProfile']);
    Route::delete('/delete-account', [AuthController::class, 'deleteAccount']);

    Route::get('/budget/all', [BudgetController::class, 'index']);
    Route::get('/budget', [BudgetController::class, 'show']);
    Route::post('/budget', [BudgetController::class, 'store']);
    Route::put('/budget/{id}', [BudgetController::class, 'update']);
    Route::delete('/budget/{id}', [BudgetController::class, 'destroy']);

    Route::get('/goal/all', [GoalController::class, 'index']);
    Route::get('/goal', [GoalController::class, 'show']);
    Route::post('/goal', [GoalController::class, 'store']);
    Route::put('/goal/{id}', [GoalController::class, 'update']);
    Route::delete('/goal/{id}', [GoalController::class, 'destroy']);

    Route::get('/expenses/all', [ExpenseController::class, 'index']);
    Route::get('/expenses', [ExpenseController::class, 'show']);
    Route::post('/expenses', [ExpenseController::class, 'store']);
    Route::put('/expenses/{id}', [ExpenseController::class, 'update']);
    Route::delete('/expenses/{id}', [ExpenseController::class, 'destroy']);
    Route::get('/analyze-expenses', [ExpenseController::class, 'analyzeExpenses']);

    Route::get('/categories', [CategoryController::class, 'index']);
    Route::post('/categories', [CategoryController::class, 'store']);
    Route::put('/categories/{id}', [CategoryController::class, 'update']);
    Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);
    Route::get('/categories/suggest', [CategoryController::class, 'suggestCategoryPriorities']);
});
