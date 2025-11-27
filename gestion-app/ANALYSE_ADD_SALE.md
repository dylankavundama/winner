# Analyse du code `add_sale.php`

## ✅ Points positifs

1. **Transactions** : Utilisation correcte de `beginTransaction()` et `rollBack()`
2. **Requêtes préparées** : Protection contre les injections SQL
3. **Headers CORS** : Configuration pour les appels cross-origin
4. **Gestion d'erreurs** : Try-catch présent
5. **Validation basique** : Vérification des champs requis

## ⚠️ Problèmes identifiés

### 🔴 Critiques (Sécurité & Intégrité)

1. **Pas de vérification du stock avant la transaction**
   - Risque de vendre plus que le stock disponible
   - Le stock peut devenir négatif

2. **Pas de validation des types de données**
   - `client_id`, `user_id` doivent être des entiers
   - `total`, `price` doivent être des nombres positifs
   - `quantity` doit être un entier positif

3. **Pas de vérification d'existence**
   - Client peut ne pas exister
   - Produit peut ne pas exister
   - Utilisateur peut ne pas exister

4. **Pas de validation du total**
   - Le total envoyé peut ne pas correspondre à la somme des produits

5. **Pas de validation de la quantité**
   - Quantité peut être 0 ou négative
   - Pas de limite maximale

6. **Pas de validation du prix**
   - Prix peut être négatif ou 0

7. **Pas de limite sur le nombre de produits**
   - Risque de DoS avec un tableau énorme

8. **Exposition d'erreurs SQL**
   - `$e->getMessage()` peut révéler des informations sensibles

### 🟡 Moyens (Robustesse)

9. **Pas de logs pour le débogage**
10. **Pas de validation des formats** (IMEI, garantie)
11. **CORS trop permissif** (`*` au lieu d'origines spécifiques)
12. **Pas de rate limiting**
13. **Pas de validation que `products` est un tableau non vide**

## 📝 Recommandations d'amélioration

### Version améliorée proposée

```php
<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *"); // À restreindre en production
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once '../config/db.php';

// Fonction de validation des types
function validateInput($input) {
    $errors = [];
    
    // Validation des champs requis
    $requiredFields = ['client_id', 'user_id', 'total', 'products'];
    foreach ($requiredFields as $field) {
        if (!isset($input[$field])) {
            $errors[] = "Le champ $field est obligatoire";
        }
    }
    
    // Validation des types
    if (isset($input['client_id']) && (!is_numeric($input['client_id']) || $input['client_id'] <= 0)) {
        $errors[] = "client_id doit être un entier positif";
    }
    
    if (isset($input['user_id']) && (!is_numeric($input['user_id']) || $input['user_id'] <= 0)) {
        $errors[] = "user_id doit être un entier positif";
    }
    
    if (isset($input['total']) && (!is_numeric($input['total']) || $input['total'] <= 0)) {
        $errors[] = "total doit être un nombre positif";
    }
    
    // Validation des produits
    if (isset($input['products'])) {
        if (!is_array($input['products']) || empty($input['products'])) {
            $errors[] = "products doit être un tableau non vide";
        } else {
            // Limite le nombre de produits
            if (count($input['products']) > 100) {
                $errors[] = "Maximum 100 produits par vente";
            }
            
            foreach ($input['products'] as $index => $product) {
                if (!isset($product['id']) || !is_numeric($product['id']) || $product['id'] <= 0) {
                    $errors[] = "Produit #$index: id invalide";
                }
                if (!isset($product['quantity']) || !is_numeric($product['quantity']) || $product['quantity'] <= 0) {
                    $errors[] = "Produit #$index: quantity doit être un entier positif";
                }
                if (!isset($product['price']) || !is_numeric($product['price']) || $product['price'] <= 0) {
                    $errors[] = "Produit #$index: price doit être un nombre positif";
                }
            }
        }
    }
    
    return $errors;
}

// Vérifier l'existence et le stock des produits
function validateProducts($pdo, $products) {
    $errors = [];
    $calculatedTotal = 0;
    
    foreach ($products as $index => $product) {
        $productId = (int)$product['id'];
        $quantity = (int)$product['quantity'];
        $price = (float)$product['price'];
        
        // Vérifier l'existence du produit
        $stmt = $pdo->prepare("SELECT id, name, quantity, prix_vente FROM products WHERE id = :id");
        $stmt->execute([':id' => $productId]);
        $dbProduct = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$dbProduct) {
            $errors[] = "Produit #$index (ID: $productId) n'existe pas";
            continue;
        }
        
        // Vérifier le stock
        if ($dbProduct['quantity'] < $quantity) {
            $errors[] = "Stock insuffisant pour {$dbProduct['name']} (disponible: {$dbProduct['quantity']}, demandé: $quantity)";
        }
        
        // Calculer le total
        $calculatedTotal += $price * $quantity;
    }
    
    return ['errors' => $errors, 'calculatedTotal' => $calculatedTotal];
}

// Vérifier l'existence du client
function clientExists($pdo, $clientId) {
    $stmt = $pdo->prepare("SELECT id FROM clients WHERE id = :id");
    $stmt->execute([':id' => $clientId]);
    return $stmt->fetch() !== false;
}

// Vérifier l'existence de l'utilisateur
function userExists($pdo, $userId) {
    $stmt = $pdo->prepare("SELECT id FROM users WHERE id = :id");
    $stmt->execute([':id' => $userId]);
    return $stmt->fetch() !== false;
}

function addSale($pdo, $clientId, $userId, $total, $imei, $garanti, $products) {
    try {
        $pdo->beginTransaction();
        
        // 1. Insérer la vente principale
        $stmt = $pdo->prepare("
            INSERT INTO sales 
            (client_id, user_id, total, imei, garanti, sale_date)
            VALUES 
            (:client_id, :user_id, :total, :imei, :garanti, NOW())
        ");
        
        $stmt->execute([
            ':client_id' => (int)$clientId,
            ':user_id' => (int)$userId,
            ':total' => (float)$total,
            ':imei' => $imei ?? '',
            ':garanti' => $garanti ?? ''
        ]);
        
        $saleId = $pdo->lastInsertId();
        
        // 2. Insérer les articles de la vente et mettre à jour le stock
        $itemStmt = $pdo->prepare("
            INSERT INTO sale_details 
            (sale_id, product_id, quantity, price)
            VALUES 
            (:sale_id, :product_id, :quantity, :price)
        ");
        
        $updateStmt = $pdo->prepare("
            UPDATE products 
            SET quantity = quantity - :quantity 
            WHERE id = :product_id AND quantity >= :quantity
        ");
        
        foreach ($products as $product) {
            $productId = (int)$product['id'];
            $quantity = (int)$product['quantity'];
            $price = (float)$product['price'];
            
            // Insérer le détail de vente
            $itemStmt->execute([
                ':sale_id' => $saleId,
                ':product_id' => $productId,
                ':quantity' => $quantity,
                ':price' => $price
            ]);
            
            // Mettre à jour le stock (avec vérification dans la requête)
            $updateStmt->execute([
                ':quantity' => $quantity,
                ':product_id' => $productId
            ]);
            
            // Vérifier que la mise à jour a affecté une ligne
            if ($updateStmt->rowCount() === 0) {
                throw new Exception("Stock insuffisant pour le produit ID: $productId");
            }
        }
        
        $pdo->commit();
        
        return [
            'success' => true,
            'message' => 'Vente enregistrée avec succès',
            'sale_id' => (int)$saleId
        ];
        
    } catch(PDOException $e) {
        $pdo->rollBack();
        // Log l'erreur sans exposer les détails
        error_log("Erreur add_sale: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Erreur lors de l\'enregistrement de la vente'
        ];
    } catch(Exception $e) {
        $pdo->rollBack();
        return [
            'success' => false,
            'message' => $e->getMessage()
        ];
    }
}

// Traitement de la requête
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        if ($input === null || json_last_error() !== JSON_ERROR_NONE) {
            echo json_encode([
                'success' => false, 
                'message' => 'Données JSON invalides'
            ]);
            exit;
        }
        
        // Validation des données
        $validationErrors = validateInput($input);
        if (!empty($validationErrors)) {
            echo json_encode([
                'success' => false, 
                'message' => implode(', ', $validationErrors)
            ]);
            exit;
        }
        
        // Vérifier l'existence du client
        if (!clientExists($pdo, $input['client_id'])) {
            echo json_encode([
                'success' => false, 
                'message' => 'Client introuvable'
            ]);
            exit;
        }
        
        // Vérifier l'existence de l'utilisateur
        if (!userExists($pdo, $input['user_id'])) {
            echo json_encode([
                'success' => false, 
                'message' => 'Utilisateur introuvable'
            ]);
            exit;
        }
        
        // Valider les produits et vérifier le stock
        $productValidation = validateProducts($pdo, $input['products']);
        if (!empty($productValidation['errors'])) {
            echo json_encode([
                'success' => false, 
                'message' => implode(', ', $productValidation['errors'])
            ]);
            exit;
        }
        
        // Vérifier que le total correspond (avec une tolérance de 0.01 pour les arrondis)
        $calculatedTotal = $productValidation['calculatedTotal'];
        $providedTotal = (float)$input['total'];
        if (abs($calculatedTotal - $providedTotal) > 0.01) {
            echo json_encode([
                'success' => false, 
                'message' => "Le total ne correspond pas (calculé: $calculatedTotal, fourni: $providedTotal)"
            ]);
            exit;
        }
        
        // Garantie et IMEI sont optionnels
        $garanti = $input['garanti'] ?? '';
        $imei = $input['imei'] ?? '';
        
        // Sanitization basique
        $garanti = trim($garanti);
        $imei = trim($imei);
        
        $result = addSale(
            $pdo,
            $input['client_id'],
            $input['user_id'],
            $input['total'],
            $imei,
            $garanti,
            $input['products']
        );
        
        echo json_encode($result);
        
    } catch (Exception $e) {
        error_log("Erreur add_sale: " . $e->getMessage());
        echo json_encode([
            'success' => false, 
            'message' => 'Erreur serveur'
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode([
        'success' => false, 
        'message' => 'Méthode non autorisée'
    ]);
}
?>
```

## 🔒 Améliorations de sécurité

1. **Validation stricte des types** : Tous les champs sont validés
2. **Vérification du stock** : Avant et pendant la transaction
3. **Vérification d'existence** : Client, utilisateur, produits
4. **Validation du total** : Correspondance avec la somme des produits
5. **Limite de produits** : Maximum 100 produits par vente
6. **Protection contre les erreurs SQL** : Messages génériques en production
7. **Logs d'erreurs** : Utilisation de `error_log()` pour le débogage
8. **Code HTTP approprié** : 405 pour méthode non autorisée

## 📊 Résumé des changements

| Aspect | Avant | Après |
|--------|-------|-------|
| Validation stock | ❌ Aucune | ✅ Avant transaction |
| Validation types | ❌ Basique | ✅ Complète |
| Vérification existence | ❌ Aucune | ✅ Client, User, Products |
| Validation total | ❌ Aucune | ✅ Calcul et comparaison |
| Limite produits | ❌ Aucune | ✅ Max 100 |
| Gestion erreurs | ⚠️ Expose détails | ✅ Messages génériques |
| Logs | ❌ Aucun | ✅ error_log() |

