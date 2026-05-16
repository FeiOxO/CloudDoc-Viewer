import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_doc_viewer/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CloudDocViewerApp());
    expect(find.text('我的云服务器'), findsOneWidget);
  });
}
