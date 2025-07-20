// lib/utils/constants.dart
class ApiConstants {
  // IMPORTANT: Replace with your actual server IP or domain
  // For Android Emulator: 'http://10.0.2.2/your_pos_project_folder'
  // For Physical Device: 'http://YOUR_MACHINE_IP/your_pos_project_folder'
  static const String baseUrl =
      'http://192.168.1.68/winner/gestion-app/gestion-app/api'; // Base for all API calls

  static const String usernamesApi = '$baseUrl/usernames.php';

  static const String loginApi = '$baseUrl/login.php';
  static const String dashboardStatsApi =
      '$baseUrl/api_dashboard_stats.php'; // Adjusted based on previous analysis
  static const String salesChartDataApi =
      '$baseUrl/api_sales_chart_data.php'; // Adjusted

  // static const String clientsApi ='http://192.168.1.65/winner/gestion-app/gestion-app/api/clients.php';

  // Add these for the Vente page
  static const String clientsApi =
      'http://192.168.1.68/winner/gestion-app/gestion-app/api/clients.php'; // Or wherever you fetch clients

  static const String addSaleApi =
      '$baseUrl/add_sale.php'; // The endpoint for POSTing sales
  // ...autres constantes éventuelles

 
  static const String productsApi =
      'http://192.168.1.68/winner/gestion-app/gestion-app/api/products.php';
  // static const String clientsApi = 'http://localhost/gestion-app/api/clients.php';
  // static const String addSaleApi = 'http://localhost/gestion-app/api/add_sale.php';
}
