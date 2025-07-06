<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Non autorisé']);
    exit;
}

require_once '../config/db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $invoice_id = $_POST['invoice_id'] ?? null;
    $new_status = $_POST['status'] ?? null;
    
    // Validation des données
    if (!$invoice_id || !$new_status) {
        echo json_encode(['success' => false, 'message' => 'Données manquantes']);
        exit;
    }
    
    // Validation du statut
    $allowed_statuses = ['payée', 'impayée'];
    if (!in_array($new_status, $allowed_statuses)) {
        echo json_encode(['success' => false, 'message' => 'Statut invalide']);
        exit;
    }
    
    try {
        // Mise à jour du statut
        $stmt = $pdo->prepare('UPDATE invoices SET status = ? WHERE id = ?');
        $result = $stmt->execute([$new_status, $invoice_id]);
        
        if ($result) {
            echo json_encode(['success' => true, 'message' => 'Statut mis à jour avec succès']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour']);
        }
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Erreur de base de données']);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
}
?> 