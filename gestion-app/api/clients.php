<?php
session_start();
header('Content-Type: application/json');

require_once '../config/db.php'; // Ensure this path is correct

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Création d'un nouveau client
    $input = json_decode(file_get_contents('php://input'), true);
    if (!isset($input['name']) || empty(trim($input['name']))) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Le nom du client est requis.'
        ]);
        exit;
    }
    $name = trim($input['name']);
    // Ajoute ici d'autres champs si besoin (email, téléphone...)
    try {
        $stmt = $pdo->prepare('INSERT INTO clients (name) VALUES (:name)');
        $stmt->bindParam(':name', $name);
        $stmt->execute();
        $client_id = $pdo->lastInsertId();
        echo json_encode([
            'success' => true,
            'client_id' => (int)$client_id
        ]);
    } catch (PDOException $e) {
        error_log("Database error in clients.php (POST): " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Erreur lors de la création du client.'
        ]);
    }
    exit;
}

try {
    $stmt = $pdo->query('SELECT * FROM clients');
    $clients = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Structure the response to match Flutter's expectation (success: true, clients: [...])
    echo json_encode([
        'success' => true,
        'clients' => $clients
    ]);

} catch (PDOException $e) { // Use PDOException for database-related errors
    // Log the error for debugging purposes (optional, but recommended)
    error_log("Database error in clients.php: " . $e->getMessage());

    http_response_code(500); // Internal Server Error
    echo json_encode([
        'success' => false,
        'message' => 'Database error',
        'details' => $e->getMessage() // Include details for development, remove for production
    ]);
} catch (Exception $e) { // Catch any other unexpected exceptions
    // Log other errors
    error_log("General error in clients.php: " . $e->getMessage());

    http_response_code(500); // Internal Server Error
    echo json_encode([
        'success' => false,
        'message' => 'An unexpected server error occurred',
        'details' => $e->getMessage() // Include details for development, remove for production
    ]);
}
?>