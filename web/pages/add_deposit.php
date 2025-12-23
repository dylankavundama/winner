<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}

require_once '../config/db.php';

$success_message = '';
$error_message = '';

// Charger les clients et produits pour le formulaire
$clients = $pdo->query('SELECT id, name FROM clients ORDER BY name')->fetchAll();
$products = $pdo->query('SELECT id, name, prix_vente, quantity FROM products ORDER BY name')->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $clientId = isset($_POST['client_id']) ? (int)$_POST['client_id'] : 0;
    $productId = isset($_POST['product_id']) ? (int)$_POST['product_id'] : 0;
    $amount = isset($_POST['amount']) ? (float)str_replace(',', '.', $_POST['amount']) : 0;
    $depositDate = !empty($_POST['deposit_date']) ? $_POST['deposit_date'] : date('Y-m-d');

    if ($clientId <= 0 || $productId <= 0 || $amount <= 0) {
        $error_message = "Veuillez sélectionner un client, un produit et saisir un montant valide.";
    } else {
        try {
            // Vérifier le stock du produit
            $stmt = $pdo->prepare('SELECT quantity FROM products WHERE id = :id');
            $stmt->execute([':id' => $productId]);
            $product = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$product) {
                $error_message = "Produit introuvable.";
            } else {
                $quantity = (int)$product['quantity'];
                $stockReserved = 0;
                $message = '';

                $pdo->beginTransaction();

                if ($quantity > 0) {
                    // Réserver 1 unité du produit (sortir du stock)
                    $update = $pdo->prepare(
                        'UPDATE products SET quantity = quantity - 1 WHERE id = :id AND quantity > 0'
                    );
                    $update->execute([':id' => $productId]);

                    if ($update->rowCount() > 0) {
                        $stockReserved = 1;
                        $message = 'Dépôt enregistré et produit réservé (retiré du stock).';
                    } else {
                        $message = 'Dépôt enregistré, mais le produit est maintenant en rupture de stock.';
                    }
                } else {
                    $message = 'Dépôt enregistré, mais le produit est actuellement hors stock.';
                }

                // Enregistrer le dépôt
                $insert = $pdo->prepare(
                    'INSERT INTO deposits (client_id, product_id, amount, deposit_date, stock_reserved)
                     VALUES (:client_id, :product_id, :amount, :deposit_date, :stock_reserved)'
                );
                $insert->execute([
                    ':client_id' => $clientId,
                    ':product_id' => $productId,
                    ':amount' => $amount,
                    ':deposit_date' => $depositDate,
                    ':stock_reserved' => $stockReserved,
                ]);

                $pdo->commit();
                $success_message = $message;
            }
        } catch (PDOException $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            $error_message = "Erreur lors de l'enregistrement du dépôt : " . $e->getMessage();
        }
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ajouter un deposit</title>
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
        @media (max-width: 900px) {
            .sidebar { min-height: auto; position: fixed; left: -220px; top: 0; width: 200px; z-index: 1050; transition: left 0.3s; }
            .sidebar.open { left: 0; }
            .sidebar .logo { font-size: 1.2rem; }
            .main-overlay { display: none; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: #0005; z-index: 1040; }
            .main-overlay.active { display: block; }
            main { padding-left: 0 !important; }
            .topbar { flex-direction: column; align-items: flex-start; gap: 10px; }
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
            <a href="sales.php"><i class="bi bi-cart"></i> Ventes</a>
            <a href="invoices.php"><i class="bi bi-receipt"></i> Factures</a>
            <a href="clients.php"><i class="bi bi-people"></i> Clients</a>
            <a href="deposits.php" class="active"><i class="bi bi-piggy-bank"></i> Deposits</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-piggy-bank"></i> Ajouter un deposit</span>
                <a href="deposits.php" class="btn btn-outline-secondary btn-sm">
                    <i class="bi bi-arrow-left"></i> Retour à l'historique
                </a>
            </div>

            <?php if ($success_message): ?>
                <div class="alert alert-success"><?= htmlspecialchars($success_message) ?></div>
            <?php endif; ?>
            <?php if ($error_message): ?>
                <div class="alert alert-danger"><?= htmlspecialchars($error_message) ?></div>
            <?php endif; ?>

            <div class="card">
                <div class="card-body">
                    <form method="post">
                        <div class="mb-3">
                            <label class="form-label">Client</label>
                            <select name="client_id" class="form-select" required>
                                <option value="">-- Sélectionner un client --</option>
                                <?php foreach ($clients as $client): ?>
                                    <option value="<?= $client['id'] ?>">
                                        <?= htmlspecialchars($client['name']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Produit</label>
                            <select name="product_id" class="form-select" required>
                                <option value="">-- Sélectionner un produit --</option>
                                <?php foreach ($products as $product): ?>
                                    <option value="<?= $product['id'] ?>">
                                        <?= htmlspecialchars($product['name']) ?>
                                        (<?= number_format($product['prix_vente'], 2) ?> $,
                                        stock: <?= (int)$product['quantity'] ?>)
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Montant du deposit</label>
                            <div class="input-group">
                                <span class="input-group-text">$</span>
                                <input type="number" step="0.01" min="0" name="amount" class="form-control" required>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Date du deposit</label>
                            <input type="date" name="deposit_date" class="form-control"
                                   value="<?= date('Y-m-d') ?>">
                        </div>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-save"></i> Enregistrer
                        </button>
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


