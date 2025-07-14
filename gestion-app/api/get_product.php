<?php
header('Content-Type: application/json');
require_once '../config/db.php';
if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Product ID is required and must be a number.']);
    exit;
}
$product_id = intval($_GET['id']);
try {
    $stmt = $pdo->prepare('SELECT id, name, description, price AS prix_achat, prix_vente, quantity FROM products WHERE id = ?');
    $stmt->execute([$product_id]);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($product) {
        http_response_code(200);
        echo json_encode(['success' => true, 'product' => $product]);
    } else {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Product not found.']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}
exit;
?>