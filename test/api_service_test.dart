import 'package:flutter_test/flutter_test.dart';
import 'package:smartfix_mobile/core/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService Tests', () {
    test('ApiService is a singleton and initializes Dio correctly', () {
      final instance1 = ApiService();
      final instance2 = ApiService();

      expect(identical(instance1, instance2), isTrue);
      expect(instance1.dio, isNotNull);
      expect(instance1.dio.options.headers['Accept'], 'application/json');
      expect(instance1.dio.options.headers['Content-Type'], 'application/json');
      expect(instance1.dio.interceptors.isNotEmpty, isTrue);
    });

    test('Dynamic Base URL resolves properly', () {
      expect(ApiService.baseUrl, isNotEmpty);
      expect(ApiService.baseUrl.contains(':8000'), isTrue);

      ApiService.setBaseUrl('http://192.168.1.100:8000/api');
      expect(ApiService.baseUrl, 'http://192.168.1.100:8000/api');
      expect(
        ApiService().dio.options.baseUrl,
        'http://192.168.1.100:8000/api/',
      );

      ApiService.setBaseUrl(null);
    });

    test('In-memory token management', () {
      ApiService.setAuthToken('test_token_123');
      expect(ApiService.hasToken, isTrue);

      ApiService.setAuthToken(null);
      expect(ApiService.hasToken, isFalse);
    });
  });
}
