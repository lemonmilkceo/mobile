import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:baeandlee_app/main.dart' as app;

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'mock member can browse a profile, request an introduction, and pause matching',
    (tester) async {
      app.main();

      await _waitFor(tester, find.text('김XX'));
      expect(find.text('인물'), findsOneWidget);

      await tester.tap(find.text('김XX'));
      await _waitFor(tester, find.text('소개해주세요'));

      await tester.tap(find.text('소개해주세요'));
      await _waitFor(tester, find.text('신중히 요청하기'));
      await tester.tap(find.text('신중히 요청하기'));
      await _waitFor(tester, find.text('프로토타입: 소개 요청을 시뮬레이션했어요.'));

      await tester.tap(find.text('내 정보'));
      await _waitFor(tester, find.text('매칭 받기'));
      expect(find.text('매칭 가능'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.text('매칭 중지'), findsOneWidget);
    },
  );
}
