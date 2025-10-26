<?php
/**
 * Hanthana Platform - RoadRunner Worker
 * Day 1: Foundation with Database Connectivity
 */

require __DIR__ . '/vendor/autoload.php';

use Spiral\RoadRunner;
use Nyholm\Psr7;

// Create RoadRunner worker
$worker = RoadRunner\Worker::create();
$psrFactory = new Psr7\Factory\Psr17Factory();

// Create PSR-7 worker
$psrWorker = new RoadRunner\Http\PSR7Worker($worker, $psrFactory, $psrFactory, $psrFactory);

// Database connection function
function getDatabaseConnection(): PDO {
    static $pdo = null;
    
    if ($pdo === null) {
        $dsn = sprintf(
            "pgsql:host=%s;port=%s;dbname=%s",
            getenv('DB_HOST') ?: 'postgres',
            getenv('DB_PORT') ?: '5432',
            getenv('DB_NAME') ?: 'hanthana'
        );
        
        try {
            $pdo = new PDO($dsn, getenv('DB_USER'), getenv('DB_PASSWORD'), [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        } catch (PDOException $e) {
            throw new RuntimeException("Database connection failed: " . $e->getMessage());
        }
    }
    
    return $pdo;
}

// Redis connection function
function getRedisConnection(): Redis {
    static $redis = null;
    
    if ($redis === null) {
        $redis = new Redis();
        try {
            $redis->connect(
                getenv('REDIS_HOST') ?: 'redis',
                (int) (getenv('REDIS_PORT') ?: 6379)
            );
            
            if ($password = getenv('REDIS_PASSWORD')) {
                $redis->auth($password);
            }
            
            $redis->ping();
        } catch (RedisException $e) {
            throw new RuntimeException("Redis connection failed: " . $e->getMessage());
        }
    }
    
    return $redis;
}

while (true) {
    try {
        $request = $psrWorker->waitRequest();
        
        if ($request === null) {
            // Termination request
            break;
        }
    } catch (\Throwable $e) {
        error_log("Worker error: " . $e->getMessage());
        continue;
    }

    try {
        // Get request details
        $method = $request->getMethod();
        $path = $request->getUri()->getPath();
        $queryParams = [];
        parse_str($request->getUri()->getQuery(), $queryParams);

        // Route the request
        $response = handleRequest($method, $path, $queryParams, $request);
        
        // Send response
        $psrWorker->respond($response);
        
    } catch (\Throwable $e) {
        error_log("Request handling error: " . $e->getMessage());
        
        $response = new Psr7\Response(500, ['Content-Type' => 'application/json']);
        $response->getBody()->write(json_encode([
            'error' => 'Internal Server Error',
            'message' => 'Something went wrong',
            'timestamp' => date('c')
        ]));
        $psrWorker->respond($response);
    }
}

/**
 * Handle incoming requests with enhanced routing
 */
function handleRequest(string $method, string $path, array $query, $request) {
    $response = new Psr7\Response();
    $response = $response->withHeader('Content-Type', 'application/json');
    
    // Health check endpoint
    if ($path === '/health' || $path === '/api/health') {
        $healthData = checkSystemHealth();
        $statusCode = $healthData['status'] === 'healthy' ? 200 : 503;
        
        $response = $response->withStatus($statusCode);
        $response->getBody()->write(json_encode($healthData, JSON_PRETTY_PRINT));
        return $response;
    }
    
    // System info endpoint
    if ($path === '/api/system') {
        $systemInfo = getSystemInfo();
        $response->getBody()->write(json_encode($systemInfo, JSON_PRETTY_PRINT));
        return $response;
    }
    
    // Database test endpoint
    if ($path === '/api/db-test') {
        $dbInfo = testDatabaseConnection();
        $response->getBody()->write(json_encode($dbInfo, JSON_PRETTY_PRINT));
        return $response;
    }
    
    // Redis test endpoint
    if ($path === '/api/redis-test') {
        $redisInfo = testRedisConnection();
        $response->getBody()->write(json_encode($redisInfo, JSON_PRETTY_PRINT));
        return $response;
    }
    
    // Test endpoint
    if ($path === '/api/test') {
        $response->getBody()->write(json_encode([
            'message' => '🚀 Welcome to Hanthana Platform API!',
            'framework' => 'Spiral RoadRunner',
            'database' => 'PostgreSQL 15',
            'cache' => 'Redis 7',
            'php_version' => PHP_VERSION,
            'jit_enabled' => (bool) ini_get('opcache.jit'),
            'timestamp' => date('c'),
            'endpoints' => [
                'GET /health' => 'System health check',
                'GET /api/system' => 'System information',
                'GET /api/db-test' => 'Database connection test',
                'GET /api/redis-test' => 'Redis connection test'
            ]
        ], JSON_PRETTY_PRINT));
        return $response;
    }
    
    // API root
    if ($path === '/api') {
        $response->getBody()->write(json_encode([
            'name' => 'Hanthana Platform API',
            'version' => '1.0.0',
            'description' => 'University Academic Collaboration Platform',
            'timestamp' => date('c'),
            'documentation' => 'https://github.com/your-username/hanthana-platform'
        ], JSON_PRETTY_PRINT));
        return $response;
    }
    
    // Not found
    $response = $response->withStatus(404);
    $response->getBody()->write(json_encode([
        'error' => 'Endpoint not found',
        'path' => $path,
        'method' => $method,
        'available_endpoints' => [
            '/health', '/api', '/api/system', '/api/test', 
            '/api/db-test', '/api/redis-test'
        ],
        'timestamp' => date('c')
    ], JSON_PRETTY_PRINT));
    return $response;
}

/**
 * Check system health status
 */
function checkSystemHealth(): array {
    $checks = [
        'database' => false,
        'redis' => false,
        'php' => true,
        'opcache' => (bool) ini_get('opcache.enable'),
        'jit' => (bool) ini_get('opcache.jit')
    ];
    
    try {
        $pdo = getDatabaseConnection();
        $pdo->query('SELECT 1')->fetch();
        $checks['database'] = true;
    } catch (Exception $e) {
        error_log("Database health check failed: " . $e->getMessage());
    }
    
    try {
        $redis = getRedisConnection();
        $redis->ping();
        $checks['redis'] = true;
    } catch (Exception $e) {
        error_log("Redis health check failed: " . $e->getMessage());
    }
    
    $allHealthy = !in_array(false, $checks, true);
    
    return [
        'status' => $allHealthy ? 'healthy' : 'degraded',
        'service' => 'Hanthana Platform API',
        'timestamp' => date('c'),
        'checks' => $checks,
        'version' => '1.0.0'
    ];
}

/**
 * Get system information
 */
function getSystemInfo(): array {
    return [
        'php' => [
            'version' => PHP_VERSION,
            'sapi' => PHP_SAPI,
            'extensions' => get_loaded_extensions(),
            'ini' => [
                'memory_limit' => ini_get('memory_limit'),
                'max_execution_time' => ini_get('max_execution_time'),
                'opcache_enabled' => (bool) ini_get('opcache.enable'),
                'jit_enabled' => (bool) ini_get('opcache.jit'),
                'jit_buffer_size' => ini_get('opcache.jit_buffer_size')
            ]
        ],
        'environment' => [
            'db_host' => getenv('DB_HOST'),
            'db_name' => getenv('DB_NAME'),
            'redis_host' => getenv('REDIS_HOST'),
            'app_env' => getenv('APP_ENV')
        ],
        'server' => [
            'software' => $_SERVER['SERVER_SOFTWARE'] ?? 'RoadRunner',
            'timestamp' => date('c'),
            'timezone' => date_default_timezone_get()
        ]
    ];
}

/**
 * Test database connection and get info
 */
function testDatabaseConnection(): array {
    try {
        $pdo = getDatabaseConnection();
        
        // Get PostgreSQL version
        $version = $pdo->query('SELECT version()')->fetchColumn();
        
        // Get database size
        $size = $pdo->query("
            SELECT pg_size_pretty(pg_database_size('hanthana')) as db_size
        ")->fetchColumn();
        
        // Get table count
        $tableCount = $pdo->query("
            SELECT COUNT(*) FROM information_schema.tables 
            WHERE table_schema = 'public'
        ")->fetchColumn();
        
        return [
            'status' => 'connected',
            'database' => 'PostgreSQL',
            'version' => $version,
            'size' => $size,
            'tables' => (int) $tableCount,
            'connection' => [
                'host' => getenv('DB_HOST'),
                'database' => getenv('DB_NAME'),
                'user' => getenv('DB_USER')
            ]
        ];
    } catch (Exception $e) {
        return [
            'status' => 'disconnected',
            'error' => $e->getMessage(),
            'connection' => [
                'host' => getenv('DB_HOST'),
                'database' => getenv('DB_NAME'),
                'user' => getenv('DB_USER')
            ]
        ];
    }
}

/**
 * Test Redis connection and get info
 */
function testRedisConnection(): array {
    try {
        $redis = getRedisConnection();
        
        $info = $redis->info('SERVER');
        $memory = $redis->info('MEMORY');
        
        // Test set/get
        $testKey = 'hanthana:test:' . time();
        $testValue = 'Hello from Hanthana Platform!';
        $redis->setex($testKey, 60, $testValue);
        $retrievedValue = $redis->get($testKey);
        $redis->del($testKey);
        
        return [
            'status' => 'connected',
            'database' => 'Redis',
            'version' => $info['redis_version'] ?? 'unknown',
            'used_memory' => $memory['used_memory_human'] ?? 'unknown',
            'test' => [
                'set_get' => $retrievedValue === $testValue ? 'success' : 'failed',
                'value' => $retrievedValue
            ],
            'connection' => [
                'host' => getenv('REDIS_HOST'),
                'port' => getenv('REDIS_PORT')
            ]
        ];
    } catch (Exception $e) {
        return [
            'status' => 'disconnected',
            'error' => $e->getMessage(),
            'connection' => [
                'host' => getenv('REDIS_HOST'),
                'port' => getenv('REDIS_PORT')
            ]
        ];
    }
}