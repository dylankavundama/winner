<?php
// reports.php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}
require_once '../config/db.php';

// Rapport des ventes par période
$start = $_GET['start'] ?? date('Y-m-01');
$end = $_GET['end'] ?? date('Y-m-d');
$stmt = $pdo->prepare('SELECT s.id, c.name AS client, s.sale_date, s.total FROM sales s INNER JOIN clients c ON s.client_id = c.id WHERE s.sale_date BETWEEN ? AND ? ORDER BY s.sale_date DESC');
$stmt->execute([$start . ' 00:00:00', $end . ' 23:59:59']);
$sales = $stmt->fetchAll();

// Rapport du stock faible
$low_stock = $pdo->query('SELECT * FROM products WHERE quantity <= 5 ORDER BY quantity ASC')->fetchAll();

// Rapport des meilleurs clients (top 5)
$top_clients = $pdo->query('SELECT c.name, SUM(s.total) as total_achats FROM sales s INNER JOIN clients c ON s.client_id = c.id GROUP BY c.id ORDER BY total_achats DESC LIMIT 5')->fetchAll();

// Rapport des factures impayées
$unpaid = $pdo->query("SELECT i.id, c.name AS client, i.amount, i.invoice_date FROM invoices i INNER JOIN sales s ON i.sale_id = s.id INNER JOIN clients c ON s.client_id = c.id WHERE i.status = 'impayée' ORDER BY i.invoice_date DESC")->fetchAll();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Rapports</title>
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
        .report-section { margin-bottom: 40px; }
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
            <a href="reports.php" class="active"><i class="bi bi-bar-chart"></i> Rapports</a>
            <a href="stock.php"><i class="bi bi-archive"></i> Stock</a>
            <a href="benefice.php"><i class="bi bi-cash-coin"></i> Bénéfice</a>
            <a href="sortie.php"><i class="bi bi-arrow-down-circle"></i> Sorties</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-bar-chart"></i> Rapports</span>
                <button onclick="window.print()" class="btn btn-outline-success"><i class="bi bi-printer"></i> Imprimer le rapport</button>
            </div>
            <div class="report-section">
                <h2>Rapport des ventes par période</h2>
                <form method="get" class="row g-2 align-items-end mb-3">
                    <div class="col-auto">
                        <label class="form-label">Du</label>
                        <input type="date" name="start" value="<?= htmlspecialchars($start) ?>" class="form-control">
                    </div>
                    <div class="col-auto">
                        <label class="form-label">Au</label>
                        <input type="date" name="end" value="<?= htmlspecialchars($end) ?>" class="form-control">
                    </div>
                    <div class="col-auto">
                        <button type="submit" class="btn btn-primary">Filtrer</button>
                    </div>
                </form>
                <div class="card">
                    <div class="card-body">
                        <table class="table table-hover align-middle">
                            <thead><tr><th>ID</th><th>Client</th><th>Date</th><th>Total</th></tr></thead>
                            <tbody>
                            <?php foreach ($sales as $s): ?>
                            <tr>
                                <td><?= $s['id'] ?></td>
                                <td><?= htmlspecialchars($s['client']) ?></td>
                                <td><?= $s['sale_date'] ?></td>
                                <td><?= number_format($s['total'],2) ?> $</td>
                            </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class="report-section">
                <h2>Produits en stock faible (&le; 5)</h2>
                <div class="card">
                    <div class="card-body">
                        <table class="table table-hover align-middle">
                            <thead><tr><th>ID</th><th>Nom</th><th>Quantité</th><th>Prix</th></tr></thead>
                            <tbody>
                            <?php foreach ($low_stock as $p): ?>
                            <tr>
                                <td><?= $p['id'] ?></td>
                                <td><?= htmlspecialchars($p['name']) ?></td>
                                <td><?= $p['quantity'] ?></td>
                                <td><?= number_format($p['price'],2) ?> $</td>
                            </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class="report-section">
                <h2>Top 5 des meilleurs clients</h2>
                <div class="card">
                    <div class="card-body">
                        <table class="table table-hover align-middle">
                            <thead><tr><th>Client</th><th>Total achats</th></tr></thead>
                            <tbody>
                            <?php foreach ($top_clients as $c): ?>
                            <tr>
                                <td><?= htmlspecialchars($c['name']) ?></td>
                                <td><?= number_format($c['total_achats'],2) ?> $</td>
                            </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class="report-section">
                <h2>Factures impayées</h2>
                <div class="card">
                    <div class="card-body">
                        <table class="table table-hover align-middle">
                            <thead><tr><th>ID</th><th>Client</th><th>Date</th><th>Montant</th></tr></thead>
                            <tbody>
                            <?php foreach ($unpaid as $f): ?>
                            <tr>
                                <td><?= $f['id'] ?></td>
                                <td><?= htmlspecialchars($f['client']) ?></td>
                                <td><?= $f['invoice_date'] ?></td>
                                <td><?= number_format($f['amount'],2) ?> $</td>
                            </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
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