import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('renders demo page', (WidgetTester tester) async {
    await tester.pumpWidget(const VoiceMessageExampleApp());

    expect(find.text('Voice Message UI'), findsOneWidget);
    expect(find.textContaining('Record a message'), findsOneWidget);
  });
}
