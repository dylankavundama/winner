<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}

require_once '../config/db.php';

$stockFilter = isset($_GET['low_stock']) && $_GET['low_stock'] === '1';

if ($stockFilter) {
    $stmt = $pdo->prepare('SELECT * FROM products WHERE quantity <= 15');
} else {
    $stmt = $pdo->prepare('SELECT * FROM products');
}

$stmt->execute();
$products = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Stock des produits</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    
    <!-- CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <link rel="stylesheet" href="../assets/style.css">

    <style>
        body { background: #f5f6fa; }
        .sidebar {
            min-height: 100vh;
            background: #222e3c;
            color: #fff;
        }
        .sidebar a {
            color: #fff;
            text-decoration: none;
            display: block;
            padding: 12px 20px;
            border-radius: 4px;
        }
        .sidebar a.active, .sidebar a:hover {
            background: #1a2230;
        }
        .sidebar .logo {
            font-size: 1.5rem;
            font-weight: bold;
            padding: 24px 20px 16px;
            text-align: center;
        }
        .sidebar .user {
            text-align: center;
            margin-bottom: 20px;
        }
        .sidebar .user i {
            font-size: 2rem;
        }
        .topbar {
            background: #fff;
            border-bottom: 1px solid #eee;
            padding: 12px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .table thead {
            background: #007bff;
            color: #fff;
        }
        @media (max-width: 900px) {
            .sidebar {
                min-height: auto;
                position: fixed;
                left: -220px;
                top: 0;
                width: 200px;
                z-index: 1050;
                transition: left 0.3s;
            }
            .sidebar.open {
                left: 0;
            }
            .main-overlay {
                display: none;
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                background: #0005;
                z-index: 1040;
            }
            .main-overlay.active {
                display: block;
            }
            main {
                padding-left: 0 !important;
            }
            .topbar {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
        }
    </style>
</head>
<body>
<div class="main-overlay" id="mainOverlay" onclick="toggleSidebar(false)"></div>
<div class="container-fluid">
    <div class="row">
        <button class="btn btn-dark d-md-none m-2" onclick="toggleSidebar(true)">
            <i class="bi bi-list"></i>
        </button>

        <!-- Sidebar -->
        <nav class="col-md-2 d-none d-md-block sidebar" id="sidebarMenu">
            <div class="logo mb-3">
                <img src="../assets/logo.png" alt="Logo" style="max-width:40px; vertical-align:middle;"> <span>WINNER</span>
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
            <a href="stock.php" class="active"><i class="bi bi-archive"></i> Stock</a>
            <a href="benefice.php"><i class="bi bi-cash-coin"></i> Bénéfice</a>
            <a href="livre_caisse.php"><i class="bi bi-journal-richtext"></i> Livre de caisse</a>
            <a href="sortie.php"><i class="bi bi-arrow-down-circle"></i> Sorties</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>

        <!-- Main content -->
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-3">
                <span><i class="bi bi-archive"></i> Stock des produits</span>
                <form method="GET" class="d-flex">
                    <input type="hidden" name="low_stock" value="<?= $stockFilter ? '0' : '1' ?>">
                    <button type="submit" class="btn btn-outline-<?= $stockFilter ? 'secondary' : 'danger' ?>">
                        <?= $stockFilter ? 'Afficher tout' : 'Afficher seulement le stock faible' ?>
                    </button>
                </form>
            </div>

            <div class="card">
                <div class="card-body table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Nom</th>
                                <th>Description</th>
                                <th>Stock</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($products as $product): ?>
                            <tr>
                                <td><?= htmlspecialchars($product['id']) ?></td>
                                <td><?= htmlspecialchars($product['name']) ?></td>
                                <td><?= htmlspecialchars($product['description']) ?></td>
                                <td>
                                    <span class="badge bg-<?= $product['quantity'] > 14 ? 'success' : 'danger' ?>">
                                        <?= htmlspecialchars($product['quantity']) ?>
                                    </span>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        <?php if (empty($products)): ?>
                            <tr>
                                <td colspan="4" class="text-center text-muted">Aucun produit trouvé.</td>
                            </tr>
                        <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </main>
    </div>
</div>

<!-- JS -->
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
        setTimeout(() => sidebar.classList.add('d-none'), 300);
    }
}
document.querySelectorAll('#sidebarMenu a').forEach(link => {
    link.addEventListener('click', () => toggleSidebar(false));
});
</script>
</body>
</html>
