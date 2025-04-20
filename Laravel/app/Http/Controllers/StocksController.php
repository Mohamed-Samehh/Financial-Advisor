<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class StocksController extends Controller
{
    protected $apiUrl;
    protected $apiKey;

    public function __construct()
    {
        $this->apiUrl = 'https://eodhd.com/api';
        $this->apiKey = env('EODHD_API_KEY');
    }

    protected function makeApiRequest($endpoint, $params = [])
    {
        $params = array_merge([
            'api_token' => $this->apiKey,
            'fmt' => 'json'
        ], $params);

        try {
            $response = Http::withOptions([
                'verify' => false, // Disable SSL verification
            ])->get("{$this->apiUrl}/{$endpoint}", $params);
            
            return $response->json();
        } catch (\Exception $e) {
            throw new \Exception('API request failed: ' . $e->getMessage());
        }
    }

    public function getEgyptStocks()
    {
        try {
            $data = $this->makeApiRequest('exchange-symbol-list/EGX');
            return response()->json($data);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function getStockDetails($symbol)
    {
        try {
            $data = $this->makeApiRequest("eod/{$symbol}.EGX", ['period' => 'm']);
            return response()->json($data);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
