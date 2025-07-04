<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}
require_once '../config/db.php';
$message = '';
// Récupérer la liste des clients et des produits
$clients = $pdo->query('SELECT id, name FROM clients')->fetchAll();
$products = $pdo->query('SELECT id, name, price, quantity FROM products')->fetchAll();

// Indexer les produits par id pour accès rapide
$product_map = [];
foreach ($products as $p) {
    $product_map[$p['id']] = $p;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $client_id = $_POST['client_id'] ?? '';
    $user_id = $_SESSION['user_id'] ?? 1;
    $product_ids = $_POST['product_id'] ?? [];
    $quantities = $_POST['quantity'] ?? [];
    $new_prices = $_POST['new_price'] ?? [];
    $imei = $_POST['imei'] ?? '';
    $garanti = $_POST['garanti'] ?? '';
    $total = 0;
    $valid = $client_id && !empty($product_ids);
    $vente = [];
    $stock_error = false;
    foreach ($product_ids as $pid) {
        $qte = 0;
        // Associer la quantité au bon produit (clé = id produit)
        if (isset($quantities[$pid])) {
            $qte = (int)$quantities[$pid];
        }
        if ($qte <= 0) $valid = false;
        if (!isset($product_map[$pid])) $valid = false;
        // Vérifier le stock
        if ($qte > $product_map[$pid]['quantity']) {
            $stock_error = true;
            $valid = false;
        }
        // Utiliser le nouveau prix saisi ou le prix par défaut
        $applied_price = isset($new_prices[$pid]) && $new_prices[$pid] !== '' ? floatval($new_prices[$pid]) : $product_map[$pid]['price'];
        if ($valid) {
            $total += $applied_price * $qte;
            $vente[] = [
                'id' => $pid,
                'qte' => $qte,
                'price' => $applied_price
            ];
        }
    }
    if ($valid && !$stock_error) {
        $pdo->beginTransaction();
        $stmt = $pdo->prepare('INSERT INTO sales (client_id, user_id, total, imei, garanti) VALUES (?, ?, ?, ?, ?)');
        $stmt->execute([$client_id, $user_id, $total, $imei, $garanti]);
        $sale_id = $pdo->lastInsertId();
        $stmt_detail = $pdo->prepare('INSERT INTO sale_details (sale_id, product_id, quantity, price) VALUES (?, ?, ?, ?)');
        foreach ($vente as $v) {
            $stmt_detail->execute([$sale_id, $v['id'], $v['qte'], $v['price']]);
            // Mettre à jour le stock
            $pdo->prepare('UPDATE products SET quantity = quantity - ? WHERE id = ?')->execute([$v['qte'], $v['id']]);
        }
        $pdo->commit();
        $message = 'Vente enregistrée avec succès!';
    } else if ($stock_error) {
        $message = 'Stock insuffisant pour au moins un produit.';
    } else {
        $message = 'Veuillez remplir tous les champs et sélectionner au moins un produit avec une quantité valide.';
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ajouter une vente</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="../assets/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { background: #f5f6fa; }
        .sidebar { min-height: 100vh; background: #222e3c; color: #fff; }
        .sidebar a { color: #fff; text-decoration: none; display: block; padding: 12px 20px; border-radius: 4px; }
        .sidebar a.active, .sidebar a:hover { background: #1a2230; }
        .sidebar .logo { font-size: 1.5rem; font-weight: bold; padding: 24px 20px 16px 20px; text-align: center; }
        .sidebar .user { text-align: center; margin-bottom: 20px; }
        .sidebar .user i { font-size: 2rem; }
        .topbar { background: #fff; border-bottom: 1px solid #eee; padding: 12px 24px; display: flex; align-items: center; justify-content: space-between; }
        .form-card { max-width: 600px; margin: 40px auto; }
        .table-responsive { overflow-x: auto; }
        @media (max-width: 900px) {
            .sidebar { min-height: auto; position: fixed; left: -220px; top: 0; width: 200px; z-index: 1050; transition: left 0.3s; }
            .sidebar.open { left: 0; }
            .sidebar .logo { font-size: 1.2rem; }
            .main-overlay { display: none; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: #0005; z-index: 1040; }
            .main-overlay.active { display: block; }
            main { padding-left: 0 !important; }
            .topbar { flex-direction: column; align-items: flex-start; gap: 10px; }
            .form-card { margin: 20px 5px; }
        }
    </style>
</head>
<body>
<div class="main-overlay" id="mainOverlay" onclick="toggleSidebar(false)"></div>
<div class="container-fluid">
    <div class="row">
        <button class="btn btn-dark d-md-none m-2" onclick="toggleSidebar(true)"><i class="bi bi-list"></i></button>
        <nav class="col-md-2 d-none d-md-block sidebar" id="sidebarMenu">
            <div class="logo mb-3">
                <img src="../assets/logo.png" alt="Logo" style="max-width:40px;vertical-align:middle;"> <span>WINNER</span>
            </div>
            <div class="user mb-3">
                <i class="bi bi-person-circle"></i><br>
                <span><?= htmlspecialchars($_SESSION['username']) ?></span>
            </div>
            <a href="dashboard.php"><i class="bi bi-speedometer2"></i> Dashboard</a>
            <a href="products.php"><i class="bi bi-box"></i> Produits</a>
            <a href="sales.php" class="active"><i class="bi bi-cart"></i> Ventes</a>
            <a href="invoices.php"><i class="bi bi-receipt"></i> Factures</a>
            <a href="clients.php"><i class="bi bi-people"></i> Clients</a>
            <a href="reports.php"><i class="bi bi-bar-chart"></i> Rapports</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-cart"></i> Ajouter une vente</span>
                <a href="sales.php" class="btn btn-outline-secondary btn-add"><i class="bi bi-arrow-left"></i> Retour</a>
            </div>
            <div class="card form-card">
                <div class="card-body">
                    <?php if ($message): ?>
                        <div class="alert alert-info text-center"> <?= htmlspecialchars($message) ?> </div>
                    <?php endif; ?>
                    <form method="post">
                        <div class="mb-3">
                            <label class="form-label">Client</label>
                            <select name="client_id" class="form-select" required>
                                <option value="">-- Sélectionner --</option>
                                <?php foreach ($clients as $client): ?>
                                    <option value="<?= $client['id'] ?>"><?= htmlspecialchars($client['name']) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Adresse IMEI de l'appareil</label>
                            <input type="text" name="imei" class="form-control" placeholder="Saisir l'adresse IMEI" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Garantie</label>
                            <input type="text" name="garanti" class="form-control" placeholder="Ex: 6 mois, 1 an...">
                        </div>
                        <fieldset class="mb-3">
                            <legend>Produits</legend>
                            <div class="table-responsive">
                                <table class="table table-bordered align-middle">
                                    <thead>
                                        <tr>
                                            <th>Sélection</th>
                                            <th>Produit</th>
                                            <th>Prix actuel</th>
                                            <th>Prix de vente</th>
                                            <th>Stock</th>
                                            <th>Quantité</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                    <?php foreach ($products as $product): ?>
                                        <tr>
                                            <td><input class="form-check-input" type="checkbox" name="product_id[]" value="<?= $product['id'] ?>" id="prod<?= $product['id'] ?>"></td>
                                            <td><label for="prod<?= $product['id'] ?>"><?= htmlspecialchars($product['name']) ?></label></td>
                                            <td><?= $product['price'] ?> $</td>
                                            <td><input type="number" step="0.01" min="0" name="new_price[<?= $product['id'] ?>]" class="form-control" value="<?= $product['price'] ?>" style="width:110px;" placeholder="Prix de vente"></td>
                                            <td><?= $product['quantity'] ?></td>
                                            <td><input type="number" name="quantity[<?= $product['id'] ?>]" min="1" max="<?= $product['quantity'] ?>" class="form-control" style="width:90px;" placeholder="Qté"></td>
                                        </tr>
                                    <?php endforeach; ?>
                                    </tbody>
                                </table>
                            </div>
                        </fieldset>
                        <button type="submit" class="btn btn-primary w-100">Enregistrer la vente</button>
                    </form>
                </div>
            </div>
        </main>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
function toggleSidebar(open) {
    const sidebar = document.getElementById('sidebarMenu');
    const overlay = document.getElementById('mainOverlay');
    if (open) {
        sidebar.classList.add('open');
        overlay.classList.add('active');
        sidebar.classList.remove('d-none');
    } else {
        sidebar.classList.remove('open');
        overlay.classList.remove('active');
        setTimeout(()=>sidebar.classList.add('d-none'), 300);
    }
}
document.querySelectorAll('#sidebarMenu a').forEach(a => {
    a.addEventListener('click', () => toggleSidebar(false));
});
</script>
</body>
</html> 