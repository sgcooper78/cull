import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'home_shell.dart';

/// The app router. Kept as a plain provider (it is a singleton); feature
/// state uses `@riverpod` codegen per CLAUDE.md.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: HomeShell.path,
    routes: [
      GoRoute(
        path: HomeShell.path,
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );
});
