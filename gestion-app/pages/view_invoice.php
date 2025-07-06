<?php
// Ensure the database configuration is included
require_once '../config/db.php';

// Check if an invoice ID is provided in the URL
if (!isset($_GET['id'])) {
    echo 'Invoice ID not provided. Cannot display invoice.';
    exit;
}

// Sanitize and validate the invoice ID
$invoice_id = intval($_GET['id']);
if ($invoice_id <= 0) {
    echo 'Invalid Invoice ID.';
    exit;
}

try {
    // Fetch invoice, sale, and client details using a JOIN query
    $stmt = $pdo->prepare('
        SELECT
            i.*,
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
    $invoice = $stmt->fetch(PDO::FETCH_ASSOC); // Fetch as associative array

    // If no invoice is found with the given ID
    if (!$invoice) {
        echo 'Invoice not found.';
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
            d.sale_id = ?
    ');
    $stmt->execute([$invoice['sale_id']]);
    $details = $stmt->fetchAll(PDO::FETCH_ASSOC); // Fetch all product details
} catch (PDOException $e) {
    // Handle database errors gracefully
    echo 'Database error: ' . $e->getMessage();
    exit;
}
?>

<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Facture #<?= htmlspecialchars($invoice['id']) ?></title>
    <style>
        /* General body styling */
        body {
            font-family: Arial, sans-serif;
            background: #f5f5f5;
            margin: 0;
            padding: 20px;
            color: #333;
        }

        /* Invoice container styling */
        .facture-box {
            max-width: 700px;
            margin: 30px auto;
            border: 1px solid #ccc;
            padding: 30px;
            background: #fff;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            text-align: center;
        }

        /* Header section */
        .facture-header {
            margin-bottom: 30px;
            border-bottom: 1px solid #eee;
            padding-bottom: 20px;
        }

        .facture-header img {
            max-width: 150px;
            display: block;
            margin: 0 auto 15px auto;
        }

        .facture-header h1 {
            margin-bottom: 5px;
            color: #2c3e50;
            font-size: 2em;
        }

        .facture-header h2 {
            margin-top: 5px;
            color: #34495e;
            font-size: 1.5em;
        }

        .facture-header p {
            color: #7f8c8d;
            font-size: 0.9em;
        }

        /* Status badge styling */
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .status-paid {
            background-color: #27ae60;
            color: white;
        }

        .status-unpaid {
            background-color: #f39c12;
            color: white;
        }

        /* Status section styling */
        .facture-status {
            margin: 20px 0;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }

        .status-info {
            text-align: center;
            font-size: 1.1em;
        }

        .status-info strong {
            margin-right: 10px;
            color: #2c3e50;
        }

        /* Details section (company and client) */
        .facture-details {
            display: flex; /* Enable flexbox for side-by-side layout */
            justify-content: space-between; /* Distribute space between items */
            align-items: flex-start; /* Align items to the top */
            margin-bottom: 20px;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }

        .company-details-left,
        .client-details-right {
            flex: 1; /* Allow both sections to grow and shrink */
            padding: 0 10px; /* Add some padding for spacing */
        }

        .company-details-left {
            text-align: left;
        }

        .client-details-right {
            text-align: right; /* Align client details to the right */
        }

        .facture-details strong {
            /* This can stay if you want consistent width for labels within each div */
            display: inline-block;
            /* width: 100px; Remove if not needed for vertical alignment */
        }

        /* Products table */
        .facture-products {
            width: 100%;
            margin: 0 auto 30px auto;
            border-collapse: collapse;
            font-size: 0.9em;
        }

        .facture-products th,
        .facture-products td {
            border: 1px solid #eee;
            padding: 10px;
            text-align: center;
        }

        .facture-products th {
            background-color: #f2f2f2;
            font-weight: bold;
        }

        .facture-products tr:nth-child(even) {
            background-color: #f9f9f9;
        }

        /* Total row */
        .facture-products .total-row td {
            text-align: right;
            font-size: 1.1em;
            font-weight: bold;
            background-color: #f2f2f2;
        }

        .facture-products .total-row td:last-child {
            text-align: center;
        }


        /* Footer notes */
        .facture-notes {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            font-size: 0.85em;
            color: #555;
            line-height: 1.5;
            text-align: left;
        }

        .facture-thanks {
            margin-top: 30px;
            font-size: 1.1em;
            color: #2c3e50;
        }

        .facture-signature {
            margin-top: 40px;
            font-size: 1.2em;
            font-weight: bold;
            color: #3498db;
        }

        /* Navigation and print button */
        .facture-actions {
            margin-top: 30px;
            text-align: center;
        }

        .facture-actions a {
            display: inline-block;
            margin: 0 10px;
            padding: 10px 20px;
            background-color: #3498db;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            transition: background-color 0.3s ease;
        }

        .facture-actions a:hover {
            background-color: #2980b9;
        }

        .facture-actions button {
            padding: 10px 25px;
            background-color: #2ecc71;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 1em;
            transition: background-color 0.3s ease;
        }

        .facture-actions button:hover {
            background-color: #27ae60;
        }

        /* Responsive design for smaller screens */
        @media (max-width: 600px) {
            .facture-details {
                flex-direction: column; /* Stack sections vertically on small screens */
                align-items: center; /* Center items when stacked */
            }
            .company-details-left,
            .client-details-right {
                text-align: center; /* Center text when stacked */
                margin-bottom: 15px; /* Add space between stacked sections */
            }
        }

        /* Print-specific styles */
        @media print {
            body {
                background: none;
                margin: 0;
                padding: 0;
            }
            .facture-box {
                border: none;
                box-shadow: none;
                margin: 0;
                padding: 0;
            }
            .facture-actions {
                display: none; /* Hide buttons when printing */
            }
        }
    </style>
</head>
<body>
    <div class="facture-box">
        <div class="facture-header">
            <img src="../assets/logo.png" alt="Company Logo">
            <h1>Winner Company</h1>
            <h2>Facture #<?= htmlspecialchars($invoice['id']) ?></h2>
            <p>Date : <?= htmlspecialchars($invoice['invoice_date']) ?> | 
               Statut : <span class="status-badge <?= $invoice['status'] === 'payée' ? 'status-paid' : 'status-unpaid' ?>"><?= htmlspecialchars($invoice['status']) ?></span></p>
        </div>

        <div class="facture-details">
            <div class="company-details-left">
                <p><strong>Contact :</strong> +243 823023277<br>
                <strong>Adresse physique :</strong> Butembo, Galerie Kisunga N° : A01</p>
            </div>
            <div class="client-details-right">
                <p><strong>Client :</strong> <?= htmlspecialchars($invoice['client_name']) ?><br>
                <strong>Téléphone :</strong> <?= htmlspecialchars($invoice['phone']) ?><br>
                <strong>IMEI :</strong> <?= htmlspecialchars($invoice['imei']) ?><br>
                <strong>Garantie :</strong> <?= htmlspecialchars($invoice['garanti']) ?></p>
            </div>
        </div>

        <!-- Status section -->
        <div class="facture-status">
            <div class="status-info">
                <strong>Statut de la facture :</strong>
                <span class="status-badge <?= $invoice['status'] === 'payée' ? 'status-paid' : 'status-unpaid' ?>">
                    <?= htmlspecialchars($invoice['status']) ?>
                </span>
            </div>
        </div>

        <table class="facture-products">
            <thead>
                <tr>
                    <th>Produit</th>
                    <th>Quantité</th>
                    <th>Prix unitaire</th>
                    <th>Total</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($details as $d): ?>
                <tr>
                    <td><?= htmlspecialchars($d['name']) ?></td>
                    <td><?= htmlspecialchars($d['quantity']) ?></td>
                    <td><?= number_format($d['price'], 2) ?> $</td>
                    <td><?= number_format($d['price'] * $d['quantity'], 2) ?> $</td>
                </tr>
                <?php endforeach; ?>
                <tr class="total-row">
                    <td colspan="3"><strong>Total :</strong></td>
                    <td><strong><?= number_format($invoice['amount'], 2) ?> $</strong></td>
                </tr>
            </tbody>
        </table>

        <div class="facture-notes">
            <p>L'autocollant de garantie doit être apposé sur le téléphone. Nous offrons une garantie spéciale de 7 jours pour les problèmes de batterie.
            <br> <strong>NB:</strong> Veuillez noter que la garantie ne couvre pas les téléphones dont l'écran est fissuré ou rayé.</p>
        </div>

        <p class="facture-thanks">Ce fut un plaisir de faire affaire avec vous.</p>

        <h1 class="facture-signature">God Wine</h1>

        <div class="facture-actions">
            <a href="invoices.php">Retour à la liste des factures</a>
            <button onclick="window.print()">Imprimer la facture</button>
        </div>
    </div>

    <?php if (isset($_GET['print']) && $_GET['print'] == 1): ?>
    <script>
        // Automatically trigger print dialog if 'print=1' is in the URL
        window.onload = function() {
            window.print();
        };
    </script>
    <?php endif; ?>
</body>
</html>