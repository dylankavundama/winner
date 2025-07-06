<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}
require_once '../config/db.php';
// Récupérer quelques stats pour le dashboard
$total_clients = $pdo->query('SELECT COUNT(*) FROM clients')->fetchColumn();
$total_products = $pdo->query('SELECT COUNT(*) FROM products')->fetchColumn();
$total_sales = $pdo->query('SELECT COUNT(*) FROM sales')->fetchColumn();
$total_invoices = $pdo->query('SELECT COUNT(*) FROM invoices')->fetchColumn();
$total_sales_amount = $pdo->query('SELECT IFNULL(SUM(total),0) FROM sales')->fetchColumn();
$total_chiffre_affaire = $pdo->query('SELECT IFNULL(SUM(quantity * price),0) FROM products')->fetchColumn();
// Pour le graphique : ventes par mois
$chart_data = $pdo->query("SELECT DATE_FORMAT(sale_date, '%b') as month, SUM(total) as total FROM sales GROUP BY month ORDER BY MIN(sale_date)")->fetchAll();
$months = [];
$totals = [];
foreach ($chart_data as $row) {
    $months[] = $row['month'];
    $totals[] = $row['total'];
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Dashboard - Gestion des ventes</title>
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
        .dashboard-cards { display: flex; flex-wrap: wrap; gap: 20px; margin-bottom: 30px; }
        .dashboard-card { flex: 1 1 200px; min-width: 200px; background: #fff; border-radius: 10px; box-shadow: 0 0 10px #0001; padding: 24px; display: flex; align-items: center; gap: 16px; }
        .dashboard-card .icon { font-size: 2.2rem; }
        .dashboard-card.bg-primary { background: #007bff; color: #fff; }
        .dashboard-card.bg-success { background: #28a745; color: #fff; }
        .dashboard-card.bg-warning { background: #ffc107; color: #222; }
        .dashboard-card.bg-danger { background: #dc3545; color: #fff; }
        .dashboard-card.bg-info { background: #17a2b8; color: #fff; }
        .dashboard-card.bg-secondary { background: #6c757d; color: #fff; }
        .dashboard-card .value { font-size: 1.6rem; font-weight: bold; }
        .dashboard-card .label { font-size: 1rem; }
        .table-responsive { overflow-x: auto; }
        @media (max-width: 900px) {
            .sidebar { min-height: auto; position: fixed; left: -220px; top: 0; width: 200px; z-index: 1050; transition: left 0.3s; }
            .sidebar.open { left: 0; }
            .sidebar .logo { font-size: 1.2rem; }
            .main-overlay { display: none; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: #0005; z-index: 1040; }
            .main-overlay.active { display: block; }
            main { padding-left: 0 !important; }
            .topbar { flex-direction: column; align-items: flex-start; gap: 10px; }
            .dashboard-cards { flex-direction: column; }
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
                <img src="../assets/logo.png" alt="Logo" style="max-width:40px;vertical-align:middle;"> <span>W-P</span>
            </div>
            <div class="user mb-3">
                <i class="bi bi-person-circle"></i><br>
                <span><?= htmlspecialchars($_SESSION['username']) ?></span>
            </div>
            <a href="dashboard.php" class="active"><i class="bi bi-speedometer2"></i> Dashboard</a>
            <a href="products.php"><i class="bi bi-box"></i> Produits</a>
            <a href="sales.php"><i class="bi bi-cart"></i> Ventes</a>
            <a href="invoices.php"><i class="bi bi-receipt"></i> Factures</a>
            <a href="clients.php"><i class="bi bi-people"></i> Clients</a>
            <a href="reports.php"><i class="bi bi-bar-chart"></i> Rapports</a>
            <a href="stock.php"><i class="bi bi-archive"></i> Stock</a>
            <a href="benefice.php"><i class="bi bi-cash-coin"></i> Bénéfice</a>
            <a href="sortie.php"><i class="bi bi-arrow-down-circle"></i> Sorties</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-house"></i> Dashboard</span>
                <span><?= date('d/m/Y') ?></span>
            </div>
            <div class="dashboard-cards mb-4">
                <div class="dashboard-card bg-primary">
                    <span class="icon"><i class="bi bi-people"></i></span>
                    <div>
                        <div class="value"><?= $total_clients ?></div>
                        <div class="label">Clients</div>
                    </div>
                </div>
                <div class="dashboard-card bg-success">
                    <span class="icon"><i class="bi bi-box"></i></span>
                    <div>
                        <div class="value"><?= $total_products ?></div>
                        <div class="label">Produits</div>
                    </div>
                </div>
                <div class="dashboard-card bg-info">
                    <span class="icon"><i class="bi bi-cart"></i></span>
                    <div>
                        <div class="value"><?= $total_sales ?></div>
                        <div class="label">Ventes</div>
                    </div>
                </div>
                <div class="dashboard-card bg-warning">
                    <span class="icon"><i class="bi bi-receipt"></i></span>
                    <div>
                        <div class="value"><?= $total_invoices ?></div>
                        <div class="label">Factures</div>
                    </div>
                </div>
                <div class="dashboard-card bg-success">
                    <span class="icon"><i class="bi bi-currency-dollar"></i></span>
                    <div>
                        <div class="value"><?= number_format($total_sales_amount,2) ?> $</div>
                        <div class="label">Total ventes</div>
                    </div>
                </div>
                <div class="dashboard-card bg-danger">
                    <span class="icon"><i class="bi bi-cash-stack"></i></span>
                    <div>
                        <div class="value"><?= number_format($total_chiffre_affaire,2) ?> $</div>
                        <div class="label">Chiffre d'affaire</div>
                    </div>
                </div>
            </div>
            <div class="card mb-4">
                <div class="card-header bg-white"><b>Ventes par mois</b></div>
                <div class="card-body table-responsive">
                    <canvas id="salesChart" height="80"></canvas>
                </div>
            </div>
        </main>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.3.0/dist/chart.umd.min.js"></script>
<script>
const ctx = document.getElementById('salesChart').getContext('2d');
const salesChart = new Chart(ctx, {
    type: 'bar',
    data: {
        labels: <?= json_encode($months) ?>,
        datasets: [{
            label: 'Ventes ($)',
            data: <?= json_encode($totals) ?>,
            backgroundColor: '#007bff',
        }]
    },
    options: {
        responsive: true,
        plugins: { legend: { display: false } }
    }
});

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