<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChatbotController extends Controller
{
    public function chat(Request $request)
    {
        $userMessage = $request->input('message');
        $apiKey = env('OPENROUTER_API_KEY');

        $response = Http::post('http://127.0.0.1:5000/chat', [
            'message' => $userMessage,
            'api_key' => $apiKey
        ]);

        if ($response->failed()) {
            Log::error('Flask Chatbot API Error: ' . $response->body());
            return response()->json(['error' => 'Failed to fetch response'], 500);
        }

        $responseData = $response->json();

        $assistantMessage = $responseData['choices'][0]['message']['content'] ?? 'No response received.';

        return response()->json([
            'message' => $assistantMessage
        ]);
    }
}
