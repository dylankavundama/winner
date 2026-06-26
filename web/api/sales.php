<?php
header('Content-Type: application/json');
require_once '../config/db.php';

try {
    $stmt = $pdo->query('SELECT sales.id, clients.name AS client_name, users.username AS vendeur, sales.sale_date, sales.total, i.status
                         FROM sales
                         LEFT JOIN clients ON sales.client_id = clients.id
                         LEFT JOIN users ON sales.user_id = users.id
                         LEFT JOIN invoices i ON sales.id = i.sale_id
                         ORDER BY sales.sale_date DESC');
    $sales = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'sales' => $sales
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération des ventes',
        'details' => $e->getMessage()
    ]);
} 