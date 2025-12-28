<?php
header('Content-Type: application/json');
require_once '../config/db.php';

$date_filter = $_GET['date'] ?? '';
$month_filter = $_GET['month'] ?? '';
$year_filter = $_GET['year'] ?? '';

$where = [];
$params = [];
if ($date_filter) {
    $where[] = 'DATE(s.sale_date) = ?';
    $params[] = $date_filter;
}
if ($month_filter) {
    $where[] = 'DATE_FORMAT(s.sale_date, "%Y-%m") = ?';
    $params[] = $month_filter;
}
if ($year_filter) {
    $where[] = 'YEAR(s.sale_date) = ?';
    $params[] = $year_filter;
}
$where_sql = $where ? ('WHERE ' . implode(' AND ', $where)) : '';

// Récupérer les ventes avec bénéfice calculé par vente
$sql = 'SELECT 
            s.id as sale_id,
            s.sale_date,
            s.total as sale_total,
            c.name as client_name,
            SUM((d.price - p.price) * d.quantity) as benefice_vente,
            SUM(d.price * d.quantity) as chiffre_affaire_vente
        FROM sales s
        LEFT JOIN clients c ON s.client_id = c.id
        JOIN sale_details d ON s.id = d.sale_id
        JOIN products p ON d.product_id = p.id
        ' . $where_sql . '
        GROUP BY s.id, s.sale_date, s.total, c.name
        ORDER BY s.sale_date DESC, s.id DESC';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$ventes_detail = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Calcul bénéfice total
$benefice_brut = 0;
$total_ventes = 0;
foreach ($ventes_detail as $v) {
    $benefice_brut += (float)$v['benefice_vente'];
    $total_ventes += (float)$v['sale_total'];
}

// Récupérer les sorties de type 'normal' sur la même période
$depenses = 0;
$sortie_where = [];
$sortie_params = [];
if ($date_filter) {
    $sortie_where[] = 'DATE(date_sortie) = ?';
    $sortie_params[] = $date_filter;
}
if ($month_filter) {
    $sortie_where[] = 'DATE_FORMAT(date_sortie, "%Y-%m") = ?';
    $sortie_params[] = $month_filter;
}
if ($year_filter) {
    $sortie_where[] = 'YEAR(date_sortie) = ?';
    $sortie_params[] = $year_filter;
}
$sortie_where[] = 'type = ?';
$sortie_params[] = 'normal';
$sortie_sql = 'SELECT SUM(montant) as total FROM sorties ' . ($sortie_where ? ('WHERE ' . implode(' AND ', $sortie_where)) : '');
$stmt_sortie = $pdo->prepare($sortie_sql);
$stmt_sortie->execute($sortie_params);
$depenses = $stmt_sortie->fetchColumn() ?: 0;

$benefice_exact = $benefice_brut - $depenses;

echo json_encode([
    'success' => true,
    'benefice_brut' => round($benefice_brut, 2),
    'depenses' => round($depenses, 2),
    'benefice_exact' => round($benefice_exact, 2),
    'total_ventes' => round($total_ventes, 2),
    'ventes' => $ventes_detail
]);

