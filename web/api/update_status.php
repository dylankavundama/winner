<?php
require_once '../config/db.php';
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(0);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée. Seul POST est accepté.']);
    exit;
}

// Get URL parameters
$record_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

// Get raw POST data
$input = json_decode(file_get_contents('php://input'), true);

if ($record_id <= 0 || !isset($input['paid_status'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Paramètres manquants ou invalides.']);
    exit;
}

$paid_status = (int)$input['paid_status'];

try {
    $sql = "UPDATE stock_out_records SET paid_status = :paid_status WHERE id = :id";
    $stmt = $pdo->prepare($sql);
    $stmt->bindParam(':paid_status', $paid_status, PDO::PARAM_INT);
    $stmt->bindParam(':id', $record_id, PDO::PARAM_INT);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => true, 'message' => 'Statut mis à jour avec succès.']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Aucun enregistrement mis à jour. L\'ID n\'existe peut-être pas.']);
    }

} catch (Exception $e) {
    error_log("Failed to update status: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour des données.']);
}
?>