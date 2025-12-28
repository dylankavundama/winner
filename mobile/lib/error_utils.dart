/// Utilitaires pour nettoyer et formater les messages d'erreur
class ErrorUtils {
  /// Nettoie un message d'erreur en supprimant les URLs, hostnames et autres informations techniques
  static String cleanErrorMessage(dynamic error) {
    String errorStr = error.toString();
    
    // Supprimer les URLs (http://, https://, etc.)
    errorStr = errorStr.replaceAll(RegExp(r'https?://[^\s]+'), '[URL]');
    
    // Supprimer les hostnames/IPs (ex: 192.168.1.1, example.com:8080)
    errorStr = errorStr.replaceAll(RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?\b'), '[IP]');
    errorStr = errorStr.replaceAll(RegExp(r'\b[a-zA-Z0-9.-]+\.(com|net|org|io|fr|dev|local)(:\d+)?\b'), '[HOST]');
    
    // Supprimer les chemins de fichiers complets (garder seulement le nom du fichier)
    errorStr = errorStr.replaceAllMapped(RegExp(r'[a-zA-Z]:\\[^\s]+|/[^\s]+'), (match) {
      final path = match.group(0) ?? '';
      final fileName = path.split(RegExp(r'[/\\]')).last;
      return fileName.isNotEmpty ? fileName : '[FILE]';
    });
    
    // Nettoyer les messages d'erreur Dart/Flutter communs
    if (errorStr.contains('SocketException') || errorStr.contains('Failed host lookup')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }
    
    if (errorStr.contains('TimeoutException') || errorStr.contains('timeout')) {
      return 'Le serveur ne répond pas. Veuillez réessayer plus tard.';
    }
    
    if (errorStr.contains('FormatException') || errorStr.contains('JSON')) {
      return 'Erreur lors du traitement des données.';
    }
    
    // Si le message est trop technique, retourner un message générique
    if (errorStr.contains('Exception:') || errorStr.contains('Error:')) {
      final parts = errorStr.split(':');
      if (parts.length > 1) {
        final errorType = parts[0].trim();
        // Garder seulement le type d'erreur sans les détails techniques
        if (errorType.contains('Exception') || errorType.contains('Error')) {
          return 'Erreur de connexion. Veuillez réessayer.';
        }
      }
    }
    
    // Limiter la longueur du message
    if (errorStr.length > 200) {
      errorStr = errorStr.substring(0, 200) + '...';
    }
    
    return errorStr;
  }
  
  /// Extrait un message d'erreur utilisateur-friendly depuis une exception
  static String getUserFriendlyError(dynamic error) {
    final cleaned = cleanErrorMessage(error);
    
    // Messages d'erreur spécifiques
    if (cleaned.toLowerCase().contains('connection refused') || 
        cleaned.toLowerCase().contains('connection reset')) {
      return 'Connexion refusée. Le serveur est peut-être indisponible.';
    }
    
    if (cleaned.toLowerCase().contains('network is unreachable')) {
      return 'Réseau inaccessible. Vérifiez votre connexion internet.';
    }
    
    if (cleaned.toLowerCase().contains('certificate') || 
        cleaned.toLowerCase().contains('ssl') ||
        cleaned.toLowerCase().contains('tls')) {
      return 'Erreur de sécurité de connexion.';
    }
    
    return cleaned;
  }
}

