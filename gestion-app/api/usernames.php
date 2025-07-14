<?php
require_once '../config/db.php';
header('Content-Type: application/json');
$users = $pdo->query('SELECT username FROM users ORDER BY username')->fetchAll(PDO::FETCH_COLUMN);
echo json_encode($users); 