<?php
header('Content-Type: application/json');
require_once '../config/db.php';
$products = $pdo->query('SELECT * FROM products')->fetchAll();
echo json_encode(['success'=>true, 'data'=>$products]); 