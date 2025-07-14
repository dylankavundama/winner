// lib/utils/constants.dart
class ApiConstants {
  // IMPORTANT: Replace with your actual server IP or domain
  // For Android Emulator: 'http://10.0.2.2/your_pos_project_folder'
  // For Physical Device: 'http://YOUR_MACHINE_IP/your_pos_project_folder'
  static const String baseUrl =
      'http://192.168.1.69/winner/gestion-app/gestion-app'; // Base for all API calls

  static const String usernamesApi = '$baseUrl/api/usernames.php';
  static const String loginApi = '$baseUrl/api/login.php';
  static const String dashboardStatsApi =
      '$baseUrl/api/api_dashboard_stats.php'; // Adjusted based on previous analysis
  static const String salesChartDataApi =
      '$baseUrl/api/api_sales_chart_data.php'; // Adjusted

  static const String clientsApi =
      '$baseUrl/api/clients.php';
  // ...autres constantes éventuelles
}
