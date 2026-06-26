<?php
if (!is_dir(ini_get('session.save_path')) || !is_writable(ini_get('session.save_path'))) {
    session_save_path(sys_get_temp_dir());
}
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

// Récupérer les ventes avec bénéfice calculé par vente
$sql = 'SELECT 
            s.id as sale_id,
            s.sale_date,
            s.total as sale_total,
            c.name as client_name,
            SUM((d.price - p.price) * d.quantity) as benefice_vente,
            SUM(d.price * d.quantity) as chiffre_affaire_vente
        FROM sales s
        LEFT JOIN clients c ON s.client_id = c.id
        JOIN sale_details d ON s.id = d.sale_id
        JOIN products p ON d.product_id = p.id
        ' . $where_sql . '
        GROUP BY s.id, s.sale_date, s.total, c.name
        ORDER BY s.sale_date DESC, s.id DESC';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$ventes_detail = $stmt->fetchAll();

// Calcul bénéfice total
$benefice_brut = 0;
$total_ventes = 0;
foreach ($ventes_detail as $v) {
    $benefice_brut += (float)$v['benefice_vente'];
    $total_ventes += (float)$v['sale_total'];
}

// New: Calculate exact profit
$benefice_exact = $benefice_brut - $depenses;

// Récupérer les sorties de type 'normal' sur la même période
$depenses = 0;
$sortie_where = [];
$sortie_params = [];
if ($date_filter) {
    $sortie_where[] = 'DATE(date_sortie) = ?';
    $sortie_params[] = $date_filter;
}
if ($month_filter) {
    $sortie_where[] = 'DATE_FORMAT(date_sortie, "%Y-%m") = ?';
    $sortie_params[] = $month_filter;
}
if ($year_filter) {
    $sortie_where[] = 'YEAR(date_sortie) = ?';
    $sortie_params[] = $year_filter;
}
$sortie_where[] = 'type = ?';
$sortie_params[] = 'normal';
$sortie_sql = 'SELECT SUM(montant) as total FROM sorties ' . ($sortie_where ? ('WHERE ' . implode(' AND ', $sortie_where)) : '');
$stmt_sortie = $pdo->prepare($sortie_sql);
$stmt_sortie->execute($sortie_params);
$depenses = $stmt_sortie->fetchColumn() ?: 0;

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
            <a href="chiffre_affaire.php"><i class="bi bi-cash-stack"></i> Chiffre d'affaire</a>
            <a href="stock.php"><i class="bi bi-archive"></i> Stock</a>
            <a href="benefice.php" class="active"><i class="bi bi-cash-coin"></i> Bénéfice</a>
            <a href="livre_caisse.php"><i class="bi bi-journal-richtext"></i> Livre de caisse</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-cash-coin"></i> Calcul du bénéfice</span>
            </div>
            <div class="card mb-4">
                <div class="card-body">
                    <form method="get" class="row g-3 align-items-end">
                        <div class="col-md-3">
                            <label for="date" class="form-label">Filtrer par jour :</label>
                            <input type="date" id="date" name="date" class="form-control" value="<?= htmlspecialchars($date_filter) ?>" onchange="clearOtherFilters('date')">
                        </div>
                        <div class="col-md-3">
                            <label for="month" class="form-label">Filtrer par mois :</label>
                            <input type="month" id="month" name="month" class="form-control" value="<?= htmlspecialchars($month_filter) ?>" onchange="clearOtherFilters('month')">
                        </div>
                        <div class="col-md-3">
                            <label for="year" class="form-label">Filtrer par année :</label>
                            <input type="number" id="year" name="year" class="form-control" min="2000" max="2100" placeholder="Ex: 2024" value="<?= htmlspecialchars($year_filter) ?>" onchange="clearOtherFilters('year')">
                        </div>
                        <div class="col-md-3">
                            <button type="submit" class="btn btn-primary w-100"><i class="bi bi-search"></i> Filtrer</button>
                            <a href="benefice.php" class="btn btn-outline-secondary w-100 mt-2"><i class="bi bi-arrow-counterclockwise"></i> Réinitialiser</a>
                        </div>
                    </form>
                </div>
            </div>
            <!-- Résumé des totaux -->
            <div class="row mb-4">
                <div class="col-md-4">
                    <div class="card text-center" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
                        <div class="card-body">
                            <h5 class="card-title">Total des ventes</h5>
                            <h2 class="mb-0"><?= number_format($total_ventes, 2) ?> $</h2>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card text-center" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white;">
                        <div class="card-body">
                            <h5 class="card-title">Dépenses</h5>
                            <h2 class="mb-0"><?= number_format($depenses, 2) ?> $</h2>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card text-center" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white;">
                        <div class="card-body">
                            <h5 class="card-title">Bénéfice brut</h5>
                            <h2 class="mb-0"><?= number_format($benefice_brut, 2) ?> $</h2>
                        </div>
                    </div>
                </div>
            </div>
            <div class="row mb-4">
                <div class="col-md-12">
                    <div class="card text-center" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%); color: white;">
                        <div class="card-body">
                            <h4 class="card-title">Bénéfice net (après dépenses)</h4>
                            <h1 class="mb-0" style="font-size: 3rem;"><?= number_format($benefice_exact, 2) ?> $</h1>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tableau des ventes -->
            <div class="card">
                <div class="card-header bg-primary text-white">
                    <h5 class="mb-0"><i class="bi bi-list-ul"></i> Détail des ventes (<?= count($ventes_detail) ?> vente(s))</h5>
                </div>
                <div class="card-body">
                    <?php if (empty($ventes_detail)): ?>
                        <div class="alert alert-info text-center">
                            <i class="bi bi-info-circle"></i> Aucune vente trouvée pour la période sélectionnée.
                        </div>
                    <?php else: ?>
                        <div class="table-responsive">
                            <table class="table table-hover table-striped">
                                <thead>
                                    <tr>
                                        <th>ID Vente</th>
                                        <th>Date</th>
                                        <th>Client</th>
                                        <th class="text-end">Montant vente</th>
                                        <th class="text-end">Bénéfice</th>
                                        <th class="text-end">% Bénéfice</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($ventes_detail as $vente): ?>
                                        <?php 
                                        $benefice = (float)$vente['benefice_vente'];
                                        $montant = (float)$vente['sale_total'];
                                        $pourcentage = $montant > 0 ? ($benefice / $montant) * 100 : 0;
                                        ?>
                                        <tr>
                                            <td><strong>#<?= $vente['sale_id'] ?></strong></td>
                                            <td><?= date('d/m/Y H:i', strtotime($vente['sale_date'])) ?></td>
                                            <td><?= htmlspecialchars($vente['client_name'] ?? 'N/A') ?></td>
                                            <td class="text-end"><?= number_format($montant, 2) ?> $</td>
                                            <td class="text-end">
                                                <span class="badge <?= $benefice >= 0 ? 'bg-success' : 'bg-danger' ?>" style="font-size: 1rem; padding: 8px 12px;">
                                                    <?= number_format($benefice, 2) ?> $
                                                </span>
                                            </td>
                                            <td class="text-end">
                                                <span class="badge <?= $pourcentage >= 0 ? 'bg-info' : 'bg-danger' ?>" style="font-size: 0.9rem; padding: 6px 10px;">
                                                    <?= number_format($pourcentage, 2) ?>%
                                                </span>
                                            </td>
                                        </tr>
                                    <?php endforeach; ?>
                                </tbody>
                                <tfoot class="table-dark">
                                    <tr>
                                        <th colspan="3" class="text-end">TOTAL :</th>
                                        <th class="text-end"><?= number_format($total_ventes, 2) ?> $</th>
                                        <th class="text-end"><?= number_format($benefice_brut, 2) ?> $</th>
                                        <th class="text-end">
                                            <?php 
                                            $pourcentage_total = $total_ventes > 0 ? ($benefice_brut / $total_ventes) * 100 : 0;
                                            echo number_format($pourcentage_total, 2) . '%';
                                            ?>
                                        </th>
                                    </tr>
                                </tfoot>
                            </table>
                        </div>
                    <?php endif; ?>
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

// Fonction pour effacer les autres filtres quand on en sélectionne un
function clearOtherFilters(selectedFilter) {
    if (selectedFilter === 'date') {
        document.getElementById('month').value = '';
        document.getElementById('year').value = '';
    } else if (selectedFilter === 'month') {
        document.getElementById('date').value = '';
        document.getElementById('year').value = '';
    } else if (selectedFilter === 'year') {
        document.getElementById('date').value = '';
        document.getElementById('month').value = '';
    }
}
</script>
</body>
</html>