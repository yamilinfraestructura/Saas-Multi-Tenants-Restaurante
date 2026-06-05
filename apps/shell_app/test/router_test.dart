import 'package:flutter_test/flutter_test.dart';
import 'package:shell_app/router/app_router.dart';

void main() {
  group('homeRouteForNivel', () {
    test('admin va al dashboard', () {
      expect(homeRouteForNivel('admin'), '/admin');
    });

    test('mozo va al comedor', () {
      expect(homeRouteForNivel('mozo'), '/pos/comedor');
    });

    test('cocina va al kanban', () {
      expect(homeRouteForNivel('cocina'), '/cocina');
    });
  });

  group('route helpers', () {
    test('menu qr es ruta pública', () {
      expect(isPublicRoute('/menu/demo-tenant/sala/mesa'), isTrue);
    });

    test('billing no es pública', () {
      expect(isPublicRoute('/billing'), isFalse);
    });

    test('billing route detectada', () {
      expect(isBillingRoute('/billing'), isTrue);
    });
  });
}
