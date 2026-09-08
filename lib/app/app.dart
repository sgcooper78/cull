import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// Root widget. Wires the router and theme; holds no state of its own.
class CullApp extends ConsumerWidget {
  const CullApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Cull',
      debugShowCheckedModeBanner: false,
      theme: cullTheme(Brightness.light),
      darkTheme: cullTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}
