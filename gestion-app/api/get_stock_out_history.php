<?php
// Set to 0 for production
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(0);

// Set headers for JSON response and CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // IMPORTANT: Change '*' to your specific domain(s) in production
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// --- Database Connection Details (REPLACE WITH YOUR OWN) ---
define('DB_HOST', 'localhost');
define('DB_NAME', 'gestion_app');
define('DB_USER', 'root');
define('DB_PASSWORD', '');
// --- End Database Connection Details ---

function getDbConnection() {
    try {
        $conn = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASSWORD
        );
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $conn;
    } catch (PDOException $e) {
        error_log("Database connection error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur de connexion à la base de données.']);
        exit;
    }
}

// Check if the request method is GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée. Seul GET est accepté.']);
    exit;
}

try {
    $conn = getDbConnection();

    // Query to retrieve stock out records with product and client names
    $sql = "
        SELECT 
            sor.id,
            sor.quantity,
            sor.reason,
            sor.out_date,
            p.name AS product_name,
            c.name AS client_name
        FROM stock_out_records AS sor
        JOIN products AS p ON sor.product_id = p.id
        LEFT JOIN clients AS c ON sor.client_id = c.id
        ORDER BY sor.out_date DESC
    ";

    $stmt = $conn->prepare($sql);
    $stmt->execute();
    $records = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(['success' => true, 'records' => $records]);

} catch (Exception $e) {
    error_log("Failed to fetch stock out records: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la récupération des données.']);
    exit;
}
?>
