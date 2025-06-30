<?php
require_once '../config/db.php';
if (!isset($_GET['id'])) {
    echo 'Facture introuvable.';
    exit;
}
$invoice_id = intval($_GET['id']);
// Récupérer la facture, la vente, le client
$stmt = $pdo->prepare('SELECT i.*, s.sale_date, s.total, c.name AS client_name, c.email, c.phone, c.address FROM invoices i INNER JOIN sales s ON i.sale_id = s.id INNER JOIN clients c ON s.client_id = c.id WHERE i.id = ?');
$stmt->execute([$invoice_id]);
$invoice = $stmt->fetch();
if (!$invoice) {
    echo 'Facture introuvable.';
    exit;
}
// Détails des produits
$stmt = $pdo->prepare('SELECT p.name, d.quantity, d.price FROM sale_details d INNER JOIN products p ON d.product_id = p.id WHERE d.sale_id = ?');
$stmt->execute([$invoice['sale_id']]);
$details = $stmt->fetchAll();
?>
<style>
    body { background: #f5f5f5; }
    .facture-box { max-width: 700px; margin: 30px auto; border: 1px solid #ccc; padding: 20px; background: #fff; text-align: center; }
    .facture-header { margin-bottom: 20px; }
    .facture-details { text-align: left; display: inline-block; margin-bottom: 20px; }
    .facture-products { width: 90%; margin: 0 auto 20px auto; border-collapse: collapse; }
    .facture-products th, .facture-products td { border: 1px solid #ccc; padding: 5px; text-align: center; }
</style>
<div class="facture-box">
    <div class="facture-header">
        <img src="../assets/logo.png" alt="Logo entreprise" style="max-width:120px; display:block; margin:0 auto 10px auto;">
        <h1 style="margin-bottom:0;">Nom de l'entreprise</h1>
        <h2 style="margin-top:5px;">Facture #<?= $invoice['id'] ?></h2>
        <!-- <p>Date : <?= $invoice['invoice_date'] ?> | Statut : <?= $invoice['status'] ?></p> -->
          <p>Date : <?= $invoice['invoice_date'] ?> | Statut : Payer</p>
     
    </div>
    <div class="facture-details">
        <strong>Client :</strong> <?= htmlspecialchars($invoice['client_name']) ?><br>
        <strong>Email :</strong> <?= htmlspecialchars($invoice['email']) ?><br>
        <strong>Téléphone :</strong> <?= htmlspecialchars($invoice['phone']) ?><br>
        <strong>Adresse :</strong> <?= nl2br(htmlspecialchars($invoice['address'])) ?><br>
    </div>
    <table class="facture-products">
        <tr>
            <th>Produit</th>
            <th>Quantité</th>
            <th>Prix unitaire</th>
            <th>Total</th>
        </tr>
        <?php foreach ($details as $d): ?>
        <tr>
            <td><?= htmlspecialchars($d['name']) ?></td>
            <td><?= $d['quantity'] ?></td>
            <td><?= number_format($d['price'], 2) ?> $</td>
            <td><?= number_format($d['price'] * $d['quantity'], 2) ?> $</td>
        </tr>
        <?php endforeach; ?>
        <tr>
            <td colspan="3" style="text-align:right"><strong>Total :</strong></td>
            <td><strong><?= number_format($invoice['amount'], 2) ?> $</strong></td>
        </tr>
    </table>
    <p><a href="invoices.php">Retour à la liste des factures</a></p>
    <br>

       <button onclick="window.print()" style="margin-top:10px; display:inline-block;">facture</button>
</div>
<?php if (isset($_GET['print']) && $_GET['print'] == 1): ?>
<script>window.onload = function(){ window.print(); };</script>
<?php endif; ?> 