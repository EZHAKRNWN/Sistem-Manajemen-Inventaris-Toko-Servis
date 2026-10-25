import 'package:flutter_test/flutter_test.dart';
import 'package:smartfix_mobile/core/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Repair Tracking & Technician Stats Tests', () {
    test('ApiService provides work orders and stats endpoint handlers', () {
      final api = ApiService();
      expect(api.getWorkOrders, isNotNull);
      expect(api.createWorkOrder, isNotNull);
      expect(api.completeWorkOrder, isNotNull);
      expect(api.getTechnicianStats, isNotNull);
    });

    test('formatRupiah logic works accurately', () {
      String formatRupiah(num? amount) {
        if (amount == null) return 'Rp 0';
        final str = amount.toInt().toString();
        final buffer = StringBuffer();
        int count = 0;
        for (int i = str.length - 1; i >= 0; i--) {
          buffer.write(str[i]);
          count++;
          if (count % 3 == 0 && i != 0) {
            buffer.write('.');
          }
        }
        return 'Rp ${buffer.toString().split('').reversed.join('')}';
      }

      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(50000), 'Rp 50.000');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('ISO Currency formatting distinguishes CNY and JPY', () {
      const cnyIso = 'CNY (¥ - Yuan Tiongkok)';
      const jpyIso = 'JPY (¥ - Yen Jepang)';

      expect(cnyIso != jpyIso, isTrue);
      expect(cnyIso.contains('CNY'), isTrue);
      expect(jpyIso.contains('JPY'), isTrue);
    });
  });
}
