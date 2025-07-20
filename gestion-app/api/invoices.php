<?php
header('Content-Type: application/json');
require_once '../config/db.php';

try {
    $stmt = $pdo->query('SELECT i.id, s.sale_date, s.total, i.status, c.name AS client_name
                         FROM invoices i
                         INNER JOIN sales s ON i.sale_id = s.id
                         INNER JOIN clients c ON s.client_id = c.id
                         ORDER BY i.id DESC');
    $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'invoices' => $invoices
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération des factures',
        'details' => $e->getMessage()
    ]);
} 