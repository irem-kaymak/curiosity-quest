import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merakli/model.dart';
import 'package:merakli/preschool.dart';
import 'package:merakli/ui.dart';
import 'package:merakli/narration.dart';
import 'package:merakli/screens.dart';

void main() {
  test('English demo questions keep their matching topic', () async {
    final service = DemoLearningService();
    for (final d in seedDiscoveries) {
      final answer = await service.ask(d.question, false);
      expect(answer.topic, d.topic, reason: d.question);
    }
    expect((await service.ask('How do plants grow?', true)).topic, 'Nature');
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/Nunito.ttf'))).load();
  });
  Widget host(Widget w, {bool older = false}) => MaterialApp(
    theme: ThemeData(fontFamily: 'Nunito'),
    home: AgeStyle(
      older: older,
      child: Scaffold(body: w),
    ),
  );
  testWidgets('Preschool screens fit 320 and 390 pixel phones', (t) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    for (final width in [320.0, 390.0]) {
      t.view.physicalSize = Size(width, 844);
      t.view.devicePixelRatio = 1;
      final m = AppModel();
      for (final w in <Widget>[
        PreschoolHome(model: m, go: (_) {}),
        PreschoolExplore(model: m, category: (_) {}),
        PreschoolHistory(
          model: m,
          topic: 'Animals',
          back: () {},
          open: (_) {},
          go: (_) {},
        ),
        PreschoolHistory(
          model: m,
          topic: 'Science',
          back: () {},
          open: (_) {},
          go: (_) {},
        ),
        PreschoolChat(model: m, back: () {}),
        PreschoolAnswer(
          discovery: m.discoveries.first,
          back: () {},
          go: (_) {},
        ),
        PreschoolQuiz(model: m, back: () {}),
        PreschoolProfile(model: m, go: (_) {}),
        PreschoolBadges(model: m, back: () {}),
      ]) {
        await t.pumpWidget(host(w));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: '${w.runtimeType} / $width');
      }
    }
  });
  testWidgets(
    'Preschool buttons have one-word 12pt labels and large pictures',
    (t) async {
      await t.pumpWidget(host(PreschoolHome(model: AppModel(), go: (_) {})));
      await t.pumpAndSettle();
      for (final b in t.widgetList<PictureButton>(find.byType(PictureButton))) {
        expect(b.label.trim().split(' ').length, 1);
      }
      expect(find.text('Little questions,\nbig discoveries.'), findsNothing);
      expect(find.text('Play'), findsOneWidget);
    },
  );
  testWidgets('Older layout stays detailed and uses a distinct cool palette', (
    t,
  ) async {
    final m = AppModel()..older = true;
    await t.pumpWidget(
      host(
        HomeScreen(model: m, go: (_) {}, category: (_) {}, open: (_) {}),
        older: true,
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Little questions,\nbig discoveries.'), findsOneWidget);
    expect(find.text('Puzzle time'), findsOneWidget);
    final c = t.element(find.byType(HomeScreen));
    expect(AgeStyle.surface(c, peach), const Color(0xFFE5E1FA));
    expect(AgeStyle.surface(c, yellow), isNot(yellow));
  });
  testWidgets('Visual quiz supports wrong and correct answers and completion', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final m = AppModel();
    await t.pumpWidget(host(PreschoolQuiz(model: m, back: () {})));
    await t.pumpAndSettle();
    await t.tap(find.text('Start'));
    await t.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      final q = visualQuestions[i];
      await t.tap(find.text(q.labels[i == 0 ? 1 : q.correct]));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      final next = find.text(i == 2 ? 'Finish' : 'Next');
      await t.ensureVisible(next);
      await t.tap(next);
      await t.pumpAndSettle();
    }
    expect(m.quizCompleted, 1);
    expect(find.text('Great'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    expect(t.takeException(), isNull);
  });
  test(
    'English narration calls the device engine and handles missing voice',
    () async {
      var available = true;
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
            call,
          ) async {
            calls.add(call);
            return call.method == 'isLanguageAvailable' ? available : 1;
          });
      expect(await Narration.speak('Hangisi uçar?'), true);
      expect(
        calls.any((c) => c.method == 'setLanguage' && c.arguments == 'en-US'),
        true,
      );
      expect(calls.any((c) => c.method == 'speak'), true);
      available = false;
      expect(await Narration.speak('Yeniden'), false);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    },
  );
}
