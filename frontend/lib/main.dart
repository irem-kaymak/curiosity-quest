import 'package:flutter/material.dart';
import 'model.dart';
import 'ui.dart';
import 'screens.dart';
import 'parent.dart';
import 'preschool.dart';
import 'narration.dart';
import 'nature.dart';

void main() => runApp(const MerakliApp());

class MerakliApp extends StatelessWidget {
  const MerakliApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Curio • Your learning buddy',
    locale: const Locale('en', 'US'),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      fontFamilyFallback: const ['NotoEmoji'],
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(seedColor: coral, surface: cream),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: ink)),
    ),
    home: const AppShell(),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final model = AppModel();
  String page = 'home';
  final history = <String>[];
  String topic = 'Animals';
  Discovery? discovery;
  bool parentUnlocked = false;
  @override
  void initState() {
    super.initState();
    final q = Uri.base.queryParameters;
    page = q['screen'] ?? 'home';
    if (q['age'] == 'older') model.older = true;
    if (page == 'parent' || page == 'settings') page = 'gate';
    model.addListener(refresh);
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Narration.stop();
    model.removeListener(refresh);
    model.dispose();
    super.dispose();
  }

  void go(String next) {
    Narration.stop();
    setState(() {
      if (page == 'parent' && next != 'settings') parentUnlocked = false;
      history.add(page);
      page = next;
    });
  }

  void back() {
    Narration.stop();
    setState(() {
      if (page == 'parent') parentUnlocked = false;
      page = history.isNotEmpty ? history.removeLast() : 'home';
      if ((page == 'parent' || page == 'settings') && !parentUnlocked) {
        page = 'gate';
      }
    });
  }

  void category(String t) {
    topic = t;
    go('history');
  }

  void openDiscovery(Discovery d) {
    discovery = d;
    go('answer');
  }

  Widget content() {
    if (!model.older) {
      switch (page) {
        case 'home':
          return PreschoolHome(model: model, go: go, open: openDiscovery);
        case 'explore':
          return PreschoolExplore(model: model, category: category);
        case 'history':
          return PreschoolHistory(
            model: model,
            topic: topic,
            back: back,
            open: openDiscovery,
            go: go,
          );
        case 'chat':
          return PreschoolChat(model: model, back: back);
        case 'answer':
          final selected = discovery ?? (model.discoveries.isEmpty ? null : model.discoveries.first);
          return selected == null
              ? PreschoolChat(model: model, back: back)
	              : PreschoolAnswer(
	                  model: model,
	                  discovery: selected,
	                  back: back,
	                  go: go,
	                );
        case 'quiz':
          return PreschoolQuiz(model: model, back: back);
        case 'profile':
          return PreschoolProfile(model: model, go: go);
        case 'badges':
          return PreschoolBadges(model: model, back: back);
      }
    }
    switch (page) {
      case 'welcome':
        return WelcomeScreen(model: model, go: go);
      case 'login':
        return AuthScreen(
          key: const ValueKey('login'),
          model: model,
          register: false,
          go: go,
          back: back,
        );
      case 'signup':
        return AuthScreen(
          key: const ValueKey('signup'),
          model: model,
          register: true,
          go: go,
          back: back,
        );
      case 'age':
        return AgeScreen(model: model, go: go, back: back);
      case 'explore':
        return ExploreScreen(model: model, category: category);
      case 'history':
        return HistoryScreen(
          model: model,
          topic: topic,
          back: back,
          open: openDiscovery,
          go: go,
        );
      case 'chat':
        return ChatScreen(model: model, back: back);
      case 'answer':
        final selected = discovery ?? (model.discoveries.isEmpty ? null : model.discoveries.first);
        return selected == null
            ? ChatScreen(model: model, back: back)
            : AnswerScreen(
                discovery: selected,
                back: back,
                go: go,
              );
      case 'quiz':
        return QuizScreen(model: model, back: back);
      case 'profile':
        return ProfileScreen(model: model, go: go);
      case 'gate':
        return ParentGate(
          model: model,
          back: back,
          onSuccess: () {
            parentUnlocked = true;
            go('parent');
          },
        );
      case 'parent':
        return ParentScreen(model: model, go: go, back: back);
      case 'settings':
        return SettingsScreen(model: model, back: back);
      case 'badges':
        return BadgesScreen(model: model, back: back);
      default:
        return HomeScreen(
          model: model,
          go: go,
          category: category,
          open: openDiscovery,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navPages = ['home', 'explore', 'chat', 'profile'];
    final showNav = [
      'home',
      'explore',
      'history',
      'answer',
      'profile',
      'badges',
    ].contains(page);
    final selected = page == 'history'
        ? 1
        : page == 'badges'
        ? 3
        : page == 'answer'
        ? 2
        : navPages.indexOf(page);
    return AgeStyle(
      older: model.older,
      child: LayoutBuilder(
        builder: (context, box) {
          final desktop = box.maxWidth > 600;
          return Scaffold(
            backgroundColor: const Color(0xFFF0EDE8),
            body: Center(
              child: Container(
                width: desktop ? 410 : double.infinity,
                height: desktop ? 850 : double.infinity,
                margin: EdgeInsets.symmetric(vertical: desktop ? 24 : 0),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(desktop ? 38 : 0),
                  border: desktop
                      ? Border.all(color: Colors.white, width: 7)
                      : null,
                  boxShadow: desktop
                      ? [
                          const BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 45,
                            offset: Offset(0, 15),
                          ),
                        ]
                      : null,
                ),
                child: Scaffold(
                  backgroundColor: model.older
                      ? const Color(0xFFF4F6FF)
                      : const Color(0xFFFFFBF2),
                  body: NatureBackground(
                    older: model.older,
                    child: SafeArea(
                      child: Column(
                        children: [
                          if (desktop)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(25, 12, 25, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  tx('9:41', size: 12, weight: FontWeight.w900),
                                  const Row(
                                    children: [
                                      Icon(Icons.signal_cellular_alt, size: 15),
                                      SizedBox(width: 5),
                                      Icon(Icons.wifi, size: 15),
                                      SizedBox(width: 5),
                                      Icon(Icons.battery_full, size: 16),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          Expanded(child: content()),
                        ],
                      ),
                    ),
                  ),
                  bottomNavigationBar: showNav
                      ? (!model.older
                            ? PreschoolNav(
                                selected: selected < 0 ? 0 : selected,
                                onTap: (i) {
                                  history.clear();
                                  go(navPages[i]);
                                },
                              )
                            : NavigationBar(
                                height: 76,
                                backgroundColor: Colors.white,
                                indicatorColor: model.older ? sky : peach,
                                selectedIndex: selected < 0 ? 0 : selected,
                                onDestinationSelected: (i) {
                                  history.clear();
                                  go(navPages[i]);
                                },
                                destinations: const [
                                  NavigationDestination(
                                    icon: Icon(Icons.home_outlined),
                                    selectedIcon: Icon(Icons.home_rounded),
                                    label: 'Home',
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.explore_outlined),
                                    selectedIcon: Icon(Icons.explore_rounded),
                                    label: 'Explore',
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.auto_awesome_outlined),
                                    selectedIcon: Icon(Icons.auto_awesome),
                                    label: 'Curio',
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.person_outline_rounded),
                                    selectedIcon: Icon(Icons.person_rounded),
                                    label: 'Me',
                                  ),
                                ],
                              ))
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
