<?php
// api_dashboard_stats.php
if (!is_dir(ini_get('session.save_path')) || !is_writable(ini_get('session.save_path'))) {
    session_save_path(sys_get_temp_dir());
}
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
    // Chiffre d'affaire : somme de TOUTES les ventes
    $total_chiffre_affaire = $pdo->query('SELECT IFNULL(SUM(total),0) FROM sales')->fetchColumn();
    
    // Argent collecté (Caisse) : somme des ventes PAYÉES uniquement
    $total_sales_amount = $pdo->query('SELECT IFNULL(SUM(s.total),0) FROM sales s JOIN invoices i ON s.id = i.sale_id WHERE i.status = "payée"')->fetchColumn();
    
    $total_deposits = $pdo->query('
        SELECT IFNULL(SUM(d.amount),0) 
        FROM deposits d 
        LEFT JOIN invoices i ON d.sale_id = i.sale_id 
        WHERE d.sale_id IS NULL OR i.status != "payée"
    ')->fetchColumn();
    $total_sorties = $pdo->query('SELECT IFNULL(SUM(montant),0) FROM sorties')->fetchColumn();
    
    // Calcul du total de la caisse : (Ventes payées + Dépôts non utilisés) - Sorties
    $total_caisse = ($total_sales_amount + $total_deposits) - $total_sorties;
    
    // Total des dettes (Tout ce qui n'est pas payé)
    $total_dette = $pdo->query('SELECT IFNULL(SUM(amount), 0) FROM invoices WHERE status != "payée"')->fetchColumn();

    echo json_encode([
        'total_clients' => (int)$total_clients,
        'total_products' => (int)$total_products,
        'total_sales' => (int)$total_sales,
        'total_invoices' => (int)$total_invoices,
        'total_sales_amount' => (double)$total_sales_amount,
        'total_chiffre_affaire' => (double)$total_chiffre_affaire,
        'total_deposits' => (double)$total_deposits,
        'total_sorties' => (double)$total_sorties,
        'total_caisse' => (double)$total_caisse,
        'total_dette' => (double)$total_dette,
        // You could also add the username here
        'username' => isset($_SESSION['username']) ? $_SESSION['username'] : 'Guest'
    ]);

} catch (PDOException $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}
?>