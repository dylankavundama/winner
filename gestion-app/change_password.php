<?php 
session_start();
require_once 'config/db.php';

$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $current_password = $_POST['password'] ?? '';
    $new_password = $_POST['new_password'] ?? '';

    // Vérifier si l'utilisateur existe
    $stmt = $pdo->prepare('SELECT password FROM users WHERE username = ?');
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    if ($user) {
        $db_password = $user['password'];

        // Vérification mot de passe actuel (hashé OU en clair)
        if (password_verify($current_password, $db_password) || $current_password === $db_password) {
            
            // Vérifier longueur du nouveau mot de passe
            if (strlen($new_password) >= 4) {
                $hashed_password = password_hash($new_password, PASSWORD_DEFAULT);

                $update = $pdo->prepare('UPDATE users SET password = ? WHERE username = ?');
                if ($update->execute([$hashed_password, $username])) {
                    // ✅ Redirection vers login.php après succès
                    header("Location: login.php?success=1");
                    exit;
                } else {
                    $message = '❌ Erreur lors de la mise à jour.';
                }
            } else {
                $message = '⚠️ Le nouveau mot de passe doit contenir au moins 4 caractères.';
            }

        } else {
            $message = '❌ Nom d\'utilisateur ou mot de passe actuel incorrect.';
        }
    } else {
        $message = '❌ Nom d\'utilisateur ou mot de passe actuel incorrect.';
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Modifier le mot de passe</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .password-container {
            position: relative;
        }
        .toggle-password {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            cursor: pointer;
            font-size: 14px;
            color: #007bff;
        }
    </style>
</head>
<body>
<div class="container mt-5">
    <h2>Modifier le mot de passe</h2>
    <?php if ($message): ?>
        <div class="alert alert-info"><?= htmlspecialchars($message) ?></div>
    <?php endif; ?>
    <form method="post">
        <div class="mb-3">
            <label class="form-label">Nom d'utilisateur</label>
            <input type="text" class="form-control" name="username" required>
        </div>
        <div class="mb-3 password-container">
            <label class="form-label">Mot de passe actuel</label>
            <input type="password" class="form-control" name="password" id="password" required>
            <span class="toggle-password" onclick="togglePassword('password')">👁️</span>
        </div>
        <div class="mb-3 password-container">
            <label class="form-label">Nouveau mot de passe</label>
            <input type="password" class="form-control" name="new_password" id="new_password" required>
            <span class="toggle-password" onclick="togglePassword('new_password')">👁️</span>
        </div>
        <button type="submit" class="btn btn-primary">Modifier</button>
    </form>
</div>

<script>
function togglePassword(id) {
    const input = document.getElementById(id);
    if (input.type === "password") {
        input.type = "text";
    } else {
        input.type = "password";
    }
}
</script>
</body>
</html>
