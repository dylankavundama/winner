<?php
// Utilisation du fichier de connexion à la base de données
require_once '../config/db.php';

// Set to 0 for production
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(0);

// Set headers for JSON response and CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // IMPORTANT: Change '*' to your specific domain(s) in production
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée. Seul POST est accepté.']);
    exit;
}

// Get the raw POST data
$input = json_decode(file_get_contents('php://input'), true);

// Validate required parameters: user_id, client_id, and items are now mandatory
if (!isset($input['user_id'], $input['client_id'], $input['items'])) {
    http_response_code(400); // Bad Request
    echo json_encode(['success' => false, 'message' => 'Paramètres manquants: user_id, client_id et items sont requis.']);
    exit;
}

if (!is_array($input['items']) || empty($input['items'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Le tableau des items est invalide ou vide.']);
    exit;
}

$user_id = (int)$input['user_id'];
$client_id = (int)$input['client_id'];
$items = $input['items'];

try {
    // Le code ci-dessous utilise l'objet $pdo fourni par 'db.php'
    // Pas besoin de getDbConnection()
    
    // Begin transaction for data integrity
    $pdo->beginTransaction();

    // 1. Check product availability
    $stock_out_data = [];
    foreach ($items as $item) {
        if (!isset($item['product_id'], $item['quantity'])) {
            throw new Exception('Item invalide: product_id et quantity sont requis pour chaque article.');
        }

        $product_id = (int)$item['product_id'];
        $quantity = (int)$item['quantity'];

        if ($quantity <= 0) {
            throw new Exception('La quantité doit être positive pour chaque article.');
        }

        // Get product stock
        $stmt_product = $pdo->prepare('SELECT quantity FROM products WHERE id = :id');
        $stmt_product->bindParam(':id', $product_id, PDO::PARAM_INT);
        $stmt_product->execute();
        $product = $stmt_product->fetch(PDO::FETCH_ASSOC);

        if (!$product) {
            throw new Exception("Produit avec l'ID $product_id non trouvé.");
        }
        if ($product['quantity'] < $quantity) {
            throw new Exception("Stock insuffisant pour le produit avec l'ID $product_id.");
        }
        
        $stock_out_data[] = [
            'product_id' => $product_id,
            'quantity' => $quantity,
        ];
    }
    
    // 2. Insert each item into the `stock_out_records` table and update product stock
    foreach ($stock_out_data as $record) {
        $product_id = $record['product_id'];
        $quantity = $record['quantity'];

        // Insert into stock_out_records with default paid_status set to 0
        $stmt_out = $pdo->prepare('INSERT INTO stock_out_records (product_id, client_id, quantity, reason, out_date, paid_status) VALUES (:product_id, :client_id, :quantity, :reason, NOW(), 0)');
        $stmt_out->bindParam(':product_id', $product_id, PDO::PARAM_INT);
        $stmt_out->bindParam(':client_id', $client_id, PDO::PARAM_INT);
        $stmt_out->bindParam(':quantity', $quantity, PDO::PARAM_INT);
        $reason = 'Vente';
        $stmt_out->bindParam(':reason', $reason, PDO::PARAM_STR);
        $stmt_out->execute();

        // Update product stock
        $stmt_update_stock = $pdo->prepare('UPDATE products SET quantity = quantity - :quantity WHERE id = :id');
        $stmt_update_stock->bindParam(':quantity', $quantity, PDO::PARAM_INT);
        $stmt_update_stock->bindParam(':id', $product_id, PDO::PARAM_INT);
        $stmt_update_stock->execute();
    }

    // Commit the transaction if all operations were successful
    $pdo->commit();

    echo json_encode(['success' => true, 'message' => 'Sorties de stock enregistrées avec succès.']);

} catch (Exception $e) {
    // Rollback the transaction on any error
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log("Stock out recording error: " . $e->getMessage());
    http_response_code(400); // Bad Request for client-side errors (e.g., stock)
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    exit;
}
?>