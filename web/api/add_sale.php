<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../config/db.php'; 

function addSale($pdo, $clientId, $userId, $total, $imei, $garanti, $products) {
    try {
        $pdo->beginTransaction();
        
        // 1. Insérer la vente principale
        $stmt = $pdo->prepare("
            INSERT INTO sales 
            (client_id, user_id, total, imei, garanti, sale_date)
            VALUES 
            (:client_id, :user_id, :total, :imei, :garanti, NOW())
        ");
        
        $stmt->execute([
            ':client_id' => $clientId,
            ':user_id' => $userId,
            ':total' => $total,
            ':imei' => $imei,
            ':garanti' => $garanti
        ]);
        
        $saleId = $pdo->lastInsertId();
        
        // 2. Insérer les articles de la vente
        $itemStmt = $pdo->prepare("
            INSERT INTO sale_details 
            (sale_id, product_id, quantity, price)
            VALUES 
            (:sale_id, :product_id, :quantity, :price)
        ");
        
        foreach ($products as $product) {
            $itemStmt->execute([
                ':sale_id' => $saleId,
                ':product_id' => $product['id'],
                ':quantity' => $product['quantity'],
                ':price' => $product['price']
            ]);
            
            // 3. Mettre à jour le stock du produit
            $updateStmt = $pdo->prepare("
                UPDATE products 
                SET quantity = quantity - :quantity 
                WHERE id = :product_id
            ");
            
            $updateStmt->execute([
                ':quantity' => $product['quantity'],
                ':product_id' => $product['id']
            ]);
        }
        
        $pdo->commit();
        
        return [
            'success' => true,
            'message' => 'Vente enregistrée avec succès',
            'sale_id' => $saleId
        ];
        
    } catch(PDOException $e) {
        $pdo->rollBack();
        return [
            'success' => false,
            'message' => 'Erreur lors de l\'enregistrement: ' . $e->getMessage()
        ];
    }
}

// Traitement de la requête
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if ($input === null) {
            echo json_encode(['success' => false, 'message' => 'Données JSON invalides']);
            exit;
        }
        
        // Validation des données requises
        $requiredFields = ['client_id', 'user_id', 'total', 'imei', 'products'];
        foreach ($requiredFields as $field) {
            if (!isset($input[$field])) {
                echo json_encode(['success' => false, 'message' => "Le champ $field est obligatoire"]);
                exit;
            }
        }
        
        // Garantie est optionnelle
        $garanti = $input['garanti'] ?? '';
        
        $result = addSale(
            $pdo,
            $input['client_id'],
            $input['user_id'],
            $input['total'],
            $input['imei'],
            $garanti,
            $input['products']
        );
        
        echo json_encode($result);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false, 
            'message' => 'Erreur serveur: ' . $e->getMessage()
        ]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
}
?>