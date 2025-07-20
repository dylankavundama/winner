<?php
header('Content-Type: application/json');
require_once '../config/db.php';

if (!isset($_GET['id'])) {
    echo json_encode(['success' => false, 'message' => 'Invoice ID not provided.']);
    exit;
}
$invoice_id = intval($_GET['id']);
if ($invoice_id <= 0) {
    echo json_encode(['success' => false, 'message' => 'Invalid Invoice ID.']);
    exit;
}

try {
    // Fetch invoice, sale, and client details
    $stmt = $pdo->prepare('
        SELECT
            i.id,
            i.status,
            s.sale_date,
            s.total,
            s.imei,
            s.garanti,
            c.name AS client_name,
            c.email,
            c.phone,
            c.address
        FROM
            invoices i
        INNER JOIN
            sales s ON i.sale_id = s.id
        INNER JOIN
            clients c ON s.client_id = c.id
        WHERE
            i.id = ?
    ');
    $stmt->execute([$invoice_id]);
    $invoice = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$invoice) {
        echo json_encode(['success' => false, 'message' => 'Invoice not found.']);
        exit;
    }
    // Fetch product details for the sale
    $stmt = $pdo->prepare('
        SELECT
            p.name,
            d.quantity,
            d.price
        FROM
            sale_details d
        INNER JOIN
            products p ON d.product_id = p.id
        WHERE
            d.sale_id = (
                SELECT sale_id FROM invoices WHERE id = ?
            )
    ');
    $stmt->execute([$invoice_id]);
    $details = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Structure the response
    echo json_encode([
        'success' => true,
        'invoice' => [
            'id' => $invoice['id'],
            'status' => $invoice['status'],
            'sale_date' => $invoice['sale_date'],
            'total' => $invoice['total'],
            'imei' => $invoice['imei'],
            'garanti' => $invoice['garanti'],
            'client' => [
                'name' => $invoice['client_name'],
                'email' => $invoice['email'],
                'phone' => $invoice['phone'],
                'address' => $invoice['address'],
            ],
            'products' => $details
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération de la facture',
        'details' => $e->getMessage()
    ]);
} 