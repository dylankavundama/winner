<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
require_once '../config/db.php';

try {
    // Total des dettes (somme des factures impayées)
    $total_dette = $pdo->query("SELECT IFNULL(SUM(amount), 0) FROM invoices WHERE status = 'impayée'")->fetchColumn();

    // Liste des clients avec leurs dettes cumulées
    $sql = "SELECT c.id as client_id, c.name as client_name, SUM(i.amount) as total_dette, COUNT(i.id) as nb_factures
            FROM clients c
            JOIN sales s ON c.id = s.client_id
            JOIN invoices i ON s.id = i.sale_id
            WHERE i.status = 'impayée'
            GROUP BY c.id, c.name
            ORDER BY total_dette DESC";
    
    $stmt = $pdo->query($sql);
    $clients_dettes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Détail des factures impayées (optionnel mais utile)
    $sql_details = "SELECT i.id as invoice_id, c.name as client_name, i.amount, s.sale_date, s.id as sale_id
                    FROM invoices i
                    JOIN sales s ON i.sale_id = s.id
                    JOIN clients c ON s.client_id = c.id
                    WHERE i.status = 'impayée'
                    ORDER BY s.sale_date DESC";
    $details_factures = $pdo->query($sql_details)->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'total_dette' => (double)$total_dette,
        'clients' => $clients_dettes,
        'details' => $details_factures
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération des dettes : ' . $e->getMessage()
    ]);
}
?>
