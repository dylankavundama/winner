<?php
header('Content-Type: application/json');
require_once '../config/db.php';

// Lire le corps de la requête
$input = json_decode(file_get_contents('php://input'), true);
if (!isset($input['sale_id']) || !is_numeric($input['sale_id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Paramètre sale_id manquant ou invalide.']);
    exit;
}
$sale_id = intval($input['sale_id']);

try {
    // Vérifier que la vente existe
    $stmt = $pdo->prepare('SELECT id FROM sales WHERE id = ?');
    $stmt->execute([$sale_id]);
    if (!$stmt->fetch()) {
        echo json_encode(['success' => false, 'message' => 'Vente non trouvée.']);
        exit;
    }
    // Insérer la facture
    $stmt = $pdo->prepare('INSERT INTO invoices (sale_id, status) VALUES (?, "non payée")');
    $stmt->execute([$sale_id]);
    $invoice_id = $pdo->lastInsertId();
    echo json_encode(['success' => true, 'invoice_id' => (int)$invoice_id]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la génération de la facture',
        'details' => $e->getMessage()
    ]);
} 