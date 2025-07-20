<?php
header('Content-Type: application/json');
require_once '../config/db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $user_id = $input['user_id'] ?? null;
    $montant = $input['montant'] ?? null;
    $motif = $input['motif'] ?? null;
    $type = $input['type'] ?? 'normal';
    if ($user_id && $montant !== null && $motif) {
        $stmt = $pdo->prepare('INSERT INTO sorties (user_id, montant, motif, type) VALUES (?, ?, ?, ?)');
        if ($stmt->execute([$user_id, $montant, $motif, $type])) {
            echo json_encode(['success' => true, 'message' => 'Sortie enregistrée avec succès!']);
        } else {
            echo json_encode(['success' => false, 'message' => "Erreur lors de l'enregistrement."]);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'Veuillez remplir tous les champs.']);
    }
    exit;
}

// GET : liste filtrable
$type_filter = $_GET['type'] ?? '';
$date_filter = $_GET['date'] ?? '';
$month_filter = $_GET['month'] ?? '';
$year_filter = $_GET['year'] ?? '';
$sql = 'SELECT s.*, u.username FROM sorties s JOIN users u ON s.user_id = u.id';
$where = [];
$params = [];
if ($type_filter && in_array($type_filter, ['normal','transaction'])) {
    $where[] = 's.type = ?';
    $params[] = $type_filter;
}
if ($date_filter) {
    $where[] = 'DATE(s.date_sortie) = ?';
    $params[] = $date_filter;
}
if ($month_filter) {
    $where[] = 'DATE_FORMAT(s.date_sortie, "%Y-%m") = ?';
    $params[] = $month_filter;
}
if ($year_filter) {
    $where[] = 'YEAR(s.date_sortie) = ?';
    $params[] = $year_filter;
}
if ($where) {
    $sql .= ' WHERE ' . implode(' AND ', $where);
}
$sql .= ' ORDER BY s.date_sortie DESC';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$sorties = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode(['success' => true, 'sorties' => $sorties]); 