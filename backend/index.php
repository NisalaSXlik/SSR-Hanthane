<?php
header('Content-Type: application/json');

echo json_encode([
    'status' => 'success',
    'message' => '🎉 Day 1: Hanthana Platform is RUNNING!',
    'day' => 1,
    'progress' => 'Docker environment ready',
    'timestamp' => date('c'),
    'endpoints' => [
        '/health' => 'Health check',
        '/api/test' => 'Test endpoint'
    ]
]);