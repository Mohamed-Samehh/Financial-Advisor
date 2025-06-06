<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Laravel\Telescope\Telescope;
use Laravel\Telescope\TelescopeApplicationServiceProvider;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        if ($this->app->environment('local')) {
            $this->app->register(TelescopeApplicationServiceProvider::class);
        }
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Telescope::filter(function ($entry) {
            return app()->environment('local') || Auth::check();
        });

        // Set the default timezone globally
        Carbon::setLocale('en');
        date_default_timezone_set('Africa/Cairo');

        // Change date for testing
        // if ($this->app->environment('local', 'testing')) {
        //     Carbon::setTestNow(Carbon::now()->subMonth(4));
        //     // subMonth() to test old data
        //     // addMonth() to test future data
        // }
    }
}
