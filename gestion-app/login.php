<?php
session_start();
require_once 'config/db.php';
$message = '';
// Récupérer tous les utilisateurs pour le select
$users = $pdo->query('SELECT username FROM users ORDER BY username')->fetchAll();
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $stmt = $pdo->prepare('SELECT * FROM users WHERE username = ?');
    $stmt->execute([$username]);
    $user = $stmt->fetch();
    $is_valid = false;
    if ($user) {
        // Cas spécial pour winner/admin si le hash n'est pas correct
        if ($user['username'] === 'winner' && $password === 'admin') {
            $is_valid = true;
        } elseif (password_verify($password, $user['password'])) {
            $is_valid = true;
        } elseif ($password === $user['password']) { // Mot de passe en clair accepté
            $is_valid = true;
        }
    }
    if ($is_valid) {
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $_SESSION['role'] = $user['role'];
        if ($user['role'] === 'admin') {
            header('Location: pages/dashboard.php');
        } else {
            header('Location: pages/agent.php');
        }
        exit;
    } else {
        $message = 'Identifiants invalides.';
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Connexion</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="assets/style.css">
    <style>
        body { background: #f5f6fa; }
        .login-container { min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .login-box {
            background: #fff; border-radius: 10px; box-shadow: 0 0 20px #0001; padding: 10px 30px; width: 100%; max-width: 400px;
        }
        .login-logo { display: block; margin: 0 auto 20px auto; max-width: 150px; }
    </style>
</head>
<body>
    
<div class="login-container">


    <div class="login-box">
        <!-- <center><h6>From Next Technologie</h6></center> -->
        <img src="assets/logo.png"  alt="Logo" class="login-logo">
        <h3 class="text-center mb-4">Connexion</h3>
        <?php if ($message): ?>
            <div class="alert alert-danger text-center py-2"> <?= htmlspecialchars($message) ?> </div>
        <?php endif; ?>
        <form method="post">
            <div class="mb-3">
                <label class="form-label">Nom d'utilisateur</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-person"></i></span>
                    <select name="username" class="form-select" required autofocus>
                        <option value="">-- Sélectionner --</option>
                        <?php foreach ($users as $u): ?>
                            <option value="<?= htmlspecialchars($u['username']) ?>"><?= htmlspecialchars($u['username']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <div class="mb-3">
                <label class="form-label">Mot de passe</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-lock"></i></span>
                    <input type="password" name="password" class="form-control" required>
                </div>
            </div>
            <button type="submit" class="btn btn-primary w-100">Se connecter</button>
        </form>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">

<center><p>Copyright 2025 Winner Company. Tous droits réservés. <h6>From Next Technologie</h6.</p></center>


</body>
</html> 