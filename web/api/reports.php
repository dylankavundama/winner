<?php
header('Content-Type: application/json');
require_once '../config/db.php';

$start = $_GET['start'] ?? date('Y-m-01');
$end = $_GET['end'] ?? date('Y-m-d');

try {
    // Rapport des ventes PAYÉES par période
    $stmt = $pdo->prepare('SELECT s.id, c.name AS client, s.sale_date, s.total FROM sales s INNER JOIN clients c ON s.client_id = c.id INNER JOIN invoices i ON s.id = i.sale_id WHERE i.status = "payée" AND s.sale_date BETWEEN ? AND ? ORDER BY s.sale_date DESC');
    $stmt->execute([$start . ' 00:00:00', $end . ' 23:59:59']);
    $sales = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Rapport du stock faible
    $low_stock = $pdo->query('SELECT id, name, quantity, price FROM products WHERE quantity <= 5 ORDER BY quantity ASC')->fetchAll(PDO::FETCH_ASSOC);

    // Rapport des meilleurs clients (basé sur factures PAYÉES)
    $top_clients = $pdo->query('SELECT c.name, SUM(s.total) as total_achats FROM sales s INNER JOIN clients c ON s.client_id = c.id INNER JOIN invoices i ON s.id = i.sale_id WHERE i.status = "payée" GROUP BY c.id ORDER BY total_achats DESC LIMIT 5')->fetchAll(PDO::FETCH_ASSOC);

    // Rapport des factures impayées (Tout ce qui n'est pas payé)
    $unpaid = $pdo->query("SELECT i.id, c.name AS client, i.amount, i.invoice_date FROM invoices i INNER JOIN sales s ON i.sale_id = s.id INNER JOIN clients c ON s.client_id = c.id WHERE i.status != 'payée' ORDER BY i.invoice_date DESC")->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'sales' => $sales,
        'low_stock' => $low_stock,
        'top_clients' => $top_clients,
        'unpaid' => $unpaid
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la génération des rapports',
        'details' => $e->getMessage()
    ]);
} 