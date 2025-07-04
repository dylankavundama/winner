<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}
require_once '../config/db.php';

// Filtres
$date_filter = $_GET['date'] ?? '';
$month_filter = $_GET['month'] ?? '';
$year_filter = $_GET['year'] ?? '';
// New: Get the expenses from the form, default to 0 if not set or invalid
$depenses = isset($_GET['depenses']) ? floatval($_GET['depenses']) : 0;

$where = [];
$params = [];
if ($date_filter) {
    $where[] = 'DATE(s.sale_date) = ?';
    $params[] = $date_filter;
}
if ($month_filter) {
    $where[] = 'DATE_FORMAT(s.sale_date, "%Y-%m") = ?';
    $params[] = $month_filter;
}
if ($year_filter) {
    $where[] = 'YEAR(s.sale_date) = ?';
    $params[] = $year_filter;
}
$where_sql = $where ? ('WHERE ' . implode(' AND ', $where)) : '';

// Récupérer les ventes et détails
$sql = 'SELECT s.id, s.sale_date, d.product_id, d.quantity, d.price as sale_price, p.price as product_price
        FROM sales s
        JOIN sale_details d ON s.id = d.sale_id
        JOIN products p ON d.product_id = p.id
        ' . $where_sql;
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$ventes = $stmt->fetchAll();

// Calcul bénéfice
$benefice_brut = 0; // Renamed to benefice_brut (gross profit)
foreach ($ventes as $v) {
    // Bénéfice brut = (prix de vente - prix du produit) * quantité
    $benefice_brut += ($v['sale_price'] - $v['product_price']) * $v['quantity'];
}

// New: Calculate exact profit
$benefice_exact = $benefice_brut - $depenses;

?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Bénéfice</title>
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
        .benefice-box { max-width: 500px; margin: 30px auto; background: #fff; border-radius: 10px; box-shadow: 0 0 20px #0001; padding: 30px; text-align: center; }
        .benefice-value { font-size: 2.5rem; font-weight: bold; color: #28a745; }
        .depenses-input { max-width: 200px; margin: 10px auto; } /* Added style for expenses input */
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
            <a href="benefice.php" class="active"><i class="bi bi-cash-coin"></i> Bénéfice</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-cash-coin"></i> Calcul du bénéfice</span>
            </div>
            <form method="get" class="row g-2 mb-4 align-items-end">
                <div class="col-auto">
                    <label for="date" class="form-label mb-0">Par jour :</label>
                    <input type="date" id="date" name="date" class="form-control" value="<?= htmlspecialchars($date_filter) ?>">
                </div>
                <div class="col-auto">
                    <label for="month" class="form-label mb-0">Par mois :</label>
                    <input type="month" id="month" name="month" class="form-control" value="<?= htmlspecialchars($month_filter) ?>">
                </div>
                <div class="col-auto">
                    <label for="year" class="form-label mb-0">Par année :</label>
                    <input type="number" id="year" name="year" class="form-control" min="2000" max="2100" placeholder="Année" value="<?= htmlspecialchars($year_filter) ?>">
                </div>
                <div class="col-auto">
                    <label for="depenses" class="form-label mb-0">Dépenses :</label>
                    <input type="number" id="depenses" name="depenses" class="form-control" step="0.01" value="<?= htmlspecialchars($depenses) ?>" placeholder="Saisir les dépenses">
                </div>
                <div class="col-auto">
                    <button type="submit" class="btn btn-outline-primary">Filtrer et Calculer</button>
                    <a href="benefice.php" class="btn btn-outline-secondary">Réinitialiser</a>
                </div>
            </form>
            <div class="benefice-box">
                <div>Bénéfice brut pour la période sélectionnée :</div>
                <div class="benefice-value" style="color: #007bff;">
                    <?= number_format($benefice_brut, 2) ?> $
                </div>
                <div class="mt-3">Dépenses déclarées :</div>
                <div class="benefice-value" style="color: #dc3545;">
                    <?= number_format($depenses, 2) ?> $
                </div>
                <div class="mt-3">Bénéfice Exact :</div>
                <div class="benefice-value">
                    <?= number_format($benefice_exact, 2) ?> $
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