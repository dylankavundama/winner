<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}
require_once '../config/db.php';
$message = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user_id = $_SESSION['user_id'];
    $montant = $_POST['montant'] ?? '';
    $motif = $_POST['motif'] ?? '';
    $type = $_POST['type'] ?? 'normal';
    if ($montant !== '' && $motif !== '') {
        $stmt = $pdo->prepare('INSERT INTO sorties (user_id, montant, motif, type) VALUES (?, ?, ?, ?)');
        if ($stmt->execute([$user_id, $montant, $motif, $type])) {
            $message = 'Sortie enregistrée avec succès!';
        } else {
            $message = "Erreur lors de l'enregistrement.";
        }
    } else {
        $message = 'Veuillez remplir tous les champs.';
    }
}
$date_filter = $_GET['date'] ?? '';
$month_filter = $_GET['month'] ?? '';
$year_filter = $_GET['year'] ?? '';
$type_filter = $_GET['type_filter'] ?? '';
$sql = 'SELECT s.*, u.username FROM sorties s JOIN users u ON s.user_id = u.id';
$where = [];
$params = [];
if ($type_filter && in_array($type_filter, ['normal','transaction'])) {
    $where[] = 's.type = ?';
    $params[] = $type_filter;
}
if ($date_filter) {
    $where[] = 'DATE(s.date_sortie) = ?';
    $params[] = $date_filter;
}
if ($month_filter) {
    $where[] = 'DATE_FORMAT(s.date_sortie, "%Y-%m") = ?';
    $params[] = $month_filter;
}
if ($year_filter) {
    $where[] = 'YEAR(s.date_sortie) = ?';
    $params[] = $year_filter;
}
if ($where) {
    $sql .= ' WHERE ' . implode(' AND ', $where);
}
$sql .= ' ORDER BY s.date_sortie DESC';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$sorties = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ajouter une sortie</title>
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
        .main-flex { display: flex; gap: 32px; align-items: flex-start; }
        .form-card { flex: 1 1 350px; max-width: 400px; margin: 0; box-shadow: 0 2px 16px #0002; border-radius: 12px; background: #fff; border: none; }
        .list-card { flex: 2 1 600px; box-shadow: 0 2px 16px #0001; border-radius: 12px; background: #fff; border: none; }
        .section-title { font-size: 1.3rem; font-weight: bold; margin-bottom: 18px; letter-spacing: 1px; }
        .table thead th { position: sticky; top: 0; background: #f8f9fa; z-index: 1; }
        .table-striped > tbody > tr:nth-of-type(odd) { background-color: #f2f6fc; }
        .badge-normal { background: #0d6efd; font-size: 0.95em; }
        .badge-transaction { background: #ffc107; color: #222; font-size: 0.95em; }
        @media (max-width: 1100px) {
            .main-flex { flex-direction: column; gap: 0; }
            .form-card, .list-card { max-width: 100%; margin: 0 0 24px 0; }
        }
        @media (max-width: 600px) {
            .main-flex { flex-direction: column; gap: 0; }
            .form-card, .list-card { max-width: 100%; margin: 0 0 18px 0; box-shadow: 0 1px 6px #0001; border-radius: 8px; padding: 10px !important; }
            .section-title { font-size: 1.05rem; margin-bottom: 12px; }
            .form-label, .form-control, .form-select, .btn, .badge { font-size: 0.98em !important; }
            .btn { padding: 8px 0; }
            .table-responsive { font-size: 0.97em; }
            .table thead th, .table td { padding: 7px 6px; }
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
            <a href="benefice.php"><i class="bi bi-cash-coin"></i> Bénéfice</a>
            <a href="sortie.php" class="active"><i class="bi bi-arrow-down-circle"></i> Sorties</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-arrow-down-circle"></i> Sorties de caisse</span>
                <a href="dashboard.php" class="btn btn-outline-secondary btn-add"><i class="bi bi-arrow-left"></i> Retour</a>
            </div>
            <div class="main-flex">
                <div class="card form-card p-4 mb-4">
                    <div class="section-title mb-3"><i class="bi bi-plus-circle"></i> Nouvelle sortie</div>
                    <?php if ($message): ?>
                        <div class="alert alert-info text-center"> <?= htmlspecialchars($message) ?> </div>
                    <?php endif; ?>
                    <form method="post">
                        <div class="mb-3">
                            <label class="form-label">Utilisateur</label>
                            <input type="text" class="form-control" value="<?= htmlspecialchars($_SESSION['username']) ?>" disabled>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Montant</label>
                            <input type="number" name="montant" class="form-control" step="0.01" min="0" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Motif</label>
                            <input type="text" name="motif" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Type</label>
                            <select name="type" class="form-select" required>
                                <option value="normal">Normal</option>
                                <option value="transaction">Transaction</option>
                            </select>
                        </div>
                        <button type="submit" class="btn btn-primary w-100"><i class="bi bi-save"></i> Enregistrer la sortie</button>
                    </form>
                </div>
                <div class="list-card card p-4 mb-4">
                    <div class="section-title mb-3"><i class="bi bi-list"></i> Liste des sorties</div>
                    <form method="get" class="mb-3 row g-2 align-items-end" style="max-width:700px">
                        <div class="col-auto">
                            <label for="type_filter" class="form-label">Type :</label>
                            <select name="type_filter" id="type_filter" class="form-select">
                                <option value=""<?= $type_filter===''?' selected':'' ?>>Tous</option>
                                <option value="normal"<?= $type_filter==='normal'?' selected':'' ?>>Normal</option>
                                <option value="transaction"<?= $type_filter==='transaction'?' selected':'' ?>>Transaction</option>
                            </select>
                        </div>
                        <div class="col-auto">
                            <label for="date" class="form-label mb-0">Jour :</label>
                            <input type="date" id="date" name="date" class="form-control" value="<?= htmlspecialchars($date_filter) ?>">
                        </div>
                        <div class="col-auto">
                            <label for="month" class="form-label mb-0">Mois :</label>
                            <input type="month" id="month" name="month" class="form-control" value="<?= htmlspecialchars($month_filter) ?>">
                        </div>
                        <div class="col-auto">
                            <label for="year" class="form-label mb-0">Année :</label>
                            <input type="number" id="year" name="year" class="form-control" min="2000" max="2100" placeholder="Année" value="<?= htmlspecialchars($year_filter) ?>">
                        </div>
                        <div class="col-auto">
                            <button type="submit" class="btn btn-outline-primary">Filtrer</button>
                            <a href="sortie.php" class="btn btn-outline-secondary">Réinitialiser</a>
                        </div>
                    </form>
                    <?php if ($sorties): ?>
                    <div class="table-responsive">
                        <table class="table table-hover table-striped align-middle">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Utilisateur</th>
                                    <th>Montant</th>
                                    <th>Motif</th>
                                    <th>Type</th>
                                    <th>Date</th>
                                </tr>
                            </thead>
                            <tbody>
                            <?php foreach ($sorties as $s): ?>
                                <tr>
                                    <td><?= $s['id'] ?></td>
                                    <td><?= htmlspecialchars($s['username']) ?></td>
                                    <td><?= number_format($s['montant'],2) ?> $</td>
                                    <td><?= htmlspecialchars($s['motif']) ?></td>
                                    <td>
                                        <?php if ($s['type']==='normal'): ?>
                                            <span class="badge badge-normal">Normal</span>
                                        <?php elseif ($s['type']==='transaction'): ?>
                                            <span class="badge badge-transaction">Transaction</span>
                                        <?php else: ?>
                                            <span class="badge bg-secondary">?</span>
                                        <?php endif; ?>
                                    </td>
                                    <td><?= $s['date_sortie'] ?></td>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                    <?php else: ?>
                        <div class="alert alert-warning text-center">Aucune sortie enregistrée.</div>
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
</script>
</body>
</html> 