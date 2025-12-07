class ApiConfig {
  // Base URL de l'API
  static const String baseUrl = 'https://api.cdn-aboapp.online/api';
  static const String socketUrl = 'https://base.cdn-aboapp.online';

  static const String apiVersion = 'v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

