<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

// Utiliser le fichier de configuration partagé
require_once '../config/db.php';

// Récupérer tous les products
function getAllProducts() {
    global $pdo;
    
    try {
        $stmt = $pdo->query("
            SELECT 
                id,
                name,
                description,
                price,
                prix_vente,
                quantity,
                created_at
            FROM products
            ORDER BY name ASC
        ");
        
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        return [
            'success' => true,
            'products' => $products,
            'count' => count($products)
        ];
        
    } catch(PDOException $e) {
        return [
            'success' => false,
            'message' => 'Erreur de requête: ' . $e->getMessage()
        ];
    }
}

// Récupérer un produit par ID
function getProductById($id) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("
            SELECT 
                id,
                name,
                description,
                price,
                prix_vente,
                quantity,
                created_at
            FROM products
            WHERE id = :id
        ");
        
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();
        
        $product = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($product) {
            return [
                'success' => true,
                'products' => $product
            ];
        } else {
            return [
                'success' => false,
                'message' => 'Produit non trouvé'
            ];
        }
        
    } catch(PDOException $e) {
        return [
            'success' => false,
            'message' => 'Erreur de requête: ' . $e->getMessage()
        ];
    }
}

// Gestion de la requête
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (isset($_GET['id'])) {
        $id = filter_var($_GET['id'], FILTER_VALIDATE_INT);
        
        if ($id === false || $id <= 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'ID de produit invalide'
            ]);
            exit;
        }
        
        $response = getProductById($id);
    } else {
        $response = getAllProducts();
    }
    
    echo json_encode($response);
} else {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Méthode non autorisée'
    ]);
}