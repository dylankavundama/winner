<?php
session_start();
header('Content-Type: application/json');

if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['error' => 'Non autorisé']);
    exit;
}

require_once '../config/db.php';

try {
    $stmt = $pdo->query('SELECT * FROM clients');
    $clients = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($clients);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Erreur serveur', 'details' => $e->getMessage()]);
} 