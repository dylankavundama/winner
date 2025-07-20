<?php
// Set to 0 for production to hide errors from users
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(0);

// Set headers for JSON response and CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // IMPORTANT: Change '*' to your specific domain(s) in production
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Handle OPTIONS pre-flight requests (for CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// --- Database Connection Details (Defined Directly Here) ---
// REPLACE THESE WITH YOUR ACTUAL DATABASE CREDENTIALS
define('DB_HOST', 'localhost'); // e.g., 'localhost' or your database server IP
define('DB_NAME', 'gestion_app'); // e.g., 'gestion_app_db'
define('DB_USER', 'root'); // e.g., 'root'
define('DB_PASSWORD', ''); // e.g., '' for no password, or 'mysecretpassword'
// --- End Database Connection Details ---


function getDbConnection() {
    try {
        $conn = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASSWORD
        );
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        return $conn;
    } catch (PDOException $e) {
        // Log the actual error for debugging (check your PHP error logs)
        error_log("Database connection error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Erreur de connexion à la base de données.']);
        exit;
    }
}

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); // Method Not Allowed
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée.']);
    exit;
}

// Get the raw POST data
$input = json_decode(file_get_contents('php://input'), true);

// Validate required parameters
if (!isset($input['id'], $input['name'], $input['price'], $input['prix_vente'], $input['quantity'])) {
    http_response_code(400); // Bad Request
    echo json_encode(['success' => false, 'message' => 'Paramètres manquants: id, name, price, prix_vente, quantity sont requis.']);
    exit;
}

// Sanitize and cast input values
$id = (int)$input['id'];
$name = trim($input['name']);
// Description is optional and handled
$description = isset($input['description']) ? trim($input['description']) : '';
$price = (float)$input['price'];
$prix_vente = (float)$input['prix_vente'];
$quantity = (int)$input['quantity'];

// Additional validation for values
if ($id <= 0 || $price < 0 || $prix_vente < 0 || $quantity < 0) {
    http_response_code(400); // Bad Request
    echo json_encode(['success' => false, 'message' => 'Les valeurs numériques (id, price, prix_vente, quantity) doivent être valides et non négatives.']);
    exit;
}
if (empty($name)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Le nom du produit ne peut pas être vide.']);
    exit;
}

try {
    $conn = getDbConnection(); // Get the database connection

    // Prepare SQL statement to prevent SQL injection
    $stmt = $conn->prepare('UPDATE products SET name = :name, description = :description, price = :price, prix_vente = :prix_vente, quantity = :quantity WHERE id = :id');

    // Bind parameters to the prepared statement
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->bindParam(':name', $name, PDO::PARAM_STR);
    $stmt->bindParam(':description', $description, PDO::PARAM_STR);
    $stmt->bindParam(':price', $price, PDO::PARAM_STR); // PDO can handle float values as STR
    $stmt->bindParam(':prix_vente', $prix_vente, PDO::PARAM_STR);
    $stmt->bindParam(':quantity', $quantity, PDO::PARAM_INT);

    // Execute the statement
    $stmt->execute();

    // Check if the update affected any rows
    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => true, 'message' => 'Produit mis à jour avec succès']);
    } else {
        // This could mean the ID wasn't found or no actual changes were made
        echo json_encode(['success' => false, 'message' => 'Aucune modification effectuée ou produit non trouvé.']);
    }

} catch (PDOException $e) {
    // Log the error for internal debugging
    error_log("Product update PDO error: " . $e->getMessage());
    http_response_code(500); // Internal Server Error
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour du produit.']);
    exit;
}
?>