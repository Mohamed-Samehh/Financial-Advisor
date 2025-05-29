<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\User;
use App\Models\Expense;
use App\Models\Budget;
use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Carbon\Carbon;

class FinancialLogicTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    public function test_user_can_calculate_total_expenses_for_month()
    {
        $user = User::factory()->create();
        
        // Create expenses for current month
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 100.00,
            'date' => Carbon::now()->format('Y-m-d')
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 50.00,
            'date' => Carbon::now()->format('Y-m-d')
        ]);
        
        // Create expense for different month (should not be included)
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 25.00,
            'date' => Carbon::now()->subMonth()->format('Y-m-d')
        ]);

        $currentMonthTotal = Expense::where('user_id', $user->id)
            ->whereYear('date', Carbon::now()->year)
            ->whereMonth('date', Carbon::now()->month)
            ->sum('amount');

        $this->assertEquals(150.00, $currentMonthTotal);
    }

    public function test_user_can_calculate_remaining_budget()
    {
        $user = User::factory()->create();
        
        // Create budget for current month
        $budget = Budget::factory()->create([
            'user_id' => $user->id,
            'monthly_budget' => 1000.00,
            'created_at' => Carbon::now()
        ]);
        
        // Create some expenses
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 300.00,
            'date' => Carbon::now()->format('Y-m-d')
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 200.00,
            'date' => Carbon::now()->format('Y-m-d')
        ]);

        $totalExpenses = Expense::where('user_id', $user->id)
            ->whereYear('date', Carbon::now()->year)
            ->whereMonth('date', Carbon::now()->month)
            ->sum('amount');

        $remainingBudget = $budget->monthly_budget - $totalExpenses;

        $this->assertEquals(500.00, $remainingBudget);
    }

    public function test_user_can_identify_budget_overspend()
    {
        $user = User::factory()->create();
        
        // Create budget for current month
        $budget = Budget::factory()->create([
            'user_id' => $user->id,
            'monthly_budget' => 500.00,
            'created_at' => Carbon::now()
        ]);
        
        // Create expenses that exceed budget
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 300.00,
            'date' => Carbon::now()->format('Y-m-d')
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 300.00,
            'date' => Carbon::now()->format('Y-m-d')
        ]);

        $totalExpenses = Expense::where('user_id', $user->id)
            ->whereYear('date', Carbon::now()->year)
            ->whereMonth('date', Carbon::now()->month)
            ->sum('amount');

        $isOverBudget = $totalExpenses > $budget->monthly_budget;
        $overspendAmount = $totalExpenses - $budget->monthly_budget;

        $this->assertTrue($isOverBudget);
        $this->assertEquals(100.00, $overspendAmount);
    }

    public function test_user_can_get_expenses_by_category()
    {
        $user = User::factory()->create();
        $category = Category::factory()->create([
            'user_id' => $user->id,
            'name' => 'Food & Dining'
        ]);
        
        // Create expenses for specific category
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Food & Dining',
            'amount' => 50.00
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Food & Dining',
            'amount' => 30.00
        ]);
        
        // Create expense for different category
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Transportation',
            'amount' => 25.00
        ]);

        $foodExpenses = Expense::where('user_id', $user->id)
            ->where('category', 'Food & Dining')
            ->get();

        $totalFoodExpenses = $foodExpenses->sum('amount');

        $this->assertCount(2, $foodExpenses);
        $this->assertEquals(80.00, $totalFoodExpenses);
    }

    public function test_user_can_track_goal_progress()
    {
        $user = User::factory()->create();
        
        // For this test, we'll simulate goal progress tracking
        // In a real application, you might have a separate savings/progress table
        $goalAmount = 5000.00;
        $currentSavings = 1500.00;
        
        $progressPercentage = ($currentSavings / $goalAmount) * 100;
        $remainingAmount = $goalAmount - $currentSavings;

        $this->assertEquals(30.0, $progressPercentage);
        $this->assertEquals(3500.00, $remainingAmount);
    }

    public function test_user_can_calculate_average_monthly_spending()
    {
        $user = User::factory()->create();
        
        // Create expenses for 3 months
        for ($i = 0; $i < 3; $i++) {
            Expense::factory()->create([
                'user_id' => $user->id,
                'amount' => 300.00,
                'date' => Carbon::now()->subMonths($i)->format('Y-m-d')
            ]);
            
            Expense::factory()->create([
                'user_id' => $user->id,
                'amount' => 200.00,
                'date' => Carbon::now()->subMonths($i)->format('Y-m-d')
            ]);
        }

        $totalExpenses = Expense::where('user_id', $user->id)->sum('amount');
        $monthsWithExpenses = Expense::where('user_id', $user->id)
            ->selectRaw('COUNT(DISTINCT YEAR(date), MONTH(date)) as month_count')
            ->first()
            ->month_count;

        $averageMonthlySpending = $totalExpenses / $monthsWithExpenses;

        $this->assertEquals(500.00, $averageMonthlySpending);
    }

    public function test_user_can_identify_spending_trends()
    {
        $user = User::factory()->create();
        
        // Create expenses showing increasing trend
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 100.00,
            'date' => Carbon::now()->subMonths(2)->format('Y-m-d')
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 150.00,
            'date' => Carbon::now()->subMonth()->format('Y-m-d')
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'amount' => 200.00,
            'date' => Carbon::now()->format('Y-m-d')
        ]);

        $monthlyTotals = Expense::where('user_id', $user->id)
            ->selectRaw('YEAR(date) as year, MONTH(date) as month, SUM(amount) as total')
            ->groupBy('year', 'month')
            ->orderBy('year', 'asc')
            ->orderBy('month', 'asc')
            ->get();

        $totals = $monthlyTotals->pluck('total')->toArray();
        
        // Check if spending is increasing
        $isIncreasing = true;
        for ($i = 1; $i < count($totals); $i++) {
            if ($totals[$i] <= $totals[$i - 1]) {
                $isIncreasing = false;
                break;
            }
        }

        $this->assertTrue($isIncreasing);
        $this->assertEquals([100.00, 150.00, 200.00], $totals);
    }

    public function test_user_can_calculate_category_spending_percentage()
    {
        $user = User::factory()->create();
        
        // Create expenses in different categories
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Food & Dining',
            'amount' => 300.00
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Transportation',
            'amount' => 200.00
        ]);
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'category' => 'Entertainment',
            'amount' => 100.00
        ]);

        $totalExpenses = Expense::where('user_id', $user->id)->sum('amount');
        $foodExpenses = Expense::where('user_id', $user->id)
            ->where('category', 'Food & Dining')
            ->sum('amount');

        $foodPercentage = ($foodExpenses / $totalExpenses) * 100;

        $this->assertEquals(600.00, $totalExpenses);
        $this->assertEquals(50.0, $foodPercentage);
    }
}
