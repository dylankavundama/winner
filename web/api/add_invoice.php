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

    // Vérifier que la vente existe et récupérer le total

    $stmt = $pdo->prepare('SELECT id, total FROM sales WHERE id = ?');

    $stmt->execute([$sale_id]);

    $sale = $stmt->fetch();

    if (!$sale) {

        echo json_encode(['success' => false, 'message' => 'Vente non trouvée.']);

        exit;

    }

    // Vérifier si une facture existe déjà pour cette vente

    $checkStmt = $pdo->prepare('SELECT id FROM invoices WHERE sale_id = ?');

    $checkStmt->execute([$sale_id]);

    $existingInvoice = $checkStmt->fetch();

    if ($existingInvoice) {

        // Une facture existe déjà, retourner son ID

        echo json_encode(['success' => true, 'invoice_id' => (int)$existingInvoice['id'], 'already_exists' => true]);

        exit;

    }

    // Récupérer le client_id et les produits de la vente pour marquer les dépôts
    $saleInfoStmt = $pdo->prepare('SELECT client_id FROM sales WHERE id = ?');
    $saleInfoStmt->execute([$sale_id]);
    $saleInfo = $saleInfoStmt->fetch(PDO::FETCH_ASSOC);
    
    if ($saleInfo) {
        $client_id = $saleInfo['client_id'];
        
        // Récupérer les produits de la vente
        $productsStmt = $pdo->prepare('SELECT DISTINCT product_id FROM sale_details WHERE sale_id = ?');
        $productsStmt->execute([$sale_id]);
        $products = $productsStmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Marquer les dépôts pour ce client et ces produits comme utilisés
        $updateDepositsStmt = $pdo->prepare('UPDATE deposits SET sale_id = ? WHERE client_id = ? AND product_id = ? AND sale_id IS NULL');
        foreach ($products as $product) {
            $updateDepositsStmt->execute([$sale_id, $client_id, $product['product_id']]);
        }
    }

    // Insérer la facture avec statut "payée" par défaut

    $stmt = $pdo->prepare('INSERT INTO invoices (sale_id, amount, status) VALUES (?, ?, "payée")');

    $stmt->execute([$sale_id, $sale['total']]);

    $invoice_id = $pdo->lastInsertId();

    echo json_encode(['success' => true, 'invoice_id' => (int)$invoice_id, 'already_exists' => false]);

} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([

        'success' => false,

        'message' => 'Erreur lors de la génération de la facture',

        'details' => $e->getMessage()

    ]);

} 