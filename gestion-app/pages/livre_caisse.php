<?php
require_once '../config/db.php';

// Traitement du formulaire d'ajout
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $numero_recu = $_POST['numero_recu'];
    $date = $_POST['date'];
    $designation = $_POST['designation'];
    $entree = floatval($_POST['entree']);
    $depense = floatval($_POST['depense']);

    $stmt = $pdo->prepare("INSERT INTO caisse (numero_recu, date, designation, entree, depense) VALUES (?, ?, ?, ?, ?)");
    $stmt->execute([$numero_recu, $date, $designation, $entree, $depense]);
}

// Récupération des mouvements de caisse
$stmt = $pdo->query("SELECT * FROM caisse ORDER BY date, id");
$mouvements = $stmt->fetchAll();

// Calcul du solde initial
$solde = 0;
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Livre de caisse</title>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #333; padding: 6px; text-align: center; }
        th { background: #eee; }
        .form-section { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h2>Livre de caisse</h2>
    <div class="form-section">
        <form method="post">
            <label>Numéro de reçu : <input type="text" name="numero_recu" required></label>
            <label>Date : <input type="date" name="date" required></label>
            <label>Désignation : <input type="text" name="designation" required></label>
            <label>Entrée (€) : <input type="number" step="0.01" name="entree" value="0"></label>
            <label>Dépense (€) : <input type="number" step="0.01" name="depense" value="0"></label>
            <button type="submit">Ajouter</button>
        </form>
    </div>
    <table>
        <thead>
            <tr>
                <th>Numéro de reçu</th>
                <th>Date</th>
                <th>Désignation</th>
                <th>Entrées en euros</th>
                <th>Dépenses en euros</th>
                <th>Solde</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($mouvements as $mvt): ?>
                <?php
                    $solde += floatval($mvt['entree']) - floatval($mvt['depense']);
                ?>
                <tr>
                    <td><?= htmlspecialchars($mvt['numero_recu']) ?></td>
                    <td><?= htmlspecialchars($mvt['date']) ?></td>
                    <td><?= htmlspecialchars($mvt['designation']) ?></td>
                    <td><?= number_format($mvt['entree'], 2, ',', ' ') ?> €</td>
                    <td><?= number_format($mvt['depense'], 2, ',', ' ') ?> €</td>
                    <td><?= number_format($solde, 2, ',', ' ') ?> €</td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html> 