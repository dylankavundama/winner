<?php
header('Content-Type: application/json');

require_once '../config/db.php';

// GET : historique complet de tous les dépôts (utilisés et non utilisés)
$clientId = isset($_GET['client_id']) ? (int)$_GET['client_id'] : null;
$productId = isset($_GET['product_id']) ? (int)$_GET['product_id'] : null;
$usedOnly = isset($_GET['used_only']) && $_GET['used_only'] === '1';

try {
    $whereConditions = [];
    $params = [];
    
    if ($clientId) {
        $whereConditions[] = 'd.client_id = :client_id';
        $params[':client_id'] = $clientId;
    }
    
    if ($productId) {
        $whereConditions[] = 'd.product_id = :product_id';
        $params[':product_id'] = $productId;
    }
    
    if ($usedOnly) {
        $whereConditions[] = 'd.sale_id IS NOT NULL';
    }
    
    $whereClause = !empty($whereConditions) ? 'WHERE ' . implode(' AND ', $whereConditions) : '';
    
    $stmt = $pdo->prepare(
        "SELECT d.*, c.name AS client_name, p.name AS product_name, s.id AS sale_id, s.sale_date
         FROM deposits d
         LEFT JOIN clients c ON d.client_id = c.id
         LEFT JOIN products p ON d.product_id = p.id
         LEFT JOIN sales s ON d.sale_id = s.id
         $whereClause
         ORDER BY d.deposit_date DESC, d.id DESC"
    );
    
    $stmt->execute($params);
    $deposits = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'deposits' => $deposits,
        'count' => count($deposits),
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération de l\'historique des dépôts.',
        'details' => $e->getMessage(),
    ]);
}

