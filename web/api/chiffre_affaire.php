<?php
header('Content-Type: application/json');
require_once '../config/db.php';

// Récupérer les paramètres de filtrage
$start_date = $_GET['start_date'] ?? null;
$end_date = $_GET['end_date'] ?? null;
$group_by = $_GET['group_by'] ?? 'all'; // 'all', 'day', 'month', 'year', 'product'

try {
    // Calcul du chiffre d'affaire total (basé sur les détails de vente : prix × quantité)
    $total_ca_query = "
        SELECT IFNULL(SUM(sd.price * sd.quantity), 0) AS total_ca
        FROM sale_details sd
        INNER JOIN sales s ON sd.sale_id = s.id
        INNER JOIN invoices i ON s.id = i.sale_id
        WHERE i.status = 'payée'
    ";
    
    $params = [];
    if ($start_date && $end_date) {
        $total_ca_query .= " WHERE DATE(s.sale_date) BETWEEN ? AND ?";
        $params[] = $start_date;
        $params[] = $end_date;
    } elseif ($start_date) {
        $total_ca_query .= " WHERE DATE(s.sale_date) >= ?";
        $params[] = $start_date;
    } elseif ($end_date) {
        $total_ca_query .= " WHERE DATE(s.sale_date) <= ?";
        $params[] = $end_date;
    }
    
    $stmt = $pdo->prepare($total_ca_query);
    $stmt->execute($params);
    $total_ca = $stmt->fetch(PDO::FETCH_ASSOC)['total_ca'];
    
    $result = [
        'success' => true,
        'total_ca' => (float)$total_ca,
        'period' => [
            'start' => $start_date,
            'end' => $end_date
        ]
    ];
    
    // Détail par période selon group_by
    if ($group_by === 'day' || $group_by === 'month' || $group_by === 'year') {
        $date_format = $group_by === 'day' ? '%Y-%m-%d' : ($group_by === 'month' ? '%Y-%m' : '%Y');
        $date_label = $group_by === 'day' ? 'DATE(s.sale_date)' : ($group_by === 'month' ? 'DATE_FORMAT(s.sale_date, "%Y-%m")' : 'YEAR(s.sale_date)');
        
        $period_query = "
            SELECT 
                $date_label AS period,
                SUM(sd.price * sd.quantity) AS ca
            FROM sale_details sd
            INNER JOIN sales s ON sd.sale_id = s.id
        ";
        
        $period_params = [];
        if ($start_date && $end_date) {
            $period_query .= " WHERE DATE(s.sale_date) BETWEEN ? AND ?";
            $period_params[] = $start_date;
            $period_params[] = $end_date;
        } elseif ($start_date) {
            $period_query .= " WHERE DATE(s.sale_date) >= ?";
            $period_params[] = $start_date;
        } elseif ($end_date) {
            $period_query .= " WHERE DATE(s.sale_date) <= ?";
            $period_params[] = $end_date;
        }
        
        $period_query .= " GROUP BY period ORDER BY period ASC";
        
        $stmt = $pdo->prepare($period_query);
        $stmt->execute($period_params);
        $result['by_period'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    // Détail par produit
    if ($group_by === 'product' || $group_by === 'all') {
        $product_query = "
            SELECT 
                p.id,
                p.name AS product_name,
                SUM(sd.quantity) AS total_quantity,
                AVG(sd.price) AS avg_price,
                SUM(sd.price * sd.quantity) AS total_ca
            FROM sale_details sd
            INNER JOIN sales s ON sd.sale_id = s.id
            INNER JOIN products p ON sd.product_id = p.id
        ";
        
        $product_params = [];
        if ($start_date && $end_date) {
            $product_query .= " WHERE DATE(s.sale_date) BETWEEN ? AND ?";
            $product_params[] = $start_date;
            $product_params[] = $end_date;
        } elseif ($start_date) {
            $product_query .= " WHERE DATE(s.sale_date) >= ?";
            $product_params[] = $start_date;
        } elseif ($end_date) {
            $product_query .= " WHERE DATE(s.sale_date) <= ?";
            $product_params[] = $end_date;
        }
        
        $product_query .= " GROUP BY p.id, p.name ORDER BY total_ca DESC";
        
        $stmt = $pdo->prepare($product_query);
        $stmt->execute($product_params);
        $result['by_product'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    // Statistiques supplémentaires
    $stats_query = "
        SELECT 
            COUNT(DISTINCT s.id) AS total_sales,
            COUNT(DISTINCT sd.product_id) AS total_products,
            AVG(sd.price * sd.quantity) AS avg_sale_amount
        FROM sale_details sd
        INNER JOIN sales s ON sd.sale_id = s.id
    ";
    
    $stats_params = [];
    if ($start_date && $end_date) {
        $stats_query .= " WHERE DATE(s.sale_date) BETWEEN ? AND ?";
        $stats_params[] = $start_date;
        $stats_params[] = $end_date;
    } elseif ($start_date) {
        $stats_query .= " WHERE DATE(s.sale_date) >= ?";
        $stats_params[] = $start_date;
    } elseif ($end_date) {
        $stats_query .= " WHERE DATE(s.sale_date) <= ?";
        $stats_params[] = $end_date;
    }
    
    $stmt = $pdo->prepare($stats_query);
    $stmt->execute($stats_params);
    $stats = $stmt->fetch(PDO::FETCH_ASSOC);
    $result['stats'] = [
        'total_sales' => (int)$stats['total_sales'],
        'total_products' => (int)$stats['total_products'],
        'avg_sale_amount' => (float)$stats['avg_sale_amount']
    ];
    
    // Calcul de la valeur totale du stock (prix d'achat × quantité)
    $stock_value_query = "SELECT IFNULL(SUM(price * quantity), 0) AS total_stock_value FROM products";
    $stock_stmt = $pdo->query($stock_value_query);
    $total_stock_value = $stock_stmt->fetch(PDO::FETCH_ASSOC)['total_stock_value'];
    $result['total_stock_value'] = (float)$total_stock_value;
    
    echo json_encode($result);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors du calcul du chiffre d\'affaire',
        'details' => $e->getMessage()
    ]);
}
?>

