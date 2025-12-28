<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}
require_once '../config/db.php';

$clientId = isset($_GET['client_id']) ? (int)$_GET['client_id'] : 0;

// Récupérer la liste des clients pour le filtre
$clients = $pdo->query('SELECT id, name FROM clients ORDER BY name')->fetchAll();

// Récupérer les dépôts (optionnellement filtrés par client) - exclure les dépôts utilisés
if ($clientId > 0) {
    $stmt = $pdo->prepare(
        'SELECT d.*, c.name AS client_name, p.name AS product_name
         FROM deposits d
         LEFT JOIN clients c ON d.client_id = c.id
         LEFT JOIN products p ON d.product_id = p.id
         WHERE d.client_id = :client_id AND d.sale_id IS NULL
         ORDER BY d.deposit_date DESC, d.id DESC'
    );
    $stmt->execute([':client_id' => $clientId]);
} else {
    $stmt = $pdo->query(
        'SELECT d.*, c.name AS client_name, p.name AS product_name
         FROM deposits d
         LEFT JOIN clients c ON d.client_id = c.id
         LEFT JOIN products p ON d.product_id = p.id
         WHERE d.sale_id IS NULL
         ORDER BY d.deposit_date DESC, d.id DESC'
    );
}
$deposits = $stmt->fetchAll();

// Calculer le total des montants pour l'affichage
$totalDeposits = 0.0;
foreach ($deposits as $d) {
    $totalDeposits += (float)$d['amount'];
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Historique des dépôts</title>
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
        .table thead { background: #007bff; color: #fff; }
        .table-responsive { overflow-x: auto; }
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
            <a href="reports.php"><i class="bi bi-bar-chart"></i> Rapports</a>
            <a href="stock.php"><i class="bi bi-archive"></i> Stock</a>
            <a href="deposits.php" class="active"><i class="bi bi-piggy-bank"></i> Deposits</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-piggy-bank"></i> Historique des dépôts</span>
                <form method="get" class="d-flex align-items-center gap-2">
                    <select name="client_id" class="form-select">
                        <option value="0">Tous les clients</option>
                        <?php foreach ($clients as $client): ?>
                            <option value="<?= $client['id'] ?>" <?= $clientId === (int)$client['id'] ? 'selected' : '' ?>>
                                <?= htmlspecialchars($client['name']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                    <button type="submit" class="btn btn-outline-primary btn-sm">Filtrer</button>
                    <a href="deposits.php" class="btn btn-outline-secondary btn-sm">Réinitialiser</a>
                    <a href="add_deposit.php" class="btn btn-primary btn-sm">
                        <i class="bi bi-plus"></i> Ajouter un deposit
                    </a>
                </form>
            </div>
            <div class="mb-3">
                <div class="alert alert-info py-2 mb-0">
                    Total dépôts pour cette sélection : <strong><?= number_format($totalDeposits, 2) ?> $</strong>
                </div>
            </div>
            <div class="card">
                <div class="card-body table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Client</th>
                            <th>Produit</th>
                            <th>Montant</th>
                            <th>Date</th>
                            <th>Stock</th>
                        </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($deposits as $deposit): ?>
                            <tr>
                                <td><?= $deposit['id'] ?></td>
                                <td><?= htmlspecialchars($deposit['client_name'] ?? '') ?></td>
                                <td><?= htmlspecialchars($deposit['product_name'] ?? '') ?></td>
                                <td><?= number_format($deposit['amount'], 2) ?> $</td>
                                <td><?= htmlspecialchars($deposit['deposit_date']) ?></td>
                                <td>
                                    <?php if ((int)$deposit['stock_reserved'] === 1): ?>
                                        <span class="badge bg-success">Réservé</span>
                                    <?php else: ?>
                                        <span class="badge bg-warning text-dark">Produit hors stock</span>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
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


