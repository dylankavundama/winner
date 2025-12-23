<?php
header('Content-Type: application/json');
require_once '../config/db.php';

try {
    // Récupérer les ventes par mois pour le graphique
    $chart_data = $pdo->query("
        SELECT 
            DATE_FORMAT(sale_date, '%b') as month, 
            SUM(total) as total 
        FROM sales 
        GROUP BY month 
        ORDER BY MIN(sale_date)
    ")->fetchAll(PDO::FETCH_ASSOC);
    
    $months = [];
    $totals = [];
    
    foreach ($chart_data as $row) {
        $months[] = $row['month'];
        $totals[] = (float)$row['total'];
    }
    
    echo json_encode([
        'success' => true,
        'months' => $months,
        'totals' => $totals
    ]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur serveur: ' . $e->getMessage()
    ]);
}
?>
