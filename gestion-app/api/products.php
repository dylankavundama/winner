<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

// Configuration de la base de données
define('DB_HOST', 'localhost');
define('DB_NAME', 'gestion_app');
define('DB_USER', 'root');
define('DB_PASSWORD', '');

// Fonction de connexion à la base de données
function getDbConnection() {
    try {
        $conn = new PDO(
            "mysql:host=".DB_HOST.";dbname=".DB_NAME.";charset=utf8mb4", 
            DB_USER, 
            DB_PASSWORD
        );
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $conn;
    } catch(PDOException $e) {
        die(json_encode([
            'success' => false,
            'message' => 'Erreur de connexion à la base de données'
        ]));
    }
}

// Récupérer tous les products
function getAllProducts() {
    $conn = getDbConnection();
    
    try {
        $stmt = $conn->query("
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
    $conn = getDbConnection();
    
    try {
        $stmt = $conn->prepare("
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