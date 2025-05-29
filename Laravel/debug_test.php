<?php

require_once 'vendor/autoload.php';

use App\Http\Controllers\StocksController;
use Illuminate\Support\Facades\Http;

// Set up environment
putenv('EODHD_API_KEY=test_api_key');

// Create controller
$controller = new StocksController();

// Test basic HTTP fake
Http::fake([
    'https://eodhd.com/api/exchange-symbol-list/EGX*' => function () {
        throw new \Exception('Network error');
    }
]);

try {
    $response = $controller->getEgyptStocks();
    echo "Response status: " . $response->getStatusCode() . "\n";
    echo "Response content: " . $response->getContent() . "\n";
} catch (\Exception $e) {
    echo "Exception: " . $e->getMessage() . "\n";
}
