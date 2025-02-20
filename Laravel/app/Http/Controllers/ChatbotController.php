<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use App\Models\Goal;
use App\Models\Budget;
use App\Models\Expense;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;

class ChatbotController extends Controller
{
    // Set Time Zone for Carbon
    public function __construct()
    {
        Carbon::setLocale('en');
        date_default_timezone_set('Africa/Cairo');
    }

    public function chat(Request $request)
    {
        $userMessage = $request->input('message');
        $apiKey = env('OPENROUTER_API_KEY');

        $user = $request->user();
        $name = $user->name;

        $budget = Budget::where('user_id', $user->id)
            ->whereYear('created_at', Carbon::now()->year)
            ->whereMonth('created_at', Carbon::now()->month)
            ->first();
        $monthlyBudget = $budget->monthly_budget ?? 0;

        $goal = Goal::where('user_id', $user->id)
            ->whereYear('created_at', Carbon::now()->year)
            ->whereMonth('created_at', Carbon::now()->month)
            ->first();
        $goalName = $goal->name ?? "Unnamed Goal";
        $goalAmount = $goal->target_amount ?? 0;

        $totalSpent = Expense::where('user_id', $user->id)
            ->whereYear('date', Carbon::now()->year)
            ->whereMonth('date', Carbon::now()->month)
            ->sum('amount');
        
        $dailyExpenses = Expense::where('user_id', $user->id)
        ->whereYear('date', Carbon::now()->year)
        ->whereMonth('date', Carbon::now()->month)
        ->selectRaw('DATE(date) as day, SUM(amount) as total_spent')
        ->groupBy('day')
        ->orderBy('day', 'asc')
        ->get()
        ->mapWithKeys(fn ($expense) => [$expense->day => $expense->total_spent])
        ->toArray();

        $categories = Category::where('user_id', $user->id)
        ->select('id', 'name', 'priority')
        ->get();
    
        $categoriesArray = $categories->map(function ($category) use ($user) {
            $categoryTotal = Expense::where('user_id', $user->id)
                ->where('category', $category->name)
                ->whereYear('date', Carbon::now()->year)
                ->whereMonth('date', Carbon::now()->month)
                ->sum('amount');
    
            return [
                'name' => $category->name,
                'priority' => $category->priority,
                'total_spent' => $categoryTotal
            ];
        })->toArray();
    
        // Prepare Data for the Flask Chatbot API
        $chatbotData = [
            'message' => $userMessage,
            'api_key' => $apiKey,
            'name' => $name,
            'budget' => $monthlyBudget,
            'goal_name' => $goalName,
            'goal_amount' => $goalAmount,
            'total_spent' => $totalSpent,
            'last_day_month' => Carbon::now()->endOfMonth()->format('F j, Y'),
            'daily_expenses' => $dailyExpenses,
            'categories' => $categoriesArray
        ];

        // Call Flask chatbot API
        $response = Http::post('http://127.0.0.1:5000/chat', $chatbotData);

        if ($response->failed()) {
            Log::error('Flask Chatbot API Error: ' . $response->body());
            return response()->json(['error' => 'Failed to fetch response'], 500);
        }

        $responseData = $response->json();
        $assistantMessage = $responseData['choices'][0]['message']['content'] ?? "I'm sorry, but I couldn't generate a response. Please try again or ask in a different way.";

        return response()->json([
            'message' => $assistantMessage
        ]);
    }
}
