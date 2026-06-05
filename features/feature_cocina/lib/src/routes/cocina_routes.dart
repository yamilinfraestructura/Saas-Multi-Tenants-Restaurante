import 'package:go_router/go_router.dart';

import '../screens/cocina_kanban_screen.dart';

class CocinaRoutes {
  CocinaRoutes._();

  static const root = '/cocina';

  static List<RouteBase> get routes => [
        GoRoute(
          path: root,
          builder: (context, state) => const CocinaKanbanScreen(),
        ),
      ];
}
