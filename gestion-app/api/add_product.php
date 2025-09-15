<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// Configuration de la base de données
define('DB_HOST', 'localhost');
define('DB_NAME', 'winnerco_db');
define('DB_USER', 'winnerco_admin');
define('DB_PASSWORD', 'VY@LS?Z)_,V5');

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
        // En cas d'échec de connexion, retourner une erreur JSON
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur de connexion à la base de données']);
        exit;
    }
}

// Vérifier que la méthode de requête est POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée. Seul POST est accepté.']);
    exit;
}

// Récupérer le corps de la requête JSON
$json_input = file_get_contents('php://input');
$data = json_decode($json_input, true);

// Vérifier si les données JSON sont valides et non vides
if ($data === null) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Données JSON invalides.']);
    exit;
}

// Validation des champs obligatoires
$required_fields = ['name', 'price', 'prix_vente', 'quantity'];
foreach ($required_fields as $field) {
    if (!isset($data[$field]) || (empty($data[$field]) && $data[$field] !== 0)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => "Le champ '$field' est manquant ou vide."]);
        exit;
    }
}

// Récupération des données et assainissement
$name = htmlspecialchars($data['name']);
$description = htmlspecialchars($data['description'] ?? ''); // Description est facultative
$price = filter_var($data['price'], FILTER_VALIDATE_FLOAT);
$prix_vente = filter_var($data['prix_vente'], FILTER_VALIDATE_FLOAT);
$quantity = filter_var($data['quantity'], FILTER_VALIDATE_INT);

// Vérifier si les valeurs numériques sont valides
if ($price === false || $prix_vente === false || $quantity === false) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Prix ou quantité invalide.']);
    exit;
}

// Connexion à la base de données
$conn = getDbConnection();

try {
    // Préparation de la requête d'insertion sécurisée
    $stmt = $conn->prepare("
        INSERT INTO products (name, description, price, prix_vente, quantity, created_at)
        VALUES (:name, :description, :price, :prix_vente, :quantity, NOW())
    ");

    // Lier les paramètres
    $stmt->bindParam(':name', $name);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':price', $price);
    $stmt->bindParam(':prix_vente', $prix_vente);
    $stmt->bindParam(':quantity', $quantity, PDO::PARAM_INT);

    // Exécuter la requête
    $stmt->execute();

    // Vérifier si l'insertion a réussi
    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => true, 'message' => 'Produit ajouté avec succès.', 'id' => $conn->lastInsertId()]);
    } else {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'ajout du produit.']);
    }

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur de requête: ' . $e->getMessage()]);
}

$conn = null;
?>