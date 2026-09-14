import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:merakli/main.dart';
import 'package:merakli/model.dart';
import 'package:merakli/screens.dart';
import 'package:merakli/parent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/Nunito.ttf'));
    await loader.load();
  });
  test(
    'Demo answers are categorized; unfamiliar questions are transparent',
    () async {
      final service = DemoLearningService();
      final answer = await service.ask('How do butterflies fly?', false);
      expect(answer.topic, 'Animals');
      final unknown = await service.ask('Tell me about trains', true);
      expect(unknown.answer, contains('In this demo'));
      expect(
        service.quiz(true).first.title,
        isNot(service.quiz(false).first.title),
      );
    },
  );
  testWidgets('Category opens the matching conversation history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MerakliApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Animals'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('How do butterflies fly?'), findsOneWidget);
    expect(find.text('Why does the Moon look different?'), findsNothing);
    await tester.tap(find.bySemanticsLabel('How do butterflies fly?'));
    await tester.pumpAndSettle();
    expect(find.text('Listen'), findsOneWidget);
    expect(find.text('Butterfly'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Quiz checks answers and awards completion only at the end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = AppModel();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Nunito'),
        home: Scaffold(
          body: QuizScreen(model: model, back: () {}),
        ),
      ),
    );
    await tester.tap(find.text('Ready, let us play!'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(model.quizCompleted, 0);
      await tester.tap(find.text(littleQuiz[i].choices[littleQuiz[i].correct]));
      await tester.pump();
      await tester.ensureVisible(find.text('Check my answer'));
      await tester.tap(find.text('Check my answer'));
      await tester.pumpAndSettle();
      expect(find.text('✨  Yes, you got it!'), findsOneWidget);
      final next = find.text(i == 2 ? 'See my result' : 'Next question');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(model.quizCompleted, 1);
    expect(find.text('3 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Parent gate rejects wrong answer', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool entered = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Nunito'),
        home: Scaffold(
          body: ParentGate(back: () {}, onSuccess: () => entered = true),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '12');
    await tester.ensureVisible(find.text('Open parent dashboard'));
    await tester.tap(find.text('Open parent dashboard'));
    await tester.pump();
    expect(entered, false);
    expect(find.text('Check your answer and try again.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.text('Open parent dashboard'));
    await tester.pump();
    expect(entered, true);
  });
  testWidgets('All main screens fit narrow and standard mobile widths', (
    tester,
  ) async {
    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      final m = AppModel();
      final screens = <Widget>[
        HomeScreen(model: m, go: (_) {}, category: (_) {}, open: (_) {}),
        ExploreScreen(model: m, category: (_) {}),
        ProfileScreen(model: m, go: (_) {}),
        ParentScreen(model: m, go: (_) {}, back: () {}),
        SettingsScreen(model: m, back: () {}),
        AgeScreen(model: m, go: (_) {}, back: () {}),
        AuthScreen(model: m, register: true, go: (_) {}, back: () {}),
        ChatScreen(model: m, back: () {}),
        QuizScreen(model: m, back: () {}),
      ];
      for (final screen in screens) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Nunito'),
            home: Scaffold(body: screen),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} at $width',
        );
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
