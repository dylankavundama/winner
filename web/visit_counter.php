<?php
header('Content-Type: application/json');

// Path to existing db config
$dbConfigPath = '../web/config/db.php';

if (file_exists($dbConfigPath)) {
    require_once $dbConfigPath;
} else {
    // Fallback if path is different (e.g. testing context)
    $host = 'localhost';
    $db   = 'winnerco_db';
    $user = 'winnerco_admin';
    $pass = 'VY@LS?Z)_,V5';
    $charset = 'utf8mb4';
    $dsn = "mysql:host=$host;dbname=$db;charset=$charset";
    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];
    try {
        $pdo = new PDO($dsn, $user, $pass, $options);
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
        exit;
    }
}

try {
    // 1. Create table if not exists
    $sqlCreateTable = "CREATE TABLE IF NOT EXISTS visitor_stats (
        id INT AUTO_INCREMENT PRIMARY KEY,
        page_name VARCHAR(50) UNIQUE,
        visit_count INT DEFAULT 0
    )";
    $pdo->exec($sqlCreateTable);

    // 2. Increment counter
    $pageName = 'promo_page';
    $sqlIncrement = "INSERT INTO visitor_stats (page_name, visit_count) VALUES (:page, 1)
                     ON DUPLICATE KEY UPDATE visit_count = visit_count + 1";
    $stmt = $pdo->prepare($sqlIncrement);
    $stmt->execute(['page' => $pageName]);

    // 3. Get current count
    $sqlGetCount = "SELECT visit_count FROM visitor_stats WHERE page_name = :page";
    $stmt = $pdo->prepare($sqlGetCount);
    $stmt->execute(['page' => $pageName]);
    $result = $stmt->fetch();

    echo json_encode(['count' => $result['visit_count']]);

} catch (PDOException $e) {
    echo json_encode(['error' => 'Query failed: ' . $e->getMessage()]);
}
