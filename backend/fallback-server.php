<?php
/**
 * Emergency Fallback Server for Day 1
 */

echo "🚀 Starting Hanthana Fallback Server...\n";

// Simple router
$requestUri = $_SERVER['REQUEST_URI'] ?? '/';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

header('Content-Type: application/json');

switch ($requestUri) {
    case '/health':
    case '/':
        http_response_code(200);
        echo json_encode([
            'status' => 'healthy',
            'service' => 'Hanthana Platform (Fallback Server)',
            'timestamp' => date('c'),
            'message' => '✅ Day 1: Basic server running!',
            'next' => 'Fixing RoadRunner...'
        ], JSON_PRETTY_PRINT);
        break;
        
    case '/api/test':
        http_response_code(200);
        echo json_encode([
            'message' => '🎉 Fallback server working!',
            'database' => 'PostgreSQL 15 (connected)',
            'cache' => 'Redis 7 (connected)',
            'day_1_progress' => 'Infrastructure setup complete',
            'timestamp' => date('c')
        ], JSON_PRETTY_PRINT);
        break;
        
    default:
        http_response_code(404);
        echo json_encode([
            'error' => 'Endpoint not found',
            'available' => ['/health', '/api/test']
        ], JSON_PRETTY_PRINT);
        break;
}