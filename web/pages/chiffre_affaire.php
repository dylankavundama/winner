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

// Paramètres de filtrage par défaut
$start_date = $_GET['start_date'] ?? date('Y-m-01'); // Premier jour du mois
$end_date = $_GET['end_date'] ?? date('Y-m-d'); // Aujourd'hui
$group_by = $_GET['group_by'] ?? 'all';

// Récupérer les données via l'API
$api_url = "../api/chiffre_affaire.php?start_date=" . urlencode($start_date) . "&end_date=" . urlencode($end_date) . "&group_by=" . urlencode($group_by);
$api_data = @file_get_contents($api_url);
$data = $api_data ? json_decode($api_data, true) : null;
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Chiffre d'affaire</title>
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
        .ca-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 15px; padding: 30px; margin-bottom: 30px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .ca-card h2 { font-size: 2.5rem; font-weight: bold; margin: 0; }
        .ca-card p { font-size: 1.1rem; opacity: 0.9; margin: 10px 0 0 0; }
        .stats-card { background: #fff; border-radius: 10px; padding: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .stats-card .value { font-size: 2rem; font-weight: bold; color: #667eea; }
        .stats-card .label { color: #666; font-size: 0.9rem; }
        .table thead { background: #667eea; color: #fff; }
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
            <a href="chiffre_affaire.php" class="active"><i class="bi bi-cash-stack"></i> Chiffre d'affaire</a>
            <a href="deposits.php"><i class="bi bi-piggy-bank"></i> Deposits</a>
            <a href="benefice.php"><i class="bi bi-cash-coin"></i> Bénéfice</a>
            <a href="sortie.php"><i class="bi bi-arrow-down-circle"></i> Sorties</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-cash-stack"></i> Chiffre d'affaire</span>
            </div>
            
            <!-- Filtres -->
            <div class="card mb-4">
                <div class="card-body">
                    <form method="get" class="row g-3">
                        <div class="col-md-3">
                            <label for="start_date" class="form-label">Date début</label>
                            <input type="date" class="form-control" id="start_date" name="start_date" value="<?= htmlspecialchars($start_date) ?>" required>
                        </div>
                        <div class="col-md-3">
                            <label for="end_date" class="form-label">Date fin</label>
                            <input type="date" class="form-control" id="end_date" name="end_date" value="<?= htmlspecialchars($end_date) ?>" required>
                        </div>
                        <div class="col-md-3">
                            <label for="group_by" class="form-label">Grouper par</label>
                            <select class="form-select" id="group_by" name="group_by">
                                <option value="all" <?= $group_by === 'all' ? 'selected' : '' ?>>Tout afficher</option>
                                <option value="day" <?= $group_by === 'day' ? 'selected' : '' ?>>Par jour</option>
                                <option value="month" <?= $group_by === 'month' ? 'selected' : '' ?>>Par mois</option>
                                <option value="year" <?= $group_by === 'year' ? 'selected' : '' ?>>Par année</option>
                                <option value="product" <?= $group_by === 'product' ? 'selected' : '' ?>>Par produit</option>
                            </select>
                        </div>
                        <div class="col-md-3 d-flex align-items-end">
                            <button type="submit" class="btn btn-primary w-100"><i class="bi bi-search"></i> Filtrer</button>
                        </div>
                    </form>
                </div>
            </div>
            
            <?php if ($data && $data['success']): ?>
                <!-- Carte principale du chiffre d'affaire -->
                <div class="ca-card">
                    <h2><?= number_format($data['total_ca'], 2) ?> $</h2>
                    <p>Chiffre d'affaire total</p>
                    <?php if ($start_date && $end_date): ?>
                        <p style="font-size: 0.9rem; opacity: 0.8;">
                            Du <?= date('d/m/Y', strtotime($start_date)) ?> au <?= date('d/m/Y', strtotime($end_date)) ?>
                        </p>
                    <?php endif; ?>
                </div>
                
                <!-- Statistiques -->
                <?php if (isset($data['stats'])): ?>
                <div class="row mb-4">
                    <div class="col-md-4">
                        <div class="stats-card text-center">
                            <div class="value"><?= $data['stats']['total_sales'] ?></div>
                            <div class="label">Nombre de ventes</div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="stats-card text-center">
                            <div class="value"><?= $data['stats']['total_products'] ?></div>
                            <div class="label">Produits vendus</div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="stats-card text-center">
                            <div class="value"><?= number_format($data['stats']['avg_sale_amount'], 2) ?> $</div>
                            <div class="label">Montant moyen par vente</div>
                        </div>
                    </div>
                </div>
                <?php endif; ?>
                
                <!-- Détail par période -->
                <?php if (isset($data['by_period']) && !empty($data['by_period'])): ?>
                <div class="card mb-4">
                    <div class="card-header bg-primary text-white">
                        <h5 class="mb-0"><i class="bi bi-calendar"></i> Chiffre d'affaire par période</h5>
                    </div>
                    <div class="card-body">
                        <canvas id="periodChart" height="80"></canvas>
                        <div class="table-responsive mt-4">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Période</th>
                                        <th class="text-end">Chiffre d'affaire</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($data['by_period'] as $period): ?>
                                    <tr>
                                        <td><?= htmlspecialchars($period['period']) ?></td>
                                        <td class="text-end"><strong><?= number_format($period['ca'], 2) ?> $</strong></td>
                                    </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <?php endif; ?>
                
                <!-- Détail par produit -->
                <?php if (isset($data['by_product']) && !empty($data['by_product'])): ?>
                <div class="card mb-4">
                    <div class="card-header bg-success text-white">
                        <h5 class="mb-0"><i class="bi bi-box"></i> Chiffre d'affaire par produit</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Produit</th>
                                        <th class="text-end">Quantité vendue</th>
                                        <th class="text-end">Prix moyen</th>
                                        <th class="text-end">Chiffre d'affaire</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($data['by_product'] as $product): ?>
                                    <tr>
                                        <td><?= htmlspecialchars($product['product_name']) ?></td>
                                        <td class="text-end"><?= number_format($product['total_quantity'], 0) ?></td>
                                        <td class="text-end"><?= number_format($product['avg_price'], 2) ?> $</td>
                                        <td class="text-end"><strong><?= number_format($product['total_ca'], 2) ?> $</strong></td>
                                    </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <?php endif; ?>
            <?php else: ?>
                <div class="alert alert-danger">
                    <i class="bi bi-exclamation-triangle"></i> Erreur lors du chargement des données du chiffre d'affaire.
                </div>
            <?php endif; ?>
        </main>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.3.0/dist/chart.umd.min.js"></script>
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

<?php if (isset($data['by_period']) && !empty($data['by_period'])): ?>
// Graphique par période
const periodCtx = document.getElementById('periodChart');
if (periodCtx) {
    const periodData = <?= json_encode($data['by_period']) ?>;
    const periodLabels = periodData.map(p => p.period);
    const periodValues = periodData.map(p => parseFloat(p.ca));
    
    new Chart(periodCtx, {
        type: 'bar',
        data: {
            labels: periodLabels,
            datasets: [{
                label: 'Chiffre d\'affaire ($)',
                data: periodValues,
                backgroundColor: 'rgba(102, 126, 234, 0.8)',
                borderColor: 'rgba(102, 126, 234, 1)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return value.toFixed(2) + ' $';
                        }
                    }
                }
            }
        }
    });
}
<?php endif; ?>
</script>
</body>
</html>

