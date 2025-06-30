<?php
require_once '../config/db.php';
require_once '../vendor/setasign/fpdf/fpdf.php';

if (!isset($_POST['invoice_id'])) {
    die('Facture introuvable.');
}
$invoice_id = intval($_POST['invoice_id']);
// Récupérer la facture, la vente, le client
$stmt = $pdo->prepare('SELECT i.*, s.sale_date, s.total, c.name AS client_name, c.email, c.phone, c.address FROM invoices i INNER JOIN sales s ON i.sale_id = s.id INNER JOIN clients c ON s.client_id = c.id WHERE i.id = ?');
$stmt->execute([$invoice_id]);
$invoice = $stmt->fetch();
if (!$invoice) die('Facture introuvable.');
// Détails des produits
$stmt = $pdo->prepare('SELECT p.name, d.quantity, d.price FROM sale_details d INNER JOIN products p ON d.product_id = p.id WHERE d.sale_id = ?');
$stmt->execute([$invoice['sale_id']]);
$details = $stmt->fetchAll();

$pdf = new FPDF();
$pdf->AddPage();
$pdf->SetFont('Arial','B',16);
$pdf->Cell(0,10,utf8_decode("Nom de l'entreprise"),0,1,'C');
$pdf->SetFont('Arial','B',14);
$pdf->Cell(0,10,utf8_decode('Facture #'.$invoice['id']),0,1,'C');
$pdf->SetFont('Arial','',12);
$pdf->Cell(0,8,utf8_decode('Date : '.$invoice['invoice_date'].'   Statut : '.$invoice['status']),0,1,'C');
$pdf->Ln(5);
$pdf->SetFont('Arial','B',12);
$pdf->Cell(0,8,utf8_decode('Client : '.$invoice['client_name']),0,1);
$pdf->SetFont('Arial','',12);
$pdf->Cell(0,8,utf8_decode('Email : '.$invoice['email']),0,1);
$pdf->Cell(0,8,utf8_decode('Téléphone : '.$invoice['phone']),0,1);
$pdf->MultiCell(0,8,utf8_decode('Adresse : '.$invoice['address']));
$pdf->Ln(5);
$pdf->SetFont('Arial','B',12);
$pdf->Cell(80,8,utf8_decode('Produit'),1);
$pdf->Cell(30,8,utf8_decode('Quantité'),1);
$pdf->Cell(40,8,utf8_decode('Prix unitaire'),1);
$pdf->Cell(40,8,utf8_decode('Total'),1);
$pdf->Ln();
$pdf->SetFont('Arial','',12);
foreach ($details as $d) {
    $pdf->Cell(80,8,utf8_decode($d['name']),1);
    $pdf->Cell(30,8,$d['quantity'],1);
    $pdf->Cell(40,8,number_format($d['price'],2).' €',1);
    $pdf->Cell(40,8,number_format($d['price']*$d['quantity'],2).' €',1);
    $pdf->Ln();
}
$pdf->SetFont('Arial','B',12);
$pdf->Cell(150,8,'Total',1);
$pdf->Cell(40,8,number_format($invoice['amount'],2).' €',1);
$pdf->Ln();
$pdf->Output('I', 'Facture_'.$invoice['id'].'.pdf'); 