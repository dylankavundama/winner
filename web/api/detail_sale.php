<?php
header('Content-Type: application/json');
require_once '../config/db.php';

if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    echo json_encode(['success' => false, 'message' => 'Paramètre id manquant ou invalide.']);
    exit;
}
$sale_id = intval($_GET['id']);

try {
    // Récupérer la vente et le client
    $stmt = $pdo->prepare('SELECT s.id, s.sale_date as date, s.total, c.name, c.phone, c.address
                          FROM sales s
                          LEFT JOIN clients c ON s.client_id = c.id
                          WHERE s.id = ?');
    $stmt->execute([$sale_id]);
    $sale = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$sale) {
        echo json_encode(['success' => false, 'message' => 'Vente non trouvée.']);
        exit;
    }
    // Récupérer les produits de la vente
    $stmt = $pdo->prepare('SELECT p.name, d.quantity, d.price
                          FROM sale_details d
                          INNER JOIN products p ON d.product_id = p.id
                          WHERE d.sale_id = ?');
    $stmt->execute([$sale_id]);
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
    // Structure la réponse
    echo json_encode([
        'success' => true,
        'sale' => [
            'id' => $sale['id'],
            'date' => $sale['date'],
            'total' => $sale['total'],
            'client' => [
                'name' => $sale['name'],
                'phone' => $sale['phone'],
                'address' => $sale['address'],
            ],
            'products' => $products
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération de la vente',
        'details' => $e->getMessage()
    ]);
} 