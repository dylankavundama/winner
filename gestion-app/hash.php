<?php
// Script temporaire pour générer un hash de mot de passe
$password = 'admin'; // Changez ici si besoin
echo 'Mot de passe : ' . htmlspecialchars($password) . '<br>Hash : <br><textarea style="width:100%" rows="2">' . password_hash($password, PASSWORD_DEFAULT) . '</textarea>'; 