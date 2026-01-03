import 'package:flutter/material.dart';

/// Simple localisation manuelle pour deux langues (fr / en).
/// Pour aller plus loin, on pourrait basculer vers les ARB et flutter gen.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('fr'),
    Locale('en'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'fr': {
      'app_title': 'Gestion App',
      'login_title': 'Connectez-vous à votre compte',
      'login_username': "Nom d'utilisateur",
      'login_password': 'Mot de passe',
      'login_button': 'Se connecter',
      'login_error_empty':
          "Veuillez sélectionner un nom d'utilisateur et entrer un mot de passe.",
      'language_select_title': 'Choisissez votre langue',
      'language_select_description':
          'Vous pourrez la changer plus tard dans les paramètres.',
      'language_french': 'Français',
      'language_english': 'Anglais',
      'language_continue': 'Continuer',

      // Dashboard (admin)
      'dashboard_title_pos': 'Winner Phone Trading',
      'dashboard_menu_clients': 'Clients',
      'dashboard_menu_products': 'Produits',
      'dashboard_menu_sales': 'Ventes',
      'dashboard_menu_invoices': 'Factures',
      'dashboard_menu_reports': 'Rapports',
      'dashboard_menu_benefits': 'Bénéfice',
      'dashboard_menu_deposits': 'Dépôts',
      'dashboard_menu_expenses': 'Sorties',
      'dashboard_menu_stock_out': 'Stock Sortie',
      'dashboard_menu_logout': 'Déconnexion',
      'dashboard_menu_language': 'Langue',
      'dashboard_fab_new_sale_tooltip': 'Nouvelle vente',
      'dashboard_key_stats_title': 'Statistiques clés',
      'dashboard_perf_overview_title': 'Aperçu des performances',
      'dashboard_stat_clients': 'Clients',
      'dashboard_stat_products': 'Produits',
      'dashboard_stat_sales': 'Ventes',
      'dashboard_stat_invoices': 'Factures',
      'dashboard_stat_total_sales_amount': 'Total des ventes',
      'dashboard_stat_revenue': 'Chiffre d\'affaires',
      'dashboard_stat_total_deposits': 'Total dépôts',
      'dashboard_menu_chiffre_affaire': 'Chiffre d\'affaire',
      'dashboard_period_6_months': '6 derniers mois',
      'dashboard_period_12_months': '12 derniers mois',
      'dashboard_period_current_year': 'Année en cours',
      'dashboard_chart_no_data':
          'Aucune donnée de vente disponible pour le graphique.',
      'dashboard_user_welcome': 'Bienvenue sur votre tableau de bord!',

      // Add Product page
      'add_product_title': 'Ajouter un Produit',
      'add_product_name_label': 'Nom du produit',
      'add_product_description_label': 'Description',
      'add_product_price_label': 'Prix d\'achat',
      'add_product_sale_price_label': 'Prix de vente',
      'add_product_quantity_label': 'Quantité',
      'add_product_button': 'Ajouter le produit',
      'add_product_field_required': 'Ce champ est obligatoire',
      'add_product_invalid_number': 'Veuillez entrer un nombre valide',
      'add_product_success': 'Produit ajouté avec succès !',
      'add_product_error': 'Erreur : {message}',
      'add_product_http_error': 'Erreur HTTP: {code}',
      'add_product_connection_error': 'Erreur de connexion : {error}',

      // Benefice page
      'benefice_title': 'Bénéfice',
      'benefice_calculation_title': 'Calcul du bénéfice',
      'benefice_day_label': 'Jour',
      'benefice_month_label': 'Mois',
      'benefice_year_label': 'Année',
      'benefice_gross_profit_label': 'Bénéfice brut pour la période sélectionnée :',
      'benefice_expenses_label': 'Dépenses déclarées :',
      'benefice_exact_profit_label': 'Bénéfice exact :',
      'benefice_load_error': 'Erreur lors du chargement du bénéfice',
      'benefice_server_error': 'Erreur serveur ({code})',
      'benefice_connection_error': 'Erreur de connexion: {error}',

      // Chiffre d'affaire page
      'chiffre_affaire_title': 'Chiffre d\'affaire',
      'chiffre_affaire_filters': 'Filtres',
      'chiffre_affaire_start_date': 'Date de début',
      'chiffre_affaire_end_date': 'Date de fin',
      'chiffre_affaire_group_by': 'Grouper par',
      'chiffre_affaire_group_by_all': 'Tout',
      'chiffre_affaire_group_by_day': 'Jour',
      'chiffre_affaire_group_by_month': 'Mois',
      'chiffre_affaire_group_by_year': 'Année',
      'chiffre_affaire_group_by_product': 'Produit',
      'chiffre_affaire_reset': 'Réinitialiser',
      'chiffre_affaire_total': 'Total chiffre d\'affaire',
      'chiffre_affaire_sales_count': 'Nombre de ventes',
      'chiffre_affaire_products_sold': 'Produits vendus',
      'chiffre_affaire_avg_sale': 'Vente moyenne',
      'chiffre_affaire_total_stock': 'Valeur du stock',
      'chiffre_affaire_details_by_period': 'Détail par période',
      'chiffre_affaire_details_by_product': 'Détail par produit',

      // Dash Vendeur
      'vendor_dashboard_title': 'Tableau de bord vendeur',
      'vendor_menu_dashboard': 'Tableau de bord',
      'vendor_menu_sales': 'Ventes',
      'vendor_menu_invoices': 'Factures',
      'vendor_menu_clients': 'Clients',
      'vendor_menu_products': 'Produits',
      'vendor_menu_deposits': 'Dépôts',
      'vendor_menu_expenses': 'Sorties',
      'vendor_menu_stock_out': 'Sortie de stock',
      'vendor_menu_logout': 'Déconnexion',
      'vendor_action_refresh': 'Actualiser',
      'vendor_action_filter_date': 'Filtrer par date',
      'vendor_action_reset_filter': 'Réinitialiser le filtre',
      'vendor_empty_no_sales': 'Aucune vente enregistrée',
      'vendor_empty_no_sales_for_date': 'Aucune vente pour cette date',
      'vendor_empty_hint': 'Les ventes apparaîtront ici',
      'vendor_empty_hint_other_date': 'Essayez une autre date',
      'vendor_total_deposits_title': 'Total des dépôts enregistrés',
      'vendor_total_caisse_title': 'Total caisse',
      'vendor_fab_new_sale': 'Nouvelle vente',
      'vendor_new_sale_notification': 'Nouvelle vente enregistrée !',
      'vendor_data_updated': 'Données mises à jour',
      'vendor_load_error': 'Erreur lors du chargement des ventes',
      'vendor_server_error': 'Erreur serveur ({code})',
      'vendor_connection_error': 'Erreur de connexion: {error}',
      'vendor_sale_item_title': 'Vente #{id} - {client}',
      'vendor_sale_item_subtitle': 'Montant: {amount} \$ \nDate: {date}',

      // Deposit Page
      'deposit_title': 'Nouveau dépôt',
      'deposit_client_label': 'Client',
      'deposit_search_client': 'Rechercher un client',
      'deposit_search_client_hint': 'Tapez le nom du client...',
      'deposit_no_clients': 'Aucun client enregistré',
      'deposit_no_client_found': 'Aucun client trouvé',
      'deposit_product_label': 'Produit',
      'deposit_select_product': 'Sélectionner un produit',
      'deposit_product_not_found': 'Produit introuvable ? Ajouter un produit',
      'deposit_amount_label': 'Montant du dépôt',
      'deposit_date_label': 'Date du dépôt',
      'deposit_save_button': 'Enregistrer le dépôt',
      'deposit_saving': 'Enregistrement...',
      'deposit_history_title': 'Historique des dépôts pour ce client et ce produit',
      'deposit_total_deposited': 'Total déjà déposé',
      'deposit_remaining_to_pay': 'Reste à payer : ',
      'deposit_no_deposits_found': 'Aucun dépôt trouvé pour cette sélection.',
      'deposit_reserved': 'Réservé',
      'deposit_out_of_stock': 'Hors stock',
      'deposit_close_button': 'Clôturer',
      'deposit_deliver_button': 'Livrer',
      'deposit_deliver_confirm': 'Créer la vente et livrer le produit ?',
      'deposit_deliver_success': 'Vente créée et produit livré avec succès.',
      'deposit_deliver_error': 'Erreur lors de la création de la vente.',
      'deposit_client_credit': 'Crédit client : ',
      'deposit_success': 'Dépôt enregistré avec succès.',
      'deposit_error': 'Erreur lors de l\'enregistrement du dépôt.',
      'deposit_connection_error': 'Erreur de connexion : {error}',
      'deposit_select_client_product': 'Veuillez sélectionner un client et un produit.',
      'deposit_amount_positive': 'Le montant doit être supérieur à 0.',
      'deposit_printer_error': 'Impossible de se connecter à l\'imprimante pour le reçu.',
      'deposit_print_error': 'Erreur lors de l\'impression du reçu: {error}',
      'deposit_receipt_title': 'REÇU DE DÉPÔT',
      'deposit_receipt_number': 'N° dépôt : {id}',
      'deposit_receipt_date': 'Date : {date}',
      'deposit_receipt_client': 'Client',
      'deposit_receipt_client_name': 'Nom : {name}',
      'deposit_receipt_product': 'Produit',
      'deposit_receipt_amount': 'Montant du dépôt',
      'deposit_receipt_stock_status': 'Statut stock',
      'deposit_receipt_reserved': 'Produit réservé (stock débité)',
      'deposit_receipt_not_reserved': 'Hors stock',
      'deposit_receipt_stock_empty': 'Stock vide',
      'deposit_receipt_proof': 'Ce reçu fait office de preuve de paiement du dépôt.',
      'deposit_receipt_thanks': 'Merci pour votre confiance.',

      // Additional Deposit Page
      'additional_deposit_title': 'Dépôt supplémentaire',
      'additional_deposit_client': 'Client',
      'additional_deposit_product': 'Produit',
      'additional_deposit_amount_label': 'Montant du dépôt supplémentaire',
      'additional_deposit_date_label': 'Date du dépôt',
      'additional_deposit_save_button': 'Enregistrer et imprimer',

      // Deposits Overview Page
      'deposits_overview_title': 'Deposits',
      'deposits_overview_load_error': 'Erreur lors du chargement des dépôts.',
      'deposits_overview_server_error': 'Erreur serveur ({code})',
      'deposits_overview_connection_error': 'Erreur de connexion : {error}',
      'deposits_overview_empty': 'Aucun deposit enregistré',
      'deposits_overview_total_deposits': 'Total deposits : ',
      'deposits_overview_remaining_total': 'Reste à payer total : ',
      'deposits_overview_history_title': 'Deposits - {client}',
      'deposits_overview_total': 'Total deposits',
      'deposits_overview_no_deposits_client': 'Aucun deposit pour ce client.',
      'deposits_overview_add_button': 'Ajouter un dépôt supplémentaire',
      'deposits_overview_add_tooltip': 'Ajouter un deposit',
      'deposits_overview_load_history_error': 'Erreur lors du chargement.',

      // Detail Sale Page
      'detail_sale_title': 'Détail de la vente',
      'detail_sale_load_error': 'Erreur lors du chargement de la vente',
      'detail_sale_server_error': 'Erreur serveur ({code})',
      'detail_sale_connection_error': 'Erreur de connexion: {error}',
      'detail_sale_id': 'Vente #{id}',
      'detail_sale_date': 'Date : {date}',
      'detail_sale_client': 'Client : {name}',
      'detail_sale_phone': 'Téléphone : {phone}',
      'detail_sale_address': 'Adresse : {address}',
      'detail_sale_product': 'Produit',
      'detail_sale_quantity': 'Quantité',
      'detail_sale_unit_price': 'Prix unitaire',
      'detail_sale_total': 'Total',
      'detail_sale_total_label': 'Total : ',

      // Client page
      'client_title': 'Clients',
      'client_unexpected_format': 'Format de réponse inattendu.',
      'client_load_error': 'Erreur lors du chargement des clients ({code})',
      'client_connection_error': 'Erreur de connexion: {error}',
      'client_empty_title': 'Aucun client enregistré',
      'client_empty_hint': 'Les clients ajoutés apparaîtront ici',
      'client_unknown_name': 'Nom inconnu',

      // Product Page
      'product_session_not_found': 'Session non trouvée. Veuillez vous reconnecter.',
      'product_load_error': 'Erreur lors du chargement des produits.',
      'product_unauthorized': 'Non autorisé. Session expirée ou invalide. Veuillez vous reconnecter.',
      'product_http_error': 'Échec du chargement des produits: HTTP {code}',
      'product_connection_error': 'Erreur de connexion au serveur: {error}',
      'product_add_tooltip': 'Ajouter un nouveau produit',
      'product_title': 'Produits et Stock',
      'product_refresh_tooltip': 'Actualiser la liste des produits',
      'product_retry_button': 'Réessayer',
      'product_search_hint': 'Rechercher un produit par nom ou description...',
      'product_total_products': 'Total Produits',
      'product_in_stock': 'En Stock',
      'product_out_of_stock': 'Rupture',
      'product_no_products': 'Aucun produit trouvé',
      'product_no_search_results': 'Aucun produit correspond à votre recherche',
      'product_stock_out': 'Rupture de stock',
      'product_stock_low': 'Stock faible',
      'product_stock_available': 'En stock',
      'product_edit_tooltip': 'Modifier ce produit',
      'product_purchase_price': 'Prix d\'achat:',
      'product_sale_price': 'Prix de vente:',
      'product_quantity_label': 'Quantité:',
      'product_added_on': 'Ajouté le: {date}',
      'product_edit_dialog_title': 'Modifier le produit',
      'product_edit_name': 'Nom : {name}',
      'product_edit_description': 'Description : {description}',
      'product_edit_purchase_price': 'Prix d\'achat',
      'product_edit_sale_price': 'Prix de vente',
      'product_edit_quantity': 'Quantité',
      'product_edit_cancel': 'Annuler',
      'product_edit_save': 'Enregistrer',
      'product_update_success': 'Produit modifié avec succès',
      'product_update_error': 'Erreur lors de la modification du produit :\n{message}',
      'product_update_http_error': 'Erreur HTTP: {code}',
      'product_update_connection_error': 'Échec de la connexion au serveur: {error}',

      // Report Page
      'report_title': 'Rapports',
      'report_tab_sales': 'Ventes',
      'report_tab_low_stock': 'Stock faible',
      'report_tab_top_clients': 'Top clients',
      'report_tab_unpaid': 'Impayées',
      'report_date_from': 'Du',
      'report_date_to': 'Au',
      'report_filter_button': 'Filtrer',
      'report_load_error': 'Erreur lors du chargement des rapports',
      'report_server_error': 'Erreur serveur ({code})',
      'report_connection_error': 'Erreur de connexion: {error}',
      'report_no_sales': 'Aucune vente trouvée',
      'report_no_sales_period': 'Aucune vente pour la période sélectionnée',
      'report_sales_column_id': 'ID',
      'report_sales_column_client': 'Client',
      'report_sales_column_date': 'Date',
      'report_sales_column_total': 'Total',
      'report_no_low_stock': 'Aucun produit en stock faible',
      'report_all_stock_sufficient': 'Tous les produits ont un stock suffisant',
      'report_low_stock_column_id': 'ID',
      'report_low_stock_column_name': 'Nom',
      'report_low_stock_column_quantity': 'Quantité',
      'report_low_stock_column_price': 'Prix',
      'report_no_clients': 'Aucun client trouvé',
      'report_no_clients_period': 'Aucun client pour la période sélectionnée',
      'report_top_clients_column_client': 'Client',
      'report_top_clients_column_total': 'Total achats',
      'report_no_unpaid': 'Aucune facture impayée',
      'report_all_invoices_paid': 'Toutes les factures sont payées',
      'report_unpaid_column_id': 'ID',
      'report_unpaid_column_client': 'Client',
      'report_unpaid_column_date': 'Date',
      'report_unpaid_column_amount': 'Montant',

      // Sale List Page
      'sale_list_title': 'Liste des Ventes',
      'sale_list_sort_by_date': 'Trier par date',
      'sale_list_sort_by_month': 'Trier par mois',
      'sale_list_sort_by_year': 'Trier par année',
      'sale_list_load_error': 'Erreur lors du chargement des ventes',
      'sale_list_server_error': 'Erreur serveur ({code})',
      'sale_list_connection_error': 'Erreur de connexion: {error}',
      'sale_list_no_sales': 'Aucune vente trouvée',
      'sale_list_empty_hint': 'Les ventes enregistrées apparaîtront ici',
      'sale_list_client_label': 'Client : {name}',
      'sale_list_date_label': 'Date : {date}',
      'sale_list_unknown': 'Inconnue',

      // Sortie Page
      'sortie_title': 'Sorties de caisse',
      'sortie_load_error': 'Erreur lors du chargement des sorties',
      'sortie_server_error': 'Erreur serveur ({code})',
      'sortie_connection_error': 'Erreur de connexion: {error}',
      'sortie_fill_all_fields': 'Veuillez remplir tous les champs.',
      'sortie_username_not_found': 'Nom d\'utilisateur non trouvé. Réessayez de vous connecter.',
      'sortie_success': 'Sortie enregistrée avec succès!',
      'sortie_save_error': 'Erreur lors de l\'enregistrement.',
      'sortie_error': 'Erreur: {error}',
      'sortie_user_label': 'Utilisateur: {username}',
      'sortie_new_title': 'Nouvelle sortie',
      'sortie_amount_label': 'Montant',
      'sortie_motif_label': 'Motif',
      'sortie_type_label': 'Type',
      'sortie_type_normal': 'Normal',
      'sortie_type_transaction': 'Transaction',
      'sortie_save_button': 'Enregistrer la sortie',
      'sortie_filter_all': 'Tous',
      'sortie_filter_day': 'Jour',
      'sortie_filter_month': 'Mois',
      'sortie_filter_year': 'Année',
      'sortie_no_sorties': 'Aucune sortie enregistrée',
      'sortie_empty_hint': 'Les sorties de caisse apparaîtront ici',
      'sortie_column_id': '#',
      'sortie_column_user': 'Utilisateur',
      'sortie_column_amount': 'Montant',
      'sortie_column_motif': 'Motif',
      'sortie_column_type': 'Type',
      'sortie_column_date': 'Date',

      // Stock Add Out (New Sale Page)
      'stock_add_out_title': 'Nouvelle Vente',
      'stock_add_out_load_error': 'Erreur lors du chargement des produits.',
      'stock_add_out_connection_error': 'Erreur de connexion : {error}',
      'stock_add_out_insufficient_stock': 'Pas assez de stock pour {product}.',
      'stock_add_out_empty_cart': 'Le panier est vide.',
      'stock_add_out_enter_client': 'Veuillez entrer le nom du client.',
      'stock_add_out_add_client_error': 'Erreur lors de l\'ajout du nouveau client.',
      'stock_add_out_server_error': 'Erreur serveur ({code}) lors de la création du client.',
      'stock_add_out_client_connection_error': 'Erreur de connexion lors de la création du client : {error}',
      'stock_add_out_success': 'Vente enregistrée avec succès !',
      'stock_add_out_error': 'Erreur: {message}',
      'stock_add_out_connection_error_sale': 'Erreur de connexion : {error}',
      'stock_add_out_client_not_found': 'Client non trouvé',
      'stock_add_out_client_not_found_message': 'Le client "{name}" n\'existe pas. Voulez-vous l\'ajouter ?',
      'stock_add_out_cancel': 'Annuler',
      'stock_add_out_add': 'Ajouter',
      'stock_add_out_client_name_label': 'Nom du client',
      'stock_add_out_search_product': 'Rechercher un produit...',
      'stock_add_out_no_products': 'Aucun produit disponible.',
      'stock_add_out_product_subtitle': '{price} \$ - Stock: {quantity}',
      'stock_add_out_validate_sale': 'Valider la vente',
      'stock_add_out_cart': 'Panier',
      'stock_add_out_quantity_label': 'Quantité: {quantity} x {price} \$',
      'stock_add_out_total': 'Total: {total} \$',

      // Vente Page
      'vente_title': 'Nouvelle Vente',
      'vente_load_error': 'Erreur de chargement: {error}',
      'vente_retry': 'Réessayer',
      'vente_step_client': 'Client',
      'vente_step_address': 'Adresse',
      'vente_step_warranty': 'Garantie',
      'vente_step_products': 'Produits',
      'vente_client_info_title': 'Informations Client',
      'vente_search_existing_client': 'Rechercher un client existant',
      'vente_search_client_label': 'Rechercher un client',
      'vente_search_client_hint': 'Tapez le nom du client...',
      'vente_no_clients_registered': 'Aucun client enregistré',
      'vente_no_client_found': 'Aucun client trouvé',
      'vente_client_selected': 'Client sélectionné: {name}',
      'vente_or': 'OU',
      'vente_create_new_client': 'Créer un nouveau client',
      'vente_new_client_name_label': 'Nom du nouveau client *',
      'vente_new_client_name_hint': 'Entrez le nom du client',
      'vente_required_fields': '* Champs obligatoires',
      'vente_no_clients_info': 'Aucun client enregistré. Créez un nouveau client pour continuer.',
      'vente_address_title': 'Adresse et Informations',
      'vente_address_label': 'Adresse',
      'vente_address_hint': 'Adresse du client (optionnel)',
      'vente_imei_label': 'IMEI',
      'vente_imei_hint': 'Numéro IMEI (optionnel)',
      'vente_warranty_title': 'Garantie',
      'vente_warranty_label': 'Durée de garantie',
      'vente_warranty_hint': 'Ex: 6 mois, 1 an, 2 ans...',
      'vente_warranty_optional': 'La garantie est optionnelle. Vous pouvez laisser ce champ vide.',
      'vente_search_product_label': 'Rechercher un produit',
      'vente_search_product_hint': 'Tapez le nom ou l\'ID du produit...',
      'vente_no_product_found': 'Aucun produit trouvé',
      'vente_stock_label': 'Stock: {quantity}',
      'vente_price_label': 'Prix: {price} \$',
      'vente_product_added': 'Ajouté',
      'vente_product_out_of_stock': 'Rupture',
      'vente_search_limit_message': 'Affichage des 20 premiers résultats. Affinez votre recherche pour plus de résultats.',
      'vente_products_title': 'Produits à Vendre',
      'vente_selected_products': 'Produits sélectionnés',
      'vente_original_price': 'Prix original: {price}',
      'vente_price': 'Prix: {price}',
      'vente_total': 'Total:',
      'vente_no_products_selected': 'Aucun produit sélectionné',
      'vente_no_products_hint': 'Utilisez la barre de recherche ci-dessus\npour ajouter des produits à la vente',
      'vente_previous': 'Précédent',
      'vente_next': 'Suivant',
      'vente_saving': 'Enregistrement...',
      'vente_finish_sale': 'Terminer la vente',
      'vente_modify_price': 'Modifier le prix',
      'vente_new_price_label': 'Nouveau prix',
      'vente_new_price_hint': 'Entrez le nouveau prix',
      'vente_price_required': 'Le prix est obligatoire',
      'vente_price_invalid': 'Veuillez entrer un nombre valide',
      'vente_price_negative': 'Le prix ne peut pas être négatif',
      'vente_price_too_high': 'Le prix semble trop élevé',
      'vente_reduction': 'Réduction: {amount}',
      'vente_reduction_percent': '{percent}% de réduction',
      'vente_increase': 'Augmentation: {amount}',
      'vente_increase_percent': '+{percent}%',
      'vente_reset': 'Réinitialiser',
      'vente_save': 'Enregistrer',
      'vente_cancel': 'Annuler',
      'vente_delete_tooltip': 'Supprimer',
      'vente_edit_price_tooltip': 'Modifier le prix',
      'vente_max_quantity': 'Quantité maximale disponible: {quantity}',
      'vente_product_removed': 'Produit retiré de la vente',
      'vente_price_modified': 'Prix modifié avec succès',
      'vente_sale_recorded': 'Vente enregistrée avec succès',
      'vente_sale_recorded_title': 'Vente enregistrée avec succès',
      'vente_close': 'Fermer',
      'vente_print_invoice': 'Imprimer la facture',
      'vente_info_client': 'Client',
      'vente_info_total': 'Total',
      'vente_info_date': 'Date',
      'vente_info_imei': 'IMEI',
      'vente_info_warranty': 'Garantie',
      'vente_error_loading_products': 'Erreur lors du chargement des produits',
      'vente_error_server': 'Erreur serveur ({code})',
      'vente_error_connection': 'Erreur de connexion: {error}',
      'vente_error_server_client': 'Erreur serveur ({code}) lors de la création du client.',
      'vente_error_connection_client': 'Erreur de connexion lors de la création du client : {error}',
      'vente_error_create_client': 'Erreur lors de la création du client',
      'vente_error_select_client': 'Veuillez sélectionner ou créer un client',
      'vente_error_product_already_added': 'Ce produit est déjà dans la liste',
      'vente_error_insufficient_stock': 'Stock insuffisant pour {product}',
      'vente_error_select_client_sale': 'Veuillez sélectionner un client',
      'vente_error_select_products': 'Veuillez sélectionner au moins un produit',
      'vente_error_sale': 'Erreur lors de la vente',
      'vente_error_server_response': 'Erreur de format de réponse du serveur',
      'vente_error_timeout': 'Timeout: Le serveur ne répond pas',
      'vente_error_generate_invoice': 'Erreur lors de la génération de la facture',
      'vente_product_added_to_sale': '{product} ajouté à la vente',
    },
    'en': {
      'app_title': 'Management App',
      'login_title': 'Sign in to your account',
      'login_username': 'Username',
      'login_password': 'Password',
      'login_button': 'Sign in',
      'login_error_empty':
          'Please select a username and enter a password.',
      'language_select_title': 'Choose your language',
      'language_select_description':
          'You will be able to change it later in settings.',
      'language_french': 'French',
      'language_english': 'English',
      'language_continue': 'Continue',

      // Dashboard (admin)
      'dashboard_title_pos': 'POS Dashboard',
      'dashboard_menu_clients': 'Clients',
      'dashboard_menu_products': 'Products',
      'dashboard_menu_sales': 'Sales',
      'dashboard_menu_invoices': 'Invoices',
      'dashboard_menu_reports': 'Reports',
      'dashboard_menu_benefits': 'Profit',
      'dashboard_menu_deposits': 'Deposits',
      'dashboard_menu_expenses': 'Expenses',
      'dashboard_menu_stock_out': 'Stock Out',
      'dashboard_menu_logout': 'Logout',
      'dashboard_menu_language': 'Language',
      'dashboard_fab_new_sale_tooltip': 'New sale',
      'dashboard_key_stats_title': 'Key statistics',
      'dashboard_perf_overview_title': 'Performance overview',
      'dashboard_stat_clients': 'Clients',
      'dashboard_stat_products': 'Products',
      'dashboard_stat_sales': 'Sales',
      'dashboard_stat_invoices': 'Invoices',
      'dashboard_stat_total_sales_amount': 'Total sales',
      'dashboard_stat_revenue': 'Revenue',
      'dashboard_stat_total_deposits': 'Total deposits',
      'dashboard_period_6_months': 'Last 6 months',
      'dashboard_period_12_months': 'Last 12 months',
      'dashboard_period_current_year': 'Current year',
      'dashboard_chart_no_data': 'No sales data available for the chart.',
      'dashboard_user_welcome': 'Welcome to your dashboard!',

      // Add Product page
      'add_product_title': 'Add Product',
      'add_product_name_label': 'Product name',
      'add_product_description_label': 'Description',
      'add_product_price_label': 'Purchase price',
      'add_product_sale_price_label': 'Sale price',
      'add_product_quantity_label': 'Quantity',
      'add_product_button': 'Add product',
      'add_product_field_required': 'This field is required',
      'add_product_invalid_number': 'Please enter a valid number',
      'add_product_success': 'Product added successfully!',
      'add_product_error': 'Error: {message}',
      'add_product_http_error': 'HTTP error: {code}',
      'add_product_connection_error': 'Connection error: {error}',

      // Benefice page
      'benefice_title': 'Profit',
      'benefice_calculation_title': 'Profit calculation',
      'benefice_day_label': 'Day',
      'benefice_month_label': 'Month',
      'benefice_year_label': 'Year',
      'benefice_gross_profit_label': 'Gross profit for the selected period:',
      'benefice_expenses_label': 'Declared expenses:',
      'benefice_exact_profit_label': 'Exact profit:',
      'benefice_load_error': 'Error loading profit',
      'benefice_server_error': 'Server error ({code})',
      'benefice_connection_error': 'Connection error: {error}',

      // Dash Vendeur
      'vendor_new_sale_notification': 'New sale recorded!',
      'vendor_data_updated': 'Data updated',
      'vendor_load_error': 'Error loading sales',
      'vendor_server_error': 'Server error ({code})',
      'vendor_connection_error': 'Connection error: {error}',
      'vendor_sale_item_title': 'Sale #{id} - {client}',
      'vendor_sale_item_subtitle': 'Amount: {amount} \$ \nDate: {date}',

      // Deposit Page
      'deposit_title': 'New Deposit',
      'deposit_client_label': 'Client',
      'deposit_search_client': 'Search for a client',
      'deposit_search_client_hint': 'Type the client name...',
      'deposit_no_clients': 'No clients registered',
      'deposit_no_client_found': 'No client found',
      'deposit_product_label': 'Product',
      'deposit_select_product': 'Select a product',
      'deposit_product_not_found': 'Product not found? Add a product',
      'deposit_amount_label': 'Deposit amount',
      'deposit_date_label': 'Deposit date',
      'deposit_save_button': 'Save deposit',
      'deposit_saving': 'Saving...',
      'deposit_history_title': 'Deposit history for this client and product',
      'deposit_total_deposited': 'Total already deposited',
      'deposit_remaining_to_pay': 'Remaining to pay: ',
      'deposit_no_deposits_found': 'No deposits found for this selection.',
      'deposit_reserved': 'Reserved',
      'deposit_out_of_stock': 'Out of stock',
      'deposit_close_button': 'Close',
      'deposit_deliver_button': 'Deliver',
      'deposit_deliver_confirm': 'Create sale and deliver product?',
      'deposit_deliver_success': 'Sale created and product delivered successfully.',
      'deposit_deliver_error': 'Error creating sale.',
      'deposit_client_credit': 'Client credit: ',
      'deposit_success': 'Deposit recorded successfully.',
      'deposit_error': 'Error recording deposit.',
      'deposit_connection_error': 'Connection error: {error}',
      'deposit_select_client_product': 'Please select a client and a product.',
      'deposit_amount_positive': 'The amount must be greater than 0.',
      'deposit_printer_error': 'Unable to connect to printer for receipt.',
      'deposit_print_error': 'Error printing receipt: {error}',
      'deposit_receipt_title': 'DEPOSIT RECEIPT',
      'deposit_receipt_number': 'Deposit #: {id}',
      'deposit_receipt_date': 'Date: {date}',
      'deposit_receipt_client': 'Client',
      'deposit_receipt_client_name': 'Name: {name}',
      'deposit_receipt_product': 'Product',
      'deposit_receipt_amount': 'Deposit amount',
      'deposit_receipt_stock_status': 'Stock status',
      'deposit_receipt_reserved': 'Product reserved (stock debited)',
      'deposit_receipt_not_reserved': 'Out of stock',
      'deposit_receipt_stock_empty': 'Stock empty',
      'deposit_receipt_proof': 'This receipt serves as proof of deposit payment.',
      'deposit_receipt_thanks': 'Thank you for your trust.',

      // Additional Deposit Page
      'additional_deposit_title': 'Additional Deposit',
      'additional_deposit_client': 'Client',
      'additional_deposit_product': 'Product',
      'additional_deposit_amount_label': 'Additional deposit amount',
      'additional_deposit_date_label': 'Deposit date',
      'additional_deposit_save_button': 'Save and print',

      // Deposits Overview Page
      'deposits_overview_title': 'Deposits',
      'deposits_overview_load_error': 'Error loading deposits.',
      'deposits_overview_server_error': 'Server error ({code})',
      'deposits_overview_connection_error': 'Connection error: {error}',
      'deposits_overview_empty': 'No deposits registered',
      'deposits_overview_total_deposits': 'Total deposits: ',
      'deposits_overview_remaining_total': 'Total remaining to pay: ',
      'deposits_overview_history_title': 'Deposits - {client}',
      'deposits_overview_total': 'Total deposits',
      'deposits_overview_no_deposits_client': 'No deposits for this client.',
      'deposits_overview_add_button': 'Add additional deposit',
      'deposits_overview_add_tooltip': 'Add a deposit',
      'deposits_overview_load_history_error': 'Error loading.',

      // Detail Sale Page
      'detail_sale_title': 'Sale Details',
      'detail_sale_load_error': 'Error loading sale',
      'detail_sale_server_error': 'Server error ({code})',
      'detail_sale_connection_error': 'Connection error: {error}',
      'detail_sale_id': 'Sale #{id}',
      'detail_sale_date': 'Date: {date}',
      'detail_sale_client': 'Client: {name}',
      'detail_sale_phone': 'Phone: {phone}',
      'detail_sale_address': 'Address: {address}',
      'detail_sale_product': 'Product',
      'detail_sale_quantity': 'Quantity',
      'detail_sale_unit_price': 'Unit price',
      'detail_sale_total': 'Total',
      'detail_sale_total_label': 'Total: ',

      // Client page
      'client_title': 'Clients',
      'client_unexpected_format': 'Unexpected response format.',
      'client_load_error': 'Error loading clients ({code})',
      'client_connection_error': 'Connection error: {error}',
      'client_empty_title': 'No clients registered',
      'client_empty_hint': 'Added clients will appear here',
      'client_unknown_name': 'Unknown name',

      // Product Page
      'product_session_not_found': 'Session not found. Please log in again.',
      'product_load_error': 'Error loading products.',
      'product_unauthorized': 'Unauthorized. Session expired or invalid. Please log in again.',
      'product_http_error': 'Failed to load products: HTTP {code}',
      'product_connection_error': 'Server connection error: {error}',
      'product_add_tooltip': 'Add a new product',
      'product_title': 'Products and Stock',
      'product_refresh_tooltip': 'Refresh product list',
      'product_retry_button': 'Retry',
      'product_search_hint': 'Search for a product by name or description...',
      'product_total_products': 'Total Products',
      'product_in_stock': 'In Stock',
      'product_out_of_stock': 'Out of Stock',
      'product_no_products': 'No products found',
      'product_no_search_results': 'No products match your search',
      'product_stock_out': 'Out of stock',
      'product_stock_low': 'Low stock',
      'product_stock_available': 'In stock',
      'product_edit_tooltip': 'Edit this product',
      'product_purchase_price': 'Purchase price:',
      'product_sale_price': 'Sale price:',
      'product_quantity_label': 'Quantity:',
      'product_added_on': 'Added on: {date}',
      'product_edit_dialog_title': 'Edit Product',
      'product_edit_name': 'Name: {name}',
      'product_edit_description': 'Description: {description}',
      'product_edit_purchase_price': 'Purchase price',
      'product_edit_sale_price': 'Sale price',
      'product_edit_quantity': 'Quantity',
      'product_edit_cancel': 'Cancel',
      'product_edit_save': 'Save',
      'product_update_success': 'Product updated successfully',
      'product_update_error': 'Error updating product:\n{message}',
      'product_update_http_error': 'HTTP error: {code}',
      'product_update_connection_error': 'Server connection failed: {error}',

      // Report Page
      'report_title': 'Reports',
      'report_tab_sales': 'Sales',
      'report_tab_low_stock': 'Low Stock',
      'report_tab_top_clients': 'Top Clients',
      'report_tab_unpaid': 'Unpaid',
      'report_date_from': 'From',
      'report_date_to': 'To',
      'report_filter_button': 'Filter',
      'report_load_error': 'Error loading reports',
      'report_server_error': 'Server error ({code})',
      'report_connection_error': 'Connection error: {error}',
      'report_no_sales': 'No sales found',
      'report_no_sales_period': 'No sales for the selected period',
      'report_sales_column_id': 'ID',
      'report_sales_column_client': 'Client',
      'report_sales_column_date': 'Date',
      'report_sales_column_total': 'Total',
      'report_no_low_stock': 'No products with low stock',
      'report_all_stock_sufficient': 'All products have sufficient stock',
      'report_low_stock_column_id': 'ID',
      'report_low_stock_column_name': 'Name',
      'report_low_stock_column_quantity': 'Quantity',
      'report_low_stock_column_price': 'Price',
      'report_no_clients': 'No clients found',
      'report_no_clients_period': 'No clients for the selected period',
      'report_top_clients_column_client': 'Client',
      'report_top_clients_column_total': 'Total purchases',
      'report_no_unpaid': 'No unpaid invoices',
      'report_all_invoices_paid': 'All invoices are paid',
      'report_unpaid_column_id': 'ID',
      'report_unpaid_column_client': 'Client',
      'report_unpaid_column_date': 'Date',
      'report_unpaid_column_amount': 'Amount',

      // Sale List Page
      'sale_list_title': 'Sales List',
      'sale_list_sort_by_date': 'Sort by date',
      'sale_list_sort_by_month': 'Sort by month',
      'sale_list_sort_by_year': 'Sort by year',
      'sale_list_load_error': 'Error loading sales',
      'sale_list_server_error': 'Server error ({code})',
      'sale_list_connection_error': 'Connection error: {error}',
      'sale_list_no_sales': 'No sales found',
      'sale_list_empty_hint': 'Recorded sales will appear here',
      'sale_list_client_label': 'Client: {name}',
      'sale_list_date_label': 'Date: {date}',
      'sale_list_unknown': 'Unknown',

      // Sortie Page
      'sortie_title': 'Cash Outflows',
      'sortie_load_error': 'Error loading outflows',
      'sortie_server_error': 'Server error ({code})',
      'sortie_connection_error': 'Connection error: {error}',
      'sortie_fill_all_fields': 'Please fill in all fields.',
      'sortie_username_not_found': 'Username not found. Please try logging in again.',
      'sortie_success': 'Outflow recorded successfully!',
      'sortie_save_error': 'Error saving.',
      'sortie_error': 'Error: {error}',
      'sortie_user_label': 'User: {username}',
      'sortie_new_title': 'New outflow',
      'sortie_amount_label': 'Amount',
      'sortie_motif_label': 'Reason',
      'sortie_type_label': 'Type',
      'sortie_type_normal': 'Normal',
      'sortie_type_transaction': 'Transaction',
      'sortie_save_button': 'Save outflow',
      'sortie_filter_all': 'All',
      'sortie_filter_day': 'Day',
      'sortie_filter_month': 'Month',
      'sortie_filter_year': 'Year',
      'sortie_no_sorties': 'No outflows recorded',
      'sortie_empty_hint': 'Cash outflows will appear here',
      'sortie_column_id': '#',
      'sortie_column_user': 'User',
      'sortie_column_amount': 'Amount',
      'sortie_column_motif': 'Reason',
      'sortie_column_type': 'Type',
      'sortie_column_date': 'Date',

      // Stock Add Out (New Sale Page)
      'stock_add_out_title': 'New Sale',
      'stock_add_out_load_error': 'Error loading products.',
      'stock_add_out_connection_error': 'Connection error: {error}',
      'stock_add_out_insufficient_stock': 'Insufficient stock for {product}.',
      'stock_add_out_empty_cart': 'The cart is empty.',
      'stock_add_out_enter_client': 'Please enter the client name.',
      'stock_add_out_add_client_error': 'Error adding new client.',
      'stock_add_out_server_error': 'Server error ({code}) while creating client.',
      'stock_add_out_client_connection_error': 'Connection error while creating client: {error}',
      'stock_add_out_success': 'Sale recorded successfully!',
      'stock_add_out_error': 'Error: {message}',
      'stock_add_out_connection_error_sale': 'Connection error: {error}',
      'stock_add_out_client_not_found': 'Client not found',
      'stock_add_out_client_not_found_message': 'The client "{name}" does not exist. Do you want to add them?',
      'stock_add_out_cancel': 'Cancel',
      'stock_add_out_add': 'Add',
      'stock_add_out_client_name_label': 'Client name',
      'stock_add_out_search_product': 'Search for a product...',
      'stock_add_out_no_products': 'No products available.',
      'stock_add_out_product_subtitle': '{price} \$ - Stock: {quantity}',
      'stock_add_out_validate_sale': 'Validate sale',
      'stock_add_out_cart': 'Cart',
      'stock_add_out_quantity_label': 'Quantity: {quantity} x {price} \$',
      'stock_add_out_total': 'Total: {total} \$',

      // Vente Page
      'vente_title': 'New Sale',
      'vente_load_error': 'Loading error: {error}',
      'vente_retry': 'Retry',
      'vente_step_client': 'Client',
      'vente_step_address': 'Address',
      'vente_step_warranty': 'Warranty',
      'vente_step_products': 'Products',
      'vente_client_info_title': 'Client Information',
      'vente_search_existing_client': 'Search for an existing client',
      'vente_search_client_label': 'Search for a client',
      'vente_search_client_hint': 'Type the client name...',
      'vente_no_clients_registered': 'No clients registered',
      'vente_no_client_found': 'No client found',
      'vente_client_selected': 'Client selected: {name}',
      'vente_or': 'OR',
      'vente_create_new_client': 'Create a new client',
      'vente_new_client_name_label': 'New client name *',
      'vente_new_client_name_hint': 'Enter the client name',
      'vente_required_fields': '* Required fields',
      'vente_no_clients_info': 'No clients registered. Create a new client to continue.',
      'vente_address_title': 'Address and Information',
      'vente_address_label': 'Address',
      'vente_address_hint': 'Client address (optional)',
      'vente_imei_label': 'IMEI',
      'vente_imei_hint': 'IMEI number (optional)',
      'vente_warranty_title': 'Warranty',
      'vente_warranty_label': 'Warranty duration',
      'vente_warranty_hint': 'Ex: 6 months, 1 year, 2 years...',
      'vente_warranty_optional': 'Warranty is optional. You can leave this field empty.',
      'vente_search_product_label': 'Search for a product',
      'vente_search_product_hint': 'Type the product name or ID...',
      'vente_no_product_found': 'No product found',
      'vente_stock_label': 'Stock: {quantity}',
      'vente_price_label': 'Price: {price} \$',
      'vente_product_added': 'Added',
      'vente_product_out_of_stock': 'Out of stock',
      'vente_search_limit_message': 'Showing first 20 results. Refine your search for more results.',
      'vente_products_title': 'Products to Sell',
      'vente_selected_products': 'Selected products',
      'vente_original_price': 'Original price: {price}',
      'vente_price': 'Price: {price}',
      'vente_total': 'Total:',
      'vente_no_products_selected': 'No products selected',
      'vente_no_products_hint': 'Use the search bar above\nto add products to the sale',
      'vente_previous': 'Previous',
      'vente_next': 'Next',
      'vente_saving': 'Saving...',
      'vente_finish_sale': 'Finish sale',
      'vente_modify_price': 'Modify price',
      'vente_new_price_label': 'New price',
      'vente_new_price_hint': 'Enter the new price',
      'vente_price_required': 'Price is required',
      'vente_price_invalid': 'Please enter a valid number',
      'vente_price_negative': 'Price cannot be negative',
      'vente_price_too_high': 'Price seems too high',
      'vente_reduction': 'Reduction: {amount}',
      'vente_reduction_percent': '{percent}% reduction',
      'vente_increase': 'Increase: {amount}',
      'vente_increase_percent': '+{percent}%',
      'vente_reset': 'Reset',
      'vente_save': 'Save',
      'vente_cancel': 'Cancel',
      'vente_delete_tooltip': 'Delete',
      'vente_edit_price_tooltip': 'Modify price',
      'vente_max_quantity': 'Maximum quantity available: {quantity}',
      'vente_product_removed': 'Product removed from sale',
      'vente_price_modified': 'Price modified successfully',
      'vente_sale_recorded': 'Sale recorded successfully',
      'vente_sale_recorded_title': 'Sale recorded successfully',
      'vente_close': 'Close',
      'vente_print_invoice': 'Print invoice',
      'vente_info_client': 'Client',
      'vente_info_total': 'Total',
      'vente_info_date': 'Date',
      'vente_info_imei': 'IMEI',
      'vente_info_warranty': 'Warranty',
      'vente_error_loading_products': 'Error loading products',
      'vente_error_server': 'Server error ({code})',
      'vente_error_connection': 'Connection error: {error}',
      'vente_error_server_client': 'Server error ({code}) while creating client.',
      'vente_error_connection_client': 'Connection error while creating client: {error}',
      'vente_error_create_client': 'Error creating client',
      'vente_error_select_client': 'Please select or create a client',
      'vente_error_product_already_added': 'This product is already in the list',
      'vente_error_insufficient_stock': 'Insufficient stock for {product}',
      'vente_error_select_client_sale': 'Please select a client',
      'vente_error_select_products': 'Please select at least one product',
      'vente_error_sale': 'Error during sale',
      'vente_error_server_response': 'Server response format error',
      'vente_error_timeout': 'Timeout: Server is not responding',
      'vente_error_generate_invoice': 'Error generating invoice',
      'vente_product_added_to_sale': '{product} added to sale',

      // Chiffre d'affaire page
      'chiffre_affaire_title': 'Revenue',
      'chiffre_affaire_filters': 'Filters',
      'chiffre_affaire_start_date': 'Start date',
      'chiffre_affaire_end_date': 'End date',
      'chiffre_affaire_group_by': 'Group by',
      'chiffre_affaire_group_by_all': 'All',
      'chiffre_affaire_group_by_day': 'Day',
      'chiffre_affaire_group_by_month': 'Month',
      'chiffre_affaire_group_by_year': 'Year',
      'chiffre_affaire_group_by_product': 'Product',
      'chiffre_affaire_reset': 'Reset',
      'chiffre_affaire_total': 'Total revenue',
      'chiffre_affaire_sales_count': 'Sales count',
      'chiffre_affaire_products_sold': 'Products sold',
      'chiffre_affaire_avg_sale': 'Average sale',
      'chiffre_affaire_total_stock': 'Stock value',
      'chiffre_affaire_details_by_period': 'Details by period',
      'chiffre_affaire_details_by_product': 'Details by product',

      // Vendor dashboard
      'vendor_dashboard_title': 'Salesperson dashboard',
      'vendor_menu_dashboard': 'Dashboard',
      'vendor_menu_sales': 'Sales',
      'vendor_menu_invoices': 'Invoices',
      'vendor_menu_clients': 'Clients',
      'vendor_menu_products': 'Products',
      'vendor_menu_deposits': 'Deposits',
      'vendor_menu_expenses': 'Expenses',
      'vendor_menu_stock_out': 'Stock out',
      'vendor_menu_logout': 'Logout',
      'vendor_action_refresh': 'Refresh',
      'vendor_action_filter_date': 'Filter by date',
      'vendor_action_reset_filter': 'Reset filter',
      'vendor_empty_no_sales': 'No sales recorded',
      'vendor_empty_no_sales_for_date': 'No sales for this date',
      'vendor_empty_hint': 'Sales will appear here',
      'vendor_empty_hint_other_date': 'Try another date',
      'vendor_total_deposits_title': 'Total recorded deposits',
      'vendor_fab_new_sale': 'New sale',
    },
  };

  String _t(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['fr']?[key] ??
        key;
  }

  String get appTitle => _t('app_title');

  String get loginTitle => _t('login_title');
  String get loginUsername => _t('login_username');
  String get loginPassword => _t('login_password');
  String get loginButton => _t('login_button');
  String get loginErrorEmpty => _t('login_error_empty');

  String get languageSelectTitle => _t('language_select_title');
  String get languageSelectDescription => _t('language_select_description');
  String get languageFrench => _t('language_french');
  String get languageEnglish => _t('language_english');
  String get languageContinue => _t('language_continue');

  // Dashboard getters
  String get dashboardTitlePos => _t('dashboard_title_pos');
  String get dashboardMenuClients => _t('dashboard_menu_clients');
  String get dashboardMenuProducts => _t('dashboard_menu_products');
  String get dashboardMenuSales => _t('dashboard_menu_sales');
  String get dashboardMenuInvoices => _t('dashboard_menu_invoices');
  String get dashboardMenuReports => _t('dashboard_menu_reports');
  String get dashboardMenuBenefits => _t('dashboard_menu_benefits');
  String get dashboardMenuDeposits => _t('dashboard_menu_deposits');
  String get dashboardMenuChiffreAffaire => _t('dashboard_menu_chiffre_affaire');
  String get dashboardMenuExpenses => _t('dashboard_menu_expenses');
  String get dashboardMenuStockOut => _t('dashboard_menu_stock_out');
  String get dashboardMenuLogout => _t('dashboard_menu_logout');
  String get dashboardMenuLanguage => _t('dashboard_menu_language');
  String get dashboardFabNewSaleTooltip => _t('dashboard_fab_new_sale_tooltip');
  String get dashboardKeyStatsTitle => _t('dashboard_key_stats_title');
  String get dashboardPerfOverviewTitle => _t('dashboard_perf_overview_title');
  String get dashboardStatClients => _t('dashboard_stat_clients');
  String get dashboardStatProducts => _t('dashboard_stat_products');
  String get dashboardStatSales => _t('dashboard_stat_sales');
  String get dashboardStatInvoices => _t('dashboard_stat_invoices');
  String get dashboardStatTotalSalesAmount =>
      _t('dashboard_stat_total_sales_amount');
  String get dashboardStatRevenue => _t('dashboard_stat_revenue');
  String get dashboardStatTotalDeposits =>
      _t('dashboard_stat_total_deposits');
  String get dashboardPeriod6Months => _t('dashboard_period_6_months');
  String get dashboardPeriod12Months => _t('dashboard_period_12_months');
  String get dashboardPeriodCurrentYear =>
      _t('dashboard_period_current_year');
  String get dashboardChartNoData => _t('dashboard_chart_no_data');
  String get dashboardUserWelcome => _t('dashboard_user_welcome');

  // Vendor dashboard getters
  String get vendorDashboardTitle => _t('vendor_dashboard_title');
  String get vendorMenuDashboard => _t('vendor_menu_dashboard');
  String get vendorMenuSales => _t('vendor_menu_sales');
  String get vendorMenuInvoices => _t('vendor_menu_invoices');
  String get vendorMenuClients => _t('vendor_menu_clients');
  String get vendorMenuProducts => _t('vendor_menu_products');
  String get vendorMenuDeposits => _t('vendor_menu_deposits');
  String get vendorMenuExpenses => _t('vendor_menu_expenses');
  String get vendorMenuStockOut => _t('vendor_menu_stock_out');
  String get vendorMenuLogout => _t('vendor_menu_logout');
  String get vendorActionRefresh => _t('vendor_action_refresh');
  String get vendorActionFilterDate => _t('vendor_action_filter_date');
  String get vendorActionResetFilter => _t('vendor_action_reset_filter');
  String get vendorEmptyNoSales => _t('vendor_empty_no_sales');
  String get vendorEmptyNoSalesForDate =>
      _t('vendor_empty_no_sales_for_date');
  String get vendorEmptyHint => _t('vendor_empty_hint');
  String get vendorEmptyHintOtherDate =>
      _t('vendor_empty_hint_other_date');
  String get vendorTotalDepositsTitle =>
      _t('vendor_total_deposits_title');
  String get vendorTotalCaisseTitle =>
      _t('vendor_total_caisse_title');
  String get vendorFabNewSale => _t('vendor_fab_new_sale');

  // Chiffre d'affaire getters
  String get chiffreAffaireTitle => _t('chiffre_affaire_title');
  String get chiffreAffaireFilters => _t('chiffre_affaire_filters');
  String get chiffreAffaireStartDate => _t('chiffre_affaire_start_date');
  String get chiffreAffaireEndDate => _t('chiffre_affaire_end_date');
  String get chiffreAffaireGroupBy => _t('chiffre_affaire_group_by');
  String get chiffreAffaireGroupByAll => _t('chiffre_affaire_group_by_all');
  String get chiffreAffaireGroupByDay => _t('chiffre_affaire_group_by_day');
  String get chiffreAffaireGroupByMonth => _t('chiffre_affaire_group_by_month');
  String get chiffreAffaireGroupByYear => _t('chiffre_affaire_group_by_year');
  String get chiffreAffaireGroupByProduct => _t('chiffre_affaire_group_by_product');
  String get chiffreAffaireReset => _t('chiffre_affaire_reset');
  String get chiffreAffaireTotal => _t('chiffre_affaire_total');
  String get chiffreAffaireSalesCount => _t('chiffre_affaire_sales_count');
  String get chiffreAffaireProductsSold => _t('chiffre_affaire_products_sold');
  String get chiffreAffaireAvgSale => _t('chiffre_affaire_avg_sale');
  String get chiffreAffaireTotalStock => _t('chiffre_affaire_total_stock');
  String get chiffreAffaireDetailsByPeriod => _t('chiffre_affaire_details_by_period');
  String get chiffreAffaireDetailsByProduct => _t('chiffre_affaire_details_by_product');

  // Add Product getters
  String get addProductTitle => _t('add_product_title');
  String get addProductNameLabel => _t('add_product_name_label');
  String get addProductDescriptionLabel => _t('add_product_description_label');
  String get addProductPriceLabel => _t('add_product_price_label');
  String get addProductSalePriceLabel => _t('add_product_sale_price_label');
  String get addProductQuantityLabel => _t('add_product_quantity_label');
  String get addProductButton => _t('add_product_button');
  String get addProductFieldRequired => _t('add_product_field_required');
  String get addProductInvalidNumber => _t('add_product_invalid_number');
  String get addProductSuccess => _t('add_product_success');
  String addProductError(String message) => _t('add_product_error').replaceAll('{message}', message);
  String addProductHttpError(int code) => _t('add_product_http_error').replaceAll('{code}', code.toString());
  String addProductConnectionError(String error) => _t('add_product_connection_error').replaceAll('{error}', error);

  // Benefice getters
  String get beneficeTitle => _t('benefice_title');
  String get beneficeCalculationTitle => _t('benefice_calculation_title');
  String get beneficeDayLabel => _t('benefice_day_label');
  String get beneficeMonthLabel => _t('benefice_month_label');
  String get beneficeYearLabel => _t('benefice_year_label');
  String get beneficeGrossProfitLabel => _t('benefice_gross_profit_label');
  String get beneficeExpensesLabel => _t('benefice_expenses_label');
  String get beneficeExactProfitLabel => _t('benefice_exact_profit_label');
  String get beneficeLoadError => _t('benefice_load_error');
  String beneficeServerError(int code) => _t('benefice_server_error').replaceAll('{code}', code.toString());
  String beneficeConnectionError(String error) => _t('benefice_connection_error').replaceAll('{error}', error);

  // Client getters
  String get clientTitle => _t('client_title');
  String get clientUnexpectedFormat => _t('client_unexpected_format');
  String clientLoadError(int code) => _t('client_load_error').replaceAll('{code}', code.toString());
  String clientConnectionError(String error) => _t('client_connection_error').replaceAll('{error}', error);
  String get clientEmptyTitle => _t('client_empty_title');
  String get clientEmptyHint => _t('client_empty_hint');
  String get clientUnknownName => _t('client_unknown_name');

  // Product Page getters
  String get productSessionNotFound => _t('product_session_not_found');
  String get productLoadError => _t('product_load_error');
  String get productUnauthorized => _t('product_unauthorized');
  String productHttpError(int code) => _t('product_http_error').replaceAll('{code}', code.toString());
  String productConnectionError(String error) => _t('product_connection_error').replaceAll('{error}', error);
  String get productAddTooltip => _t('product_add_tooltip');
  String get productTitle => _t('product_title');
  String get productRefreshTooltip => _t('product_refresh_tooltip');
  String get productRetryButton => _t('product_retry_button');
  String get productSearchHint => _t('product_search_hint');
  String get productTotalProducts => _t('product_total_products');
  String get productInStock => _t('product_in_stock');
  String get productOutOfStock => _t('product_out_of_stock');
  String get productNoProducts => _t('product_no_products');
  String get productNoSearchResults => _t('product_no_search_results');
  String get productStockOut => _t('product_stock_out');
  String get productStockLow => _t('product_stock_low');
  String get productStockAvailable => _t('product_stock_available');
  String get productEditTooltip => _t('product_edit_tooltip');
  String get productPurchasePrice => _t('product_purchase_price');
  String get productSalePrice => _t('product_sale_price');
  String get productQuantityLabel => _t('product_quantity_label');
  String productAddedOn(String date) => _t('product_added_on').replaceAll('{date}', date);
  String get productEditDialogTitle => _t('product_edit_dialog_title');
  String productEditName(String name) => _t('product_edit_name').replaceAll('{name}', name);
  String productEditDescription(String description) => _t('product_edit_description').replaceAll('{description}', description);
  String get productEditPurchasePrice => _t('product_edit_purchase_price');
  String get productEditSalePrice => _t('product_edit_sale_price');
  String get productEditQuantity => _t('product_edit_quantity');
  String get productEditCancel => _t('product_edit_cancel');
  String get productEditSave => _t('product_edit_save');
  String get productUpdateSuccess => _t('product_update_success');
  String productUpdateError(String message) => _t('product_update_error').replaceAll('{message}', message);
  String productUpdateHttpError(int code) => _t('product_update_http_error').replaceAll('{code}', code.toString());
  String productUpdateConnectionError(String error) => _t('product_update_connection_error').replaceAll('{error}', error);

  // Report Page getters
  String get reportTitle => _t('report_title');
  String get reportTabSales => _t('report_tab_sales');
  String get reportTabLowStock => _t('report_tab_low_stock');
  String get reportTabTopClients => _t('report_tab_top_clients');
  String get reportTabUnpaid => _t('report_tab_unpaid');
  String get reportDateFrom => _t('report_date_from');
  String get reportDateTo => _t('report_date_to');
  String get reportFilterButton => _t('report_filter_button');
  String get reportLoadError => _t('report_load_error');
  String reportServerError(int code) => _t('report_server_error').replaceAll('{code}', code.toString());
  String reportConnectionError(String error) => _t('report_connection_error').replaceAll('{error}', error);
  String get reportNoSales => _t('report_no_sales');
  String get reportNoSalesPeriod => _t('report_no_sales_period');
  String get reportSalesColumnId => _t('report_sales_column_id');
  String get reportSalesColumnClient => _t('report_sales_column_client');
  String get reportSalesColumnDate => _t('report_sales_column_date');
  String get reportSalesColumnTotal => _t('report_sales_column_total');
  String get reportNoLowStock => _t('report_no_low_stock');
  String get reportAllStockSufficient => _t('report_all_stock_sufficient');
  String get reportLowStockColumnId => _t('report_low_stock_column_id');
  String get reportLowStockColumnName => _t('report_low_stock_column_name');
  String get reportLowStockColumnQuantity => _t('report_low_stock_column_quantity');
  String get reportLowStockColumnPrice => _t('report_low_stock_column_price');
  String get reportNoClients => _t('report_no_clients');
  String get reportNoClientsPeriod => _t('report_no_clients_period');
  String get reportTopClientsColumnClient => _t('report_top_clients_column_client');
  String get reportTopClientsColumnTotal => _t('report_top_clients_column_total');
  String get reportNoUnpaid => _t('report_no_unpaid');
  String get reportAllInvoicesPaid => _t('report_all_invoices_paid');
  String get reportUnpaidColumnId => _t('report_unpaid_column_id');
  String get reportUnpaidColumnClient => _t('report_unpaid_column_client');
  String get reportUnpaidColumnDate => _t('report_unpaid_column_date');
  String get reportUnpaidColumnAmount => _t('report_unpaid_column_amount');

  // Sale List Page getters
  String get saleListTitle => _t('sale_list_title');
  String get saleListSortByDate => _t('sale_list_sort_by_date');
  String get saleListSortByMonth => _t('sale_list_sort_by_month');
  String get saleListSortByYear => _t('sale_list_sort_by_year');
  String get saleListLoadError => _t('sale_list_load_error');
  String saleListServerError(int code) => _t('sale_list_server_error').replaceAll('{code}', code.toString());
  String saleListConnectionError(String error) => _t('sale_list_connection_error').replaceAll('{error}', error);
  String get saleListNoSales => _t('sale_list_no_sales');
  String get saleListEmptyHint => _t('sale_list_empty_hint');
  String saleListClientLabel(String name) => _t('sale_list_client_label').replaceAll('{name}', name);
  String saleListDateLabel(String date) => _t('sale_list_date_label').replaceAll('{date}', date);
  String get saleListUnknown => _t('sale_list_unknown');

  // Sortie Page getters
  String get sortieTitle => _t('sortie_title');
  String get sortieLoadError => _t('sortie_load_error');
  String sortieServerError(int code) => _t('sortie_server_error').replaceAll('{code}', code.toString());
  String sortieConnectionError(String error) => _t('sortie_connection_error').replaceAll('{error}', error);
  String get sortieFillAllFields => _t('sortie_fill_all_fields');
  String get sortieUsernameNotFound => _t('sortie_username_not_found');
  String get sortieSuccess => _t('sortie_success');
  String get sortieSaveError => _t('sortie_save_error');
  String sortieError(String error) => _t('sortie_error').replaceAll('{error}', error);
  String sortieUserLabel(String username) => _t('sortie_user_label').replaceAll('{username}', username);
  String get sortieNewTitle => _t('sortie_new_title');
  String get sortieAmountLabel => _t('sortie_amount_label');
  String get sortieMotifLabel => _t('sortie_motif_label');
  String get sortieTypeLabel => _t('sortie_type_label');
  String get sortieTypeNormal => _t('sortie_type_normal');
  String get sortieTypeTransaction => _t('sortie_type_transaction');
  String get sortieSaveButton => _t('sortie_save_button');
  String get sortieFilterAll => _t('sortie_filter_all');
  String get sortieFilterDay => _t('sortie_filter_day');
  String get sortieFilterMonth => _t('sortie_filter_month');
  String get sortieFilterYear => _t('sortie_filter_year');
  String get sortieNoSorties => _t('sortie_no_sorties');
  String get sortieEmptyHint => _t('sortie_empty_hint');
  String get sortieColumnId => _t('sortie_column_id');
  String get sortieColumnUser => _t('sortie_column_user');
  String get sortieColumnAmount => _t('sortie_column_amount');
  String get sortieColumnMotif => _t('sortie_column_motif');
  String get sortieColumnType => _t('sortie_column_type');
  String get sortieColumnDate => _t('sortie_column_date');

  // Stock Add Out (New Sale Page) getters
  String get stockAddOutTitle => _t('stock_add_out_title');
  String get stockAddOutLoadError => _t('stock_add_out_load_error');
  String stockAddOutConnectionError(String error) => _t('stock_add_out_connection_error').replaceAll('{error}', error);
  String stockAddOutInsufficientStock(String product) => _t('stock_add_out_insufficient_stock').replaceAll('{product}', product);
  String get stockAddOutEmptyCart => _t('stock_add_out_empty_cart');
  String get stockAddOutEnterClient => _t('stock_add_out_enter_client');
  String get stockAddOutAddClientError => _t('stock_add_out_add_client_error');
  String stockAddOutServerError(int code) => _t('stock_add_out_server_error').replaceAll('{code}', code.toString());
  String stockAddOutClientConnectionError(String error) => _t('stock_add_out_client_connection_error').replaceAll('{error}', error);
  String get stockAddOutSuccess => _t('stock_add_out_success');
  String stockAddOutError(String message) => _t('stock_add_out_error').replaceAll('{message}', message);
  String stockAddOutConnectionErrorSale(String error) => _t('stock_add_out_connection_error_sale').replaceAll('{error}', error);
  String get stockAddOutClientNotFound => _t('stock_add_out_client_not_found');
  String stockAddOutClientNotFoundMessage(String name) => _t('stock_add_out_client_not_found_message').replaceAll('{name}', name);
  String get stockAddOutCancel => _t('stock_add_out_cancel');
  String get stockAddOutAdd => _t('stock_add_out_add');
  String get stockAddOutClientNameLabel => _t('stock_add_out_client_name_label');
  String get stockAddOutSearchProduct => _t('stock_add_out_search_product');
  String get stockAddOutNoProducts => _t('stock_add_out_no_products');
  String stockAddOutProductSubtitle(String price, String quantity) => _t('stock_add_out_product_subtitle').replaceAll('{price}', price).replaceAll('{quantity}', quantity);
  String get stockAddOutValidateSale => _t('stock_add_out_validate_sale');
  String get stockAddOutCart => _t('stock_add_out_cart');
  String stockAddOutQuantityLabel(String quantity, String price) => _t('stock_add_out_quantity_label').replaceAll('{quantity}', quantity).replaceAll('{price}', price);
  String stockAddOutTotal(String total) => _t('stock_add_out_total').replaceAll('{total}', total);

  // Vente Page getters
  String get venteTitle => _t('vente_title');
  String venteLoadError(String error) => _t('vente_load_error').replaceAll('{error}', error);
  String get venteRetry => _t('vente_retry');
  String get venteStepClient => _t('vente_step_client');
  String get venteStepAddress => _t('vente_step_address');
  String get venteStepWarranty => _t('vente_step_warranty');
  String get venteStepProducts => _t('vente_step_products');
  String get venteClientInfoTitle => _t('vente_client_info_title');
  String get venteSearchExistingClient => _t('vente_search_existing_client');
  String get venteSearchClientLabel => _t('vente_search_client_label');
  String get venteSearchClientHint => _t('vente_search_client_hint');
  String get venteNoClientsRegistered => _t('vente_no_clients_registered');
  String get venteNoClientFound => _t('vente_no_client_found');
  String venteClientSelected(String name) => _t('vente_client_selected').replaceAll('{name}', name);
  String get venteOr => _t('vente_or');
  String get venteCreateNewClient => _t('vente_create_new_client');
  String get venteNewClientNameLabel => _t('vente_new_client_name_label');
  String get venteNewClientNameHint => _t('vente_new_client_name_hint');
  String get venteRequiredFields => _t('vente_required_fields');
  String get venteNoClientsInfo => _t('vente_no_clients_info');
  String get venteAddressTitle => _t('vente_address_title');
  String get venteAddressLabel => _t('vente_address_label');
  String get venteAddressHint => _t('vente_address_hint');
  String get venteImeiLabel => _t('vente_imei_label');
  String get venteImeiHint => _t('vente_imei_hint');
  String get venteWarrantyTitle => _t('vente_warranty_title');
  String get venteWarrantyLabel => _t('vente_warranty_label');
  String get venteWarrantyHint => _t('vente_warranty_hint');
  String get venteWarrantyOptional => _t('vente_warranty_optional');
  String get venteSearchProductLabel => _t('vente_search_product_label');
  String get venteSearchProductHint => _t('vente_search_product_hint');
  String get venteNoProductFound => _t('vente_no_product_found');
  String venteStockLabel(String quantity) => _t('vente_stock_label').replaceAll('{quantity}', quantity);
  String ventePriceLabel(String price) => _t('vente_price_label').replaceAll('{price}', price);
  String get venteProductAdded => _t('vente_product_added');
  String get venteProductOutOfStock => _t('vente_product_out_of_stock');
  String get venteSearchLimitMessage => _t('vente_search_limit_message');
  String get venteProductsTitle => _t('vente_products_title');
  String get venteSelectedProducts => _t('vente_selected_products');
  String venteOriginalPrice(String price) => _t('vente_original_price').replaceAll('{price}', price);
  String ventePrice(String price) => _t('vente_price').replaceAll('{price}', price);
  String get venteTotal => _t('vente_total');
  String get venteNoProductsSelected => _t('vente_no_products_selected');
  String get venteNoProductsHint => _t('vente_no_products_hint');
  String get ventePrevious => _t('vente_previous');
  String get venteNext => _t('vente_next');
  String get venteSaving => _t('vente_saving');
  String get venteFinishSale => _t('vente_finish_sale');
  String get venteModifyPrice => _t('vente_modify_price');
  String get venteNewPriceLabel => _t('vente_new_price_label');
  String get venteNewPriceHint => _t('vente_new_price_hint');
  String get ventePriceRequired => _t('vente_price_required');
  String get ventePriceInvalid => _t('vente_price_invalid');
  String get ventePriceNegative => _t('vente_price_negative');
  String get ventePriceTooHigh => _t('vente_price_too_high');
  String venteReduction(String amount) => _t('vente_reduction').replaceAll('{amount}', amount);
  String venteReductionPercent(String percent) => _t('vente_reduction_percent').replaceAll('{percent}', percent);
  String venteIncrease(String amount) => _t('vente_increase').replaceAll('{amount}', amount);
  String venteIncreasePercent(String percent) => _t('vente_increase_percent').replaceAll('{percent}', percent);
  String get venteReset => _t('vente_reset');
  String get venteSave => _t('vente_save');
  String get venteCancel => _t('vente_cancel');
  String get venteDeleteTooltip => _t('vente_delete_tooltip');
  String get venteEditPriceTooltip => _t('vente_edit_price_tooltip');
  String venteMaxQuantity(String quantity) => _t('vente_max_quantity').replaceAll('{quantity}', quantity);
  String get venteProductRemoved => _t('vente_product_removed');
  String get ventePriceModified => _t('vente_price_modified');
  String get venteSaleRecorded => _t('vente_sale_recorded');
  String get venteSaleRecordedTitle => _t('vente_sale_recorded_title');
  String get venteClose => _t('vente_close');
  String get ventePrintInvoice => _t('vente_print_invoice');
  String get venteInfoClient => _t('vente_info_client');
  String get venteInfoTotal => _t('vente_info_total');
  String get venteInfoDate => _t('vente_info_date');
  String get venteInfoImei => _t('vente_info_imei');
  String get venteInfoWarranty => _t('vente_info_warranty');
  String get venteErrorLoadingProducts => _t('vente_error_loading_products');
  String venteErrorServer(int code) => _t('vente_error_server').replaceAll('{code}', code.toString());
  String venteErrorConnection(String error) => _t('vente_error_connection').replaceAll('{error}', error);
  String venteErrorServerClient(int code) => _t('vente_error_server_client').replaceAll('{code}', code.toString());
  String venteErrorConnectionClient(String error) => _t('vente_error_connection_client').replaceAll('{error}', error);
  String get venteErrorCreateClient => _t('vente_error_create_client');
  String get venteErrorSelectClient => _t('vente_error_select_client');
  String get venteErrorProductAlreadyAdded => _t('vente_error_product_already_added');
  String venteErrorInsufficientStock(String product) => _t('vente_error_insufficient_stock').replaceAll('{product}', product);
  String get venteErrorSelectClientSale => _t('vente_error_select_client_sale');
  String get venteErrorSelectProducts => _t('vente_error_select_products');
  String get venteErrorSale => _t('vente_error_sale');
  String get venteErrorServerResponse => _t('vente_error_server_response');
  String get venteErrorTimeout => _t('vente_error_timeout');
  String get venteErrorGenerateInvoice => _t('vente_error_generate_invoice');
  String venteProductAddedToSale(String product) => _t('vente_product_added_to_sale').replaceAll('{product}', product);

  // Dash Vendeur getters
  String get vendorNewSaleNotification => _t('vendor_new_sale_notification');
  String get vendorDataUpdated => _t('vendor_data_updated');
  String get vendorLoadError => _t('vendor_load_error');
  String vendorServerError(int code) => _t('vendor_server_error').replaceAll('{code}', code.toString());
  String vendorConnectionError(String error) => _t('vendor_connection_error').replaceAll('{error}', error);
  String vendorSaleItemTitle(int id, String client) => _t('vendor_sale_item_title').replaceAll('{id}', id.toString()).replaceAll('{client}', client);
  String vendorSaleItemSubtitle(String amount, String date) => _t('vendor_sale_item_subtitle').replaceAll('{amount}', amount).replaceAll('{date}', date);

  // Deposit Page getters
  String get depositTitle => _t('deposit_title');
  String get depositClientLabel => _t('deposit_client_label');
  String get depositSearchClient => _t('deposit_search_client');
  String get depositSearchClientHint => _t('deposit_search_client_hint');
  String get depositNoClients => _t('deposit_no_clients');
  String get depositNoClientFound => _t('deposit_no_client_found');
  String get depositProductLabel => _t('deposit_product_label');
  String get depositSelectProduct => _t('deposit_select_product');
  String get depositProductNotFound => _t('deposit_product_not_found');
  String get depositAmountLabel => _t('deposit_amount_label');
  String get depositDateLabel => _t('deposit_date_label');
  String get depositSaveButton => _t('deposit_save_button');
  String get depositSaving => _t('deposit_saving');
  String get depositHistoryTitle => _t('deposit_history_title');
  String get depositTotalDeposited => _t('deposit_total_deposited');
  String get depositRemainingToPay => _t('deposit_remaining_to_pay');
  String get depositNoDepositsFound => _t('deposit_no_deposits_found');
  String get depositReserved => _t('deposit_reserved');
  String get depositOutOfStock => _t('deposit_out_of_stock');
  String get depositCloseButton => _t('deposit_close_button');
  String get depositDeliverButton => _t('deposit_deliver_button');
  String get depositDeliverConfirm => _t('deposit_deliver_confirm');
  String get depositDeliverSuccess => _t('deposit_deliver_success');
  String get depositDeliverError => _t('deposit_deliver_error');
  String get depositClientCredit => _t('deposit_client_credit');
  String get depositSuccess => _t('deposit_success');
  String get depositError => _t('deposit_error');
  String depositConnectionError(String error) => _t('deposit_connection_error').replaceAll('{error}', error);
  String get depositSelectClientProduct => _t('deposit_select_client_product');
  String get depositAmountPositive => _t('deposit_amount_positive');
  String get depositPrinterError => _t('deposit_printer_error');
  String depositPrintError(String error) => _t('deposit_print_error').replaceAll('{error}', error);
  String get depositReceiptTitle => _t('deposit_receipt_title');
  String depositReceiptNumber(int? id) => _t('deposit_receipt_number').replaceAll('{id}', id?.toString() ?? '');
  String depositReceiptDate(String date) => _t('deposit_receipt_date').replaceAll('{date}', date);
  String get depositReceiptClient => _t('deposit_receipt_client');
  String depositReceiptClientName(String name) => _t('deposit_receipt_client_name').replaceAll('{name}', name);
  String get depositReceiptProduct => _t('deposit_receipt_product');
  String get depositReceiptAmount => _t('deposit_receipt_amount');
  String get depositReceiptStockStatus => _t('deposit_receipt_stock_status');
  String get depositReceiptReserved => _t('deposit_receipt_reserved');
  String get depositReceiptNotReserved => _t('deposit_receipt_not_reserved');
  String get depositReceiptStockEmpty => _t('deposit_receipt_stock_empty');
  String get depositReceiptProof => _t('deposit_receipt_proof');
  String get depositReceiptThanks => _t('deposit_receipt_thanks');

  // Additional Deposit Page getters
  String get additionalDepositTitle => _t('additional_deposit_title');
  String get additionalDepositClient => _t('additional_deposit_client');
  String get additionalDepositProduct => _t('additional_deposit_product');
  String get additionalDepositAmountLabel => _t('additional_deposit_amount_label');
  String get additionalDepositDateLabel => _t('additional_deposit_date_label');
  String get additionalDepositSaveButton => _t('additional_deposit_save_button');

  // Deposits Overview getters
  String get depositsOverviewTitle => _t('deposits_overview_title');
  String get depositsOverviewLoadError => _t('deposits_overview_load_error');
  String depositsOverviewServerError(int code) => _t('deposits_overview_server_error').replaceAll('{code}', code.toString());
  String depositsOverviewConnectionError(String error) => _t('deposits_overview_connection_error').replaceAll('{error}', error);
  String get depositsOverviewEmpty => _t('deposits_overview_empty');
  String get depositsOverviewTotalDeposits => _t('deposits_overview_total_deposits');
  String get depositsOverviewRemainingTotal => _t('deposits_overview_remaining_total');
  String depositsOverviewHistoryTitle(String client) => _t('deposits_overview_history_title').replaceAll('{client}', client);
  String get depositsOverviewTotal => _t('deposits_overview_total');
  String get depositsOverviewNoDepositsClient => _t('deposits_overview_no_deposits_client');
  String get depositsOverviewAddButton => _t('deposits_overview_add_button');
  String get depositsOverviewAddTooltip => _t('deposits_overview_add_tooltip');
  String get depositsOverviewLoadHistoryError => _t('deposits_overview_load_history_error');

  // Detail Sale getters
  String get detailSaleTitle => _t('detail_sale_title');
  String get detailSaleLoadError => _t('detail_sale_load_error');
  String detailSaleServerError(int code) => _t('detail_sale_server_error').replaceAll('{code}', code.toString());
  String detailSaleConnectionError(String error) => _t('detail_sale_connection_error').replaceAll('{error}', error);
  String detailSaleId(int id) => _t('detail_sale_id').replaceAll('{id}', id.toString());
  String detailSaleDate(String date) => _t('detail_sale_date').replaceAll('{date}', date);
  String detailSaleClient(String name) => _t('detail_sale_client').replaceAll('{name}', name);
  String detailSalePhone(String phone) => _t('detail_sale_phone').replaceAll('{phone}', phone);
  String detailSaleAddress(String address) => _t('detail_sale_address').replaceAll('{address}', address);
  String get detailSaleProduct => _t('detail_sale_product');
  String get detailSaleQuantity => _t('detail_sale_quantity');
  String get detailSaleUnitPrice => _t('detail_sale_unit_price');
  String get detailSaleTotal => _t('detail_sale_total');
  String get detailSaleTotalLabel => _t('detail_sale_total_label');

}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}


