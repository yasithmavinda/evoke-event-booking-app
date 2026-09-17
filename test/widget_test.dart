// This is a basic Flutter widget test for the Evoke app.
import 'package:flutter_test/flutter_test.dart';
import 'package:evoke/main.dart';
import 'package:evoke/screens/splash_screen.dart';

void main() {
  testWidgets('Evoke App splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EvokeApp());

    // Verify that the Splash Screen is shown initially by checking for the brand name.
    expect(find.text('EVOKE'), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
