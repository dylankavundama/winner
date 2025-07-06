<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}
require_once '../config/db.php';
$stmt = $pdo->query('SELECT invoices.id, clients.name AS client_name, invoices.invoice_date, invoices.amount, invoices.status FROM invoices LEFT JOIN sales ON invoices.sale_id = sales.id LEFT JOIN clients ON sales.client_id = clients.id ORDER BY invoices.invoice_date DESC');
$invoices = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Factures</title>
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
        .btn-add { float: right; margin-bottom: 10px; }
        .table-responsive { overflow-x: auto; }
        .badge { font-size: 0.8em; }
        .status-cell { display: flex; align-items: center; gap: 8px; }
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
            <a href="invoices.php" class="active"><i class="bi bi-receipt"></i> Factures</a>
            <a href="clients.php"><i class="bi bi-people"></i> Clients</a>
            <a href="reports.php"><i class="bi bi-bar-chart"></i> Rapports</a>
            <a href="stock.php"><i class="bi bi-archive"></i> Stock</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-receipt"></i> Factures</span>
                <a href="add_invoice.php" class="btn btn-primary btn-add"><i class="bi bi-plus"></i> Générer une facture</a>
            </div>
            <div class="card">
                <div class="card-body table-responsive">
                    <table class="table table-hover align-middle">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Client</th>
                                <th>Date</th>
                                <th>Montant</th>
                                <th>Statut</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($invoices as $invoice): ?>
                        <tr>
                            <td><?= $invoice['id'] ?></td>
                            <td><?= htmlspecialchars($invoice['client_name']) ?></td>
                            <td><?= $invoice['invoice_date'] ?></td>
                            <td><?= $invoice['amount'] ?> $</td>
                            <td class="status-cell">
                                <span class="badge <?= $invoice['status'] === 'payée' ? 'bg-success' : 'bg-warning' ?>">
                                    <?= $invoice['status'] ?>
                                </span>
                                <button class="btn btn-sm btn-outline-secondary" 
                                        onclick="changeStatus(<?= $invoice['id'] ?>, '<?= $invoice['status'] === 'payée' ? 'impayée' : 'payée' ?>')"
                                        title="Changer le statut">
                                    <i class="bi bi-arrow-repeat"></i>
                                </button>
                            </td>
                            <td>
                                <a href="view_invoice.php?id=<?= $invoice['id'] ?>" class="btn btn-sm btn-outline-info">Voir</a>
                                <a href="view_invoice.php?id=<?= $invoice['id'] ?>&print=1" target="_blank" class="btn btn-sm btn-outline-success">Imprimer</a>
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

// Fonction pour changer le statut d'une facture
function changeStatus(invoiceId, newStatus) {
    if (!confirm('Êtes-vous sûr de vouloir changer le statut de cette facture ?')) {
        return;
    }
    
    const formData = new FormData();
    formData.append('invoice_id', invoiceId);
    formData.append('status', newStatus);
    
    fetch('update_invoice_status.php', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // Afficher une notification de succès
            showNotification(data.message, 'success');
            // Recharger la page après un délai
            setTimeout(() => {
                location.reload();
            }, 1500);
        } else {
            showNotification(data.message, 'error');
        }
    })
    .catch(error => {
        console.error('Erreur:', error);
        showNotification('Erreur lors de la mise à jour', 'error');
    });
}

// Fonction pour afficher les notifications
function showNotification(message, type) {
    // Supprimer les notifications existantes
    const existingNotifications = document.querySelectorAll('.notification');
    existingNotifications.forEach(notification => notification.remove());
    
    // Créer la notification
    const notification = document.createElement('div');
    notification.className = `notification alert alert-${type === 'success' ? 'success' : 'danger'} alert-dismissible fade show position-fixed`;
    notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
    notification.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(notification);
    
    // Auto-suppression après 5 secondes
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, 5000);
}
</script>
</body>
</html> 