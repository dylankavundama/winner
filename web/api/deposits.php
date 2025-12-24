<?php
header('Content-Type: application/json');

require_once '../config/db.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Données JSON invalides.',
        ]);
        exit;
    }

    $clientId = $input['client_id'] ?? null;
    $productId = $input['product_id'] ?? null;
    $amount = $input['amount'] ?? null;
    $depositDate = $input['deposit_date'] ?? null;

    if (!$clientId || !$productId || !$amount) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'client_id, product_id et amount sont obligatoires.',
        ]);
        exit;
    }

    if (!is_numeric($amount) || $amount <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Le montant doit être un nombre positif.',
        ]);
        exit;
    }

    try {
        $stockReserved = 0;
        $message = '';

        $pdo->beginTransaction();

        // Vérifier si un dépôt précédent a déjà réservé ce produit pour ce client
        $existing = $pdo->prepare(
            'SELECT COUNT(*) FROM deposits 
             WHERE client_id = :client_id AND product_id = :product_id AND stock_reserved = 1'
        );
        $existing->execute([
            ':client_id' => $clientId,
            ':product_id' => $productId,
        ]);
        $alreadyReserved = (int)$existing->fetchColumn() > 0;

        if ($alreadyReserved) {
            // Le stock a déjà été décrémenté lors du premier dépôt pour ce client/produit.
            // On n'enlève PAS à nouveau du stock, mais on garde l'info de réservation.
            $stockReserved = 1;
            $message =
                'Dépôt supplémentaire enregistré pour un produit déjà réservé.';
        } else {
            // Premier dépôt pour ce client/produit : on réserve le stock
            $stmt = $pdo->prepare('SELECT quantity FROM products WHERE id = :id');
            $stmt->execute([':id' => $productId]);
            $product = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$product) {
                http_response_code(404);
                echo json_encode([
                    'success' => false,
                    'message' => 'Produit introuvable.',
                ]);
                exit;
            }

            $quantity = (int)$product['quantity'];

            if ($quantity > 0) {
                // Réserver 1 unité du produit (sortir du stock)
                $update = $pdo->prepare(
                    'UPDATE products SET quantity = quantity - 1 WHERE id = :id AND quantity > 0'
                );
                $update->execute([':id' => $productId]);

                // Vérifier qu'une ligne a bien été mise à jour
                if ($update->rowCount() > 0) {
                    $stockReserved = 1;
                    $message =
                        'Dépôt enregistré et produit réservé (retiré du stock).';
                } else {
                    // Conflit de stock (autre opération en même temps)
                    $message =
                        'Dépôt enregistré, mais le produit est maintenant en rupture de stock.';
                }
            } else {
                // Pas de stock disponible
                $message =
                    'Dépôt enregistré, mais le produit est actuellement hors stock.';
            }
        }

        // Enregistrer le dépôt avec l\'info de réservation
        $insert = $pdo->prepare(
            'INSERT INTO deposits (client_id, product_id, amount, deposit_date, stock_reserved) 
             VALUES (:client_id, :product_id, :amount, :deposit_date, :stock_reserved)'
        );
        $insert->execute([
            ':client_id' => $clientId,
            ':product_id' => $productId,
            ':amount' => $amount,
            ':deposit_date' => $depositDate ?: date('Y-m-d'),
            ':stock_reserved' => $stockReserved,
        ]);

        $depositId = (int)$pdo->lastInsertId();
        $pdo->commit();

        echo json_encode([
            'success' => true,
            'message' => $message,
            'deposit_id' => $depositId,
            'stock_reserved' => (bool)$stockReserved,
        ]);
    } catch (PDOException $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Erreur lors de l\'enregistrement du dépôt.',
            'details' => $e->getMessage(),
        ]);
    }
    exit;
}

// GET : liste des dépôts, avec possibilité de filtrer et de retourner un total cumulé
$clientId = isset($_GET['client_id']) ? (int)$_GET['client_id'] : null;
$productId = isset($_GET['product_id']) ? (int)$_GET['product_id'] : null;

try {
    if ($clientId && $productId) {
        // Tous les dépôts pour ce client et ce produit + total cumulé
        $stmt = $pdo->prepare(
            'SELECT d.*, c.name AS client_name, p.name AS product_name
             FROM deposits d
             LEFT JOIN clients c ON d.client_id = c.id
             LEFT JOIN products p ON d.product_id = p.id
             WHERE d.client_id = :client_id AND d.product_id = :product_id
             ORDER BY d.deposit_date DESC, d.id DESC'
        );
        $stmt->execute([
            ':client_id' => $clientId,
            ':product_id' => $productId,
        ]);
        $deposits = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $sumStmt = $pdo->prepare(
            'SELECT IFNULL(SUM(amount),0) AS total_amount
             FROM deposits
             WHERE client_id = :client_id AND product_id = :product_id'
        );
        $sumStmt->execute([
            ':client_id' => $clientId,
            ':product_id' => $productId,
        ]);
        $totalRow = $sumStmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'success' => true,
            'deposits' => $deposits,
            'total_amount' => (float)$totalRow['total_amount'],
        ]);
        exit;
    }

    if ($clientId) {
        $stmt = $pdo->prepare(
            'SELECT d.*, c.name AS client_name, p.name AS product_name
             FROM deposits d
             LEFT JOIN clients c ON d.client_id = c.id
             LEFT JOIN products p ON d.product_id = p.id
             WHERE d.client_id = :client_id
             ORDER BY d.deposit_date DESC, d.id DESC'
        );
        $stmt->execute([':client_id' => $clientId]);
    } else {
        $stmt = $pdo->query(
            'SELECT d.*, c.name AS client_name, p.name AS product_name
             FROM deposits d
             LEFT JOIN clients c ON d.client_id = c.id
             LEFT JOIN products p ON d.product_id = p.id
             ORDER BY d.deposit_date DESC, d.id DESC'
        );
    }

    $deposits = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success' => true,
        'deposits' => $deposits,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération des dépôts.',
        'details' => $e->getMessage(),
    ]);
}


