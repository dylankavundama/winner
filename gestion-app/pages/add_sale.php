<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: ../login.php');
    exit;
}
require_once '../config/db.php';

// --- Start: AJAX Product Search Logic ---
if (isset($_GET['ajax_search']) && $_GET['ajax_search'] === 'true') {
    $search_query = $_GET['query'] ?? '';
    $products = [];
    try {
        if ($search_query) {
            $stmt = $pdo->prepare('SELECT id, name, prix_vente, quantity FROM products WHERE name LIKE ? LIMIT 50');
            $stmt->execute(['%' . $search_query . '%']);
            $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        } else {
            $products = $pdo->query('SELECT id, name, prix_vente, quantity FROM products LIMIT 50')->fetchAll(PDO::FETCH_ASSOC);
        }
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'products' => $products]);
        exit;
    } catch (PDOException $e) {
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
        exit;
    }
}
// --- End: AJAX Product Search Logic ---

$message = '';
$message_type = ''; // To control alert class (e.g., alert-info, alert-danger, alert-success)

// Get client list (this part remains for the initial page load)
try {
    $clients = $pdo->query('SELECT id, name FROM clients')->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $clients = [];
    $message = 'Erreur lors du chargement des clients: ' . $e->getMessage();
    $message_type = 'danger';
}


// For initial product display, we might load a small set or none
// If JavaScript is enabled, this list will be replaced by AJAX search results quickly.
// We are only loading a small initial set here, and AJAX will take over for search.
$initial_products_display = [];
try {
    $initial_products_display = $pdo->query('SELECT id, name, prix_vente, quantity FROM products LIMIT 20')->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    // Handle error, maybe log it
    $message = 'Erreur lors du chargement initial des produits: ' . $e->getMessage();
    $message_type = 'danger';
}

$role = $_SESSION['role'] ?? '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $client_id = $_POST['client_id'] ?? '';
    $user_id = $_SESSION['user_id'] ?? 1; // Default to 1 if not set, ensure this is handled securely
    $product_ids = $_POST['product_id'] ?? [];
    $quantities = $_POST['quantity'] ?? [];
    $new_prices = $_POST['new_price'] ?? [];
    $imei = trim($_POST['imei'] ?? '');
    $garanti = trim($_POST['garanti'] ?? '');
    $total = 0;
    $valid = true;
    $vente = [];
    $stock_error = false;

    // Validate inputs upfront
    if (empty($client_id) || empty($product_ids)) {
        $message = 'Veuillez sélectionner un client et au moins un produit.';
        $message_type = 'danger';
        $valid = false;
    }

    // Re-fetch product data for validation during POST to ensure data integrity
    // This is crucial as client-side data could be manipulated or outdated
    $current_products_in_db = [];
    if (!empty($product_ids)) {
        $placeholders = implode(',', array_fill(0, count($product_ids), '?'));
        try {
            $stmt = $pdo->prepare("SELECT id, name, prix_vente, quantity FROM products WHERE id IN ($placeholders)");
            $stmt->execute(array_values($product_ids));
            foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $p) {
                $current_products_in_db[$p['id']] = $p;
            }
        } catch (PDOException $e) {
            $message = 'Erreur de base de données lors de la validation des produits: ' . $e->getMessage();
            $message_type = 'danger';
            $valid = false;
        }
    }


    if ($valid) {
        foreach ($product_ids as $pid) {
            $qte = (int)($quantities[$pid] ?? 0);

            if (!isset($current_products_in_db[$pid])) {
                $valid = false;
                $message = 'Un produit sélectionné n\'existe plus.';
                $message_type = 'danger';
                break;
            }

            $applied_price = isset($new_prices[$pid]) && $new_prices[$pid] !== '' ? floatval($new_prices[$pid]) : $current_products_in_db[$pid]['prix_vente'];

            if ($qte <= 0) {
                $valid = false;
                $message = 'Veuillez entrer une quantité valide pour tous les produits sélectionnés.';
                $message_type = 'danger';
                break;
            }

            if ($qte > $current_products_in_db[$pid]['quantity']) {
                $stock_error = true;
                $valid = false;
                $message = 'Stock insuffisant pour le produit ' . htmlspecialchars($current_products_in_db[$pid]['name']) . '. Stock disponible: ' . $current_products_in_db[$pid]['quantity'];
                $message_type = 'danger';
                break;
            }

            $total += $applied_price * $qte;
            $vente[] = [
                'id' => $pid,
                'qte' => $qte,
                'price' => $applied_price
            ];
        }
    }

    if ($valid && !$stock_error) {
        try {
            $pdo->beginTransaction();
            $stmt = $pdo->prepare('INSERT INTO sales (client_id, user_id, total, imei, garanti) VALUES (?, ?, ?, ?, ?)');
            $stmt->execute([$client_id, $user_id, $total, $imei, $garanti]);
            $sale_id = $pdo->lastInsertId();

            $stmt_detail = $pdo->prepare('INSERT INTO sale_details (sale_id, product_id, quantity, price) VALUES (?, ?, ?, ?)');
            $stmt_update_stock = $pdo->prepare('UPDATE products SET quantity = quantity - ? WHERE id = ?');

            foreach ($vente as $v) {
                $stmt_detail->execute([$sale_id, $v['id'], $v['qte'], $v['price']]);
                $stmt_update_stock->execute([$v['qte'], $v['id']]);
            }
            $pdo->commit();
            $message = 'Vente enregistrée avec succès!';
            $message_type = 'success';
            // Clear form fields if desired after successful submission
             $_POST = []; // Clears all POST data after success
        } catch (PDOException $e) {
            $pdo->rollBack();
            $message = 'Erreur lors de l\'enregistrement de la vente: ' . $e->getMessage();
            $message_type = 'danger';
        }
    } else {
        if (!$message) { // Fallback if no specific message was set
            $message = 'Veuillez vérifier les informations de la vente.';
            $message_type = 'danger';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ajouter une vente</title>
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
        .form-card { max-width: 800px; margin: 40px auto; }
        .table-responsive { overflow-x: auto; }
        @media (max-width: 900px) {
            .sidebar { min-height: auto; position: fixed; left: -220px; top: 0; width: 200px; z-index: 1050; transition: left 0.3s; }
            .sidebar.open { left: 0; }
            .sidebar .logo { font-size: 1.2rem; }
            .main-overlay { display: none; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: #0005; z-index: 1040; }
            .main-overlay.active { display: block; }
            main { padding-left: 0 !important; }
            .topbar { flex-direction: column; align-items: flex-start; gap: 10px; }
            .form-card { margin: 20px 5px; }
        }
        /* Loading spinner for product search */
        #search_spinner {
            display: none;
            margin-left: 10px;
            vertical-align: middle;
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
            <a href="sales.php" class="active"><i class="bi bi-cart"></i> Ventes</a>
            <a href="invoices.php"><i class="bi bi-receipt"></i> Factures</a>
            <a href="clients.php"><i class="bi bi-people"></i> Clients</a>
            <a href="reports.php"><i class="bi bi-bar-chart"></i> Rapports</a>
            <a href="../logout.php"><i class="bi bi-box-arrow-right"></i> Déconnexion</a>
        </nav>
        <main class="col-md-10 ms-sm-auto px-4">
            <div class="topbar mb-4">
                <span><i class="bi bi-cart"></i> Ajouter une vente</span>
                <a href="sales.php" class="btn btn-outline-secondary btn-add"><i class="bi bi-arrow-left"></i> Retour</a>
            </div>
            <div class="card form-card">
                <div class="card-body">
                    <?php if ($message): ?>
                        <div class="alert alert-<?= $message_type ?> text-center"> <?= htmlspecialchars($message) ?> </div>
                    <?php endif; ?>
                    <form method="post">
                        <div class="mb-3">
                            <label for="client_id" class="form-label">Client</label>
                            <select name="client_id" id="client_id" class="form-select" required>
                                <option value="">-- Sélectionner --</option>
                                <?php foreach ($clients as $client): ?>
                                    <option value="<?= $client['id'] ?>" <?= (isset($_POST['client_id']) && $_POST['client_id'] == $client['id']) ? 'selected' : '' ?>><?= htmlspecialchars($client['name']) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label for="imei" class="form-label">Adresse IMEI de l'appareil</label>
                            <input type="text" name="imei" id="imei" class="form-control" placeholder="Saisir l'adresse IMEI" value="<?= htmlspecialchars($_POST['imei'] ?? '') ?>" required>
                        </div>
                        <div class="mb-3">
                            <label for="garanti" class="form-label">Garantie</label>
                            <input type="text" name="garanti" id="garanti" class="form-control" placeholder="Ex: 6 mois, 1 an..." value="<?= htmlspecialchars($_POST['garanti'] ?? '') ?>">
                        </div>
                        <fieldset class="mb-3">
                            <legend>Produits</legend>
                            <div class="mb-3 d-flex align-items-center">
                                <label for="search_product" class="form-label mb-0 me-2">Rechercher un produit</label>
                                <input type="text" id="search_product" class="form-control" placeholder="Taper le nom du produit pour rechercher">
                                <div class="spinner-border text-primary spinner-border-sm" role="status" id="search_spinner">
                                    <span class="visually-hidden">Loading...</span>
                                </div>
                            </div>

                            <div class="table-responsive">
                                <table class="table table-bordered align-middle">
                                    <thead>
                                        <tr>
                                            <th>Sélection</th>
                                            <th>Produit</th>
                                            <th>Prix de vente</th>
                                            <th>Stock</th>
                                            <th>Quantité</th>
                                        </tr>
                                    </thead>
                                    <tbody id="product_table_body">
                                    <?php if (empty($initial_products_display)): ?>
                                        <tr>
                                            <td colspan="5" class="text-center">Aucun produit disponible. Commencez à taper pour rechercher.</td>
                                        </tr>
                                    <?php else: ?>
                                        <?php foreach ($initial_products_display as $product): ?>
                                            <?php
                                                // Retain selected state and values after POST submission
                                                $isChecked = isset($_POST['product_id']) && in_array($product['id'], $_POST['product_id']) ? 'checked' : '';
                                                $currentQuantity = $_POST['quantity'][$product['id']] ?? '';
                                                $currentPrice = $_POST['new_price'][$product['id']] ?? $product['prix_vente'];
                                            ?>
                                            <tr>
                                                <td><input class="form-check-input" type="checkbox" name="product_id[]" value="<?= $product['id'] ?>" id="prod<?= $product['id'] ?>" <?= $isChecked ?>></td>
                                                <td><label for="prod<?= $product['id'] ?>"><?= htmlspecialchars($product['name']) ?></label></td>
                                                <td><input type="number" step="0.01" min="0" name="new_price[<?= $product['id'] ?>]" class="form-control" value="<?= htmlspecialchars($currentPrice) ?>" style="width:110px;" placeholder="Prix de vente"></td>
                                                <td><?= $product['quantity'] ?></td>
                                                <td><input type="number" name="quantity[<?= $product['id'] ?>]" min="1" max="<?= $product['quantity'] ?>" class="form-control" value="<?= htmlspecialchars($currentQuantity) ?>" style="width:90px;" placeholder="Qté"></td>
                                            </tr>
                                        <?php endforeach; ?>
                                    <?php endif; ?>
                                    </tbody>
                                </table>
                            </div>
                        </fieldset>
                        <button type="submit" class="btn btn-primary w-100">Enregistrer la vente</button>
                    </form>
                </div>
            </div>
        </main>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
const USER_ROLE = <?= json_encode($role) ?>;

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

// --- Start: Instant Search JavaScript ---
document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('search_product');
    const productTableBody = document.getElementById('product_table_body');
    const searchSpinner = document.getElementById('search_spinner');
    let debounceTimer;
    let currentAbortController = null; // For aborting previous requests

    // Store selected product data (checked, quantity, price)
    // This object will hold product IDs as keys, and an object with their state as values
    // e.g., { '123': { isChecked: true, quantity: 2, newPrice: 15.50 } }
    const selectedProductsData = {};

    // Function to update selectedProductsData from current form inputs
    function updateSelectedProductsData() {
        // Clear any products that are no longer selected
        for (const productId in selectedProductsData) {
            const checkbox = document.getElementById(`prod${productId}`);
            if (checkbox && !checkbox.checked) {
                delete selectedProductsData[productId];
            }
        }

        // Add/update currently selected products
        document.querySelectorAll('#product_table_body input[type="checkbox"]:checked').forEach(checkbox => {
            const productId = checkbox.value;
            const quantityInput = document.querySelector(`input[name="quantity[${productId}]"]`);
            const priceInput = document.querySelector(`input[name="new_price[${productId}]"]`);

            selectedProductsData[productId] = {
                isChecked: true,
                quantity: quantityInput ? quantityInput.value : '',
                newPrice: priceInput ? priceInput.value : ''
            };
        });
    }

    // Attach event listeners to the dynamically loaded product rows
    // This function will be called after fetching new products
    function attachProductInputListeners() {
        productTableBody.querySelectorAll('input[type="checkbox"], input[type="number"]').forEach(input => {
            input.addEventListener('change', updateSelectedProductsData);
            input.addEventListener('input', updateSelectedProductsData); // For quantity/price changes
        });
    }

    // Function to fetch products via AJAX
    async function fetchProducts(query) {
        if (currentAbortController) {
            currentAbortController.abort(); // Abort previous pending request
        }
        currentAbortController = new AbortController();
        const signal = currentAbortController.signal;

        searchSpinner.style.display = 'inline-block'; // Show spinner
        productTableBody.innerHTML = `<tr><td colspan="5" class="text-center text-muted">Recherche en cours...</td></tr>`; // Show loading message

        // Get the current path of the page (e.g., /sales/add_sale.php)
        const currentPath = window.location.pathname;
        const url = `${currentPath}?ajax_search=true&query=${encodeURIComponent(query)}`;

        try {
            const response = await fetch(url, { signal });
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            const data = await response.json();

            if (!data.success) {
                productTableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">${data.message || 'Erreur lors du chargement des produits.'}</td></tr>`;
                return;
            }

            const products = data.products;
            productTableBody.innerHTML = ''; // Clear existing table rows

            if (products.length === 0) {
                const noResultsRow = `<tr><td colspan="5" class="text-center">Aucun produit trouvé pour "${query}".</td></tr>`;
                productTableBody.innerHTML = noResultsRow;
                return;
            }

            products.forEach(product => {
                // Check if this product was previously selected (from selectedProductsData)
                const storedData = selectedProductsData[product.id];
                const isChecked = storedData ? storedData.isChecked : false;
                const quantityValue = storedData ? storedData.quantity : '';
                const newPriceValue = storedData ? storedData.newPrice : product.prix_vente;

                let row = `<tr>`;
                row += `<td><input class="form-check-input" type="checkbox" name="product_id[]" value="${product.id}" id="prod${product.id}" ${isChecked ? 'checked' : ''}></td>`;
                row += `<td><label for="prod${product.id}">${product.name}</label></td>`;
                row += `<td><input type="number" step="0.01" min="0" name="new_price[${product.id}]" class="form-control" value="${newPriceValue}" style="width:110px;" placeholder="Prix de vente"></td>`;
                row += `<td>${product.quantity}</td>`;
                row += `<td><input type="number" name="quantity[${product.id}]" min="1" max="${product.quantity}" class="form-control" value="${quantityValue}" style="width:90px;" placeholder="Qté"></td>`;
                row += `</tr>`;
                productTableBody.innerHTML += row;
            });
            attachProductInputListeners(); // Re-attach listeners to new elements

        } catch (error) {
            if (error.name === 'AbortError') {
                console.log('Fetch aborted:', query); // Request was cancelled, which is fine
            } else {
                console.error('Error fetching products:', error);
                productTableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Erreur lors du chargement des produits.</td></tr>`;
            }
        } finally {
            searchSpinner.style.display = 'none'; // Hide spinner
            currentAbortController = null; // Clear controller
        }
    }

    // Initial population of selectedProductsData from PHP rendered products
    // This ensures that if the page reloads due to a POST failure, selections are preserved.
    document.querySelectorAll('#product_table_body input[type="checkbox"]:checked').forEach(checkbox => {
        const productId = checkbox.value;
        const quantityInput = document.querySelector(`input[name="quantity[${productId}]"]`);
        const priceInput = document.querySelector(`input[name="new_price[${productId}]"]`);

        selectedProductsData[productId] = {
            isChecked: true,
            quantity: quantityInput ? quantityInput.value : '',
            newPrice: priceInput ? priceInput.value : ''
        };
    });
    attachProductInputListeners(); // Attach listeners for initial products

    // Event listener for input changes with debounce
    searchInput.addEventListener('input', function() {
        clearTimeout(debounceTimer); // Clear previous timer
        const query = this.value;
        debounceTimer = setTimeout(() => {
            fetchProducts(query);
        }, 300); // 300ms debounce time
    });

    // Optional: Fetch initial products on DOMContentLoaded if search input is empty
    // If you always want some products to show even before typing
    // if (searchInput.value === '') {
    //     fetchProducts(''); // Fetch a limited set of all products
    // }
});
// --- End: Instant Search JavaScript ---
</script>
</body>
</html>