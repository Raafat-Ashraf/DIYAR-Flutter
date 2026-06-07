import 'package:diyar/src/app/app.dart';
import 'package:diyar/src/core/di/service_locator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DIYAR app opens Arabic onboarding when there is no session', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();

    await tester.pumpWidget(const DiyarApp());
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
