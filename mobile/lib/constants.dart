// lib/utils/constants.dart
class ApiConstants {
  // IMPORTANT: Replace with your actual server IP or domain
  // For Android Emulator: 'http://10.0.2.2/your_pos_project_folder'
  // For Physical Device: 'http://YOUR_MACHINE_IP/your_pos_project_folder'
  static const String baseUrl =
      'https://winnercompany.net/api'; // Base for all API calls
  // 'http://192.168.1.69/winner/gestion-app/gestion-app/api/';
  static const String usernamesApi = '$baseUrl/usernames.php';
  static const String loginApi = '$baseUrl/login.php';
  static const String dashboardStatsApi =
      '$baseUrl/api_dashboard_stats.php'; // Adjusted based on previous analysis
  static const String salesChartDataApi =
      '$baseUrl/api_sales_chart_data.php'; // Adjusted

  static const String stockOutHistoryApi = '$baseUrl/get_stock_out_history.php';
  static const String updatePaymentStatusApi = '$baseUrl/update_status.php';

  // static const String clientsApi ='http://192.168.1.65/winner/gestion-app/gestion-app/api/clients.php';
  static const String recordStockOutApi =
      '$baseUrl/record_stock_out.php'; // Add this line
  // Add these for the Vente page
  static const String clientsApi =
      '$baseUrl/clients.php'; // Or wherever you fetch clients

  static const String addSaleApi =
      '$baseUrl/add_sale.php'; // The endpoint for POSTing sales
  // ...autres constantes éventuelles

  static const String productsApi = '$baseUrl/products.php';
  // 'http://192.168.1.67/winner/gestion-app/gestion-app/api/products.php';

  // Dépôts (paiement par tranches)
  static const String depositsApi = '$baseUrl/deposits.php';
  static const String depositsHistoryApi = '$baseUrl/deposits_history.php';
  static const String dettesApi = '$baseUrl/dettes.php';
  static const String addInvoiceApi = '$baseUrl/add_invoice.php';
}
