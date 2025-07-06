<?php
header('Content-Type: application/json');
require_once '../config/db.php';
$input = json_decode(file_get_contents('php://input'), true);
$username = $input['username'] ?? '';
$password = $input['password'] ?? '';
if (!$username || !$password) {
    echo json_encode(['success'=>false, 'error'=>'Champs manquants']);
    exit;
}
$stmt = $pdo->prepare('SELECT * FROM users WHERE username = ?');
$stmt->execute([$username]);
$user = $stmt->fetch();
if ($user && password_verify($password, $user['password'])) {
    echo json_encode(['success'=>true, 'user'=>[
        'id'=>$user['id'],
        'username'=>$user['username'],
        'role'=>$user['role']
    ]]);
} else {
    echo json_encode(['success'=>false, 'error'=>'Identifiants invalides']);
} 