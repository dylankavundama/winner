<?php
// api_dashboard_stats.php
session_start();
if (!isset($_SESSION['user_id'])) {
    http_response_code(401); // Unauthorized
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

require_once '../config/db.php'; // Your database connection

header('Content-Type: application/json'); // Tell the client it's JSON

try {
    $total_clients = $pdo->query('SELECT COUNT(*) FROM clients')->fetchColumn();
    $total_products = $pdo->query('SELECT COUNT(*) FROM products')->fetchColumn();
    $total_sales = $pdo->query('SELECT COUNT(*) FROM sales')->fetchColumn();
    $total_invoices = $pdo->query('SELECT COUNT(*) FROM invoices')->fetchColumn();
    $total_sales_amount = $pdo->query('SELECT IFNULL(SUM(total),0) FROM sales')->fetchColumn();
    // Corrected "Chiffre d'affaire" if 'total' in sales is the revenue per sale
    $total_chiffre_affaire = $pdo->query('SELECT IFNULL(SUM(total),0) FROM sales')->fetchColumn(); // Assuming total_sales_amount IS chiffre d'affaire

    echo json_encode([
        'total_clients' => (int)$total_clients,
        'total_products' => (int)$total_products,
        'total_sales' => (int)$total_sales,
        'total_invoices' => (int)$total_invoices,
        'total_sales_amount' => (double)$total_sales_amount,
        'total_chiffre_affaire' => (double)$total_chiffre_affaire,
        // You could also add the username here
        'username' => isset($_SESSION['username']) ? $_SESSION['username'] : 'Guest'
    ]);

} catch (PDOException $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>