import 'package:cull/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the empty home shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CullApp()));
    await tester.pumpAndSettle();

    expect(find.text('File'), findsOneWidget);
    expect(find.text('Mark'), findsOneWidget);
    expect(find.textContaining('No directory open'), findsOneWidget);
    expect(find.textContaining('select a file to preview'), findsOneWidget);
  });
}
