<?php
/**
 * Minimal Hanthana Worker - Day 1
 */

// Simple check for autoload
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require __DIR__ . '/vendor/autoload.php';
    echo "✅ Autoloader loaded successfully\n";
} else {
    echo "❌ Autoloader not found\n";
    exit(1);
}

use Spiral\RoadRunner;
use Nyholm\Psr7;

echo "🚀 Starting Hanthana Worker...\n";

try {
    // Create RoadRunner worker
    $worker = RoadRunner\Worker::create();
    $psrFactory = new Psr7\Factory\Psr17Factory();

    // Create PSR-7 worker
    $psrWorker = new RoadRunner\Http\PSR7Worker($worker, $psrFactory, $psrFactory, $psrFactory);
    
    echo "✅ RoadRunner workers created successfully\n";
    echo "📡 Listening on http://0.0.0.0:8080\n";

    while (true) {
        try {
            $request = $psrWorker->waitRequest();
            
            if ($request === null) {
                echo "🛑 Termination request received\n";
                break;
            }
        } catch (\Throwable $e) {
            error_log("Wait request error: " . $e->getMessage());
            continue;
        }

        try {
            $method = $request->getMethod();
            $path = $request->getUri()->getPath();

            $response = new Psr7\Response();
            $response = $response->withHeader('Content-Type', 'application/json');

            // Health endpoint
            if ($path === '/health' || $path === '/') {
                $response->getBody()->write(json_encode([
                    'status' => 'healthy',
                    'service' => 'Hanthana Platform API',
                    'timestamp' => date('c'),
                    'day' => 1,
                    'message' => '🎉 Docker Environment & Database Setup Complete!',
                    'database' => 'PostgreSQL 15',
                    'cache' => 'Redis 7',
                    'php' => PHP_VERSION,
                    'jit' => ini_get('opcache.jit')
                ], JSON_PRETTY_PRINT));
                $psrWorker->respond($response);
                continue;
            }

            // Test endpoint
            if ($path === '/api/test') {
                $response->getBody()->write(json_encode([
                    'message' => '🚀 Hanthana Platform is successfully running!',
                    'progress' => [
                        'day_1' => 'Docker Environment ✓',
                        'day_1' => 'Database Schema ✓', 
                        'day_1' => 'RoadRunner Setup ✓',
                        'next' => 'Authentication System'
                    ],
                    'endpoints' => [
                        'GET /health' => 'System health check',
                        'GET /api/test' => 'Test endpoint',
                        'GET /api/db-status' => 'Database status',
                        'GET /api/system' => 'System information'
                    ],
                    'timestamp' => date('c')
                ], JSON_PRETTY_PRINT));
                $psrWorker->respond($response);
                continue;
            }

            // Database status endpoint
            if ($path === '/api/db-status') {
                $dbStatus = checkDatabaseConnection();
                $response->getBody()->write(json_encode($dbStatus, JSON_PRETTY_PRINT));
                $psrWorker->respond($response);
                continue;
            }

            // System info endpoint
            if ($path === '/api/system') {
                $systemInfo = [
                    'php' => [
                        'version' => PHP_VERSION,
                        'extensions' => get_loaded_extensions(),
                        'jit_enabled' => ini_get('opcache.jit'),
                        'memory_limit' => ini_get('memory_limit')
                    ],
                    'environment' => [
                        'db_host' => getenv('DB_HOST'),
                        'redis_host' => getenv('REDIS_HOST')
                    ],
                    'roadrunner' => true,
                    'timestamp' => date('c')
                ];
                $response->getBody()->write(json_encode($systemInfo, JSON_PRETTY_PRINT));
                $psrWorker->respond($response);
                continue;
            }

            // Not found
            $response = $response->withStatus(404);
            $response->getBody()->write(json_encode([
                'error' => 'Endpoint not found',
                'path' => $path,
                'available_endpoints' => [
                    '/health', '/api/test', '/api/db-status', '/api/system'
                ]
            ], JSON_PRETTY_PRINT));
            $psrWorker->respond($response);
            
        } catch (\Throwable $e) {
            error_log("Request error: " . $e->getMessage());
            
            $response = new Psr7\Response(500, ['Content-Type' => 'application/json']);
            $response->getBody()->write(json_encode([
                'error' => 'Internal Server Error',
                'message' => $e->getMessage()
            ], JSON_PRETTY_PRINT));
            $psrWorker->respond($response);
        }
    }
} catch (\Throwable $e) {
    echo "❌ Fatal error: " . $e->getMessage() . "\n";
    exit(1);
}

/**
 * Check database connection
 */
function checkDatabaseConnection(): array {
    try {
        $dsn = sprintf(
            "pgsql:host=%s;port=%s;dbname=%s",
            getenv('DB_HOST') ?: 'postgres',
            getenv('DB_PORT') ?: '5432',
            getenv('DB_NAME') ?: 'hanthana'
        );
        
        $pdo = new PDO($dsn, getenv('DB_USER'), getenv('DB_PASSWORD'), [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
        
        // Get table count
        $stmt = $pdo->query("
            SELECT COUNT(*) as table_count 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        ");
        $tableCount = $stmt->fetchColumn();
        
        // Get PostgreSQL version
        $version = $pdo->query('SELECT version()')->fetchColumn();
        
        return [
            'status' => 'connected',
            'database' => 'PostgreSQL',
            'tables' => (int) $tableCount,
            'version' => $version,
            'timestamp' => date('c')
        ];
    } catch (PDOException $e) {
        return [
            'status' => 'disconnected',
            'error' => $e->getMessage(),
            'timestamp' => date('c')
        ];
    }
}