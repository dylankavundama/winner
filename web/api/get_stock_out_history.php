<?php
// Use the external database connection file
require_once '../config/db.php';

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

// Check if the request method is GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée. Seul GET est accepté.']);
    exit;
}

try {
    // The $pdo object is now available from require_once '../config/db.php';
    // No need for a separate getDbConnection() function or hardcoded credentials.
    
    // Query to retrieve stock out records with product and client names
    $sql = "
        SELECT 
            sor.id,
            sor.quantity,
            sor.reason,
            sor.out_date,
            sor.paid_status, -- Nouvelle colonne ajoutée ici
            p.name AS product_name,
            c.name AS client_name
        FROM stock_out_records AS sor
        JOIN products AS p ON sor.product_id = p.id
        LEFT JOIN clients AS c ON sor.client_id = c.id
        ORDER BY sor.out_date DESC
    ";

    $stmt = $pdo->prepare($sql);
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