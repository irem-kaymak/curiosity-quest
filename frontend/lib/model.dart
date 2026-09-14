import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api_service.dart';

const ink = Color(0xFF29324D);
const muted = Color(0xFF7A8092);
const cream = Color(0xFFFFFCF7);
const coral = Color(0xFFEE7183);
const blue = Color(0xFF608DEB);
const peach = Color(0xFFFFE5DE);
const sky = Color(0xFFE4EFFD);
const mint = Color(0xFFE6F3E9);
const lilac = Color(0xFFEDE7FB);
const yellow = Color(0xFFFFF0C7);

class Topic {
  final String name, emoji;
  final Color color;
  const Topic(this.name, this.emoji, this.color);
}

const topics = [
  Topic('Heritage', '🏛️', sky),
  Topic('Animals', '🦁', peach),
  Topic('Nature', '🌿', mint),
  Topic('Space', '🪐', sky),
  Topic('Science', '🔬', lilac),
  Topic('Colors', '🎨', yellow),
  Topic('Food', '🍎', peach),
];

class HypothesisView {
  final String label, confidence, rationale, status;
  const HypothesisView(
    this.label,
    this.confidence,
    this.rationale, {
    this.status = 'active',
  });
}

class EvidenceView {
  final String type, observation, reliability;
  const EvidenceView(this.type, this.observation, this.reliability);
}

class QuestView {
  final String instruction, modality, completionRule, safetyRule;
  const QuestView(
    this.instruction,
    this.modality,
    this.completionRule,
    this.safetyRule,
  );
}

class SafetyEventView {
  final String severity, title, childMessage, parentMessage, recommendedAction;
  final bool notifyParent;
  const SafetyEventView({
    required this.severity,
    required this.title,
    required this.childMessage,
    required this.parentMessage,
    required this.recommendedAction,
    this.notifyParent = true,
  });
}

class InvestigationView {
  final String domain, confidence, uncertainty, parentSummary, kidSummary, status;
  final String policyMessage;
  final List<HypothesisView> hypotheses;
  final List<EvidenceView> evidence;
  final QuestView quest;
  final String curiosityQuestion;
  final List<String> safetyFlags, sources;
  final List<SafetyEventView> safetyEvents;
  final List<String> notificationDeliveries;
  const InvestigationView({
    required this.domain,
    required this.confidence,
    required this.uncertainty,
    required this.parentSummary,
    required this.kidSummary,
    required this.status,
    this.policyMessage = '',
    required this.hypotheses,
    required this.evidence,
    required this.quest,
    this.curiosityQuestion = '',
    required this.safetyFlags,
    required this.sources,
    this.safetyEvents = const [],
    this.notificationDeliveries = const [],
  });
}

class Discovery {
  final String question, answer, topic, emoji, date;
  final InvestigationView? investigation;
  final Uint8List? photoBytes;
  Discovery(
    this.question,
    this.answer,
    this.topic,
    this.emoji,
    this.date, {
    this.investigation,
    this.photoBytes,
  });

  Discovery withPhoto(List<int> bytes) => Discovery(
    question,
    answer,
    topic,
    emoji,
    date,
    investigation: investigation,
    photoBytes: Uint8List.fromList(bytes),
  );
}

class ParentNotification {
  final String severity, title, body, action, time, deliverySummary;
  final bool unread;
  const ParentNotification({
    required this.severity,
    required this.title,
    required this.body,
    required this.action,
    required this.time,
    this.deliverySummary = 'In-app alert ready',
    this.unread = true,
  });
}

class ParentContactView {
  final String email, phone, pushToken;
  final bool emailVerified, phoneVerified, pushEnabled;
  const ParentContactView({
    required this.email,
    required this.phone,
    required this.pushToken,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.pushEnabled = false,
  });
}

class ParentProfileView {
  final String parentId, parentName, childName;
  final ParentContactView contact;
  final List<String> channels;
  const ParentProfileView({
    required this.parentId,
    required this.parentName,
    required this.childName,
    required this.contact,
    this.channels = const [],
  });
}

final seedDiscoveries = [
  Discovery(
    'What is this old fountain?',
    'Let us investigate it. The first photo suggests a historic public fountain, but Curio needs a text clue or side view before giving a final answer.',
    'Heritage',
    '🏛️',
    'Today',
    investigation: demoHeritageInvestigation,
  ),
  Discovery(
    'How do butterflies fly?',
    'Butterflies flap their four wings using strong chest muscles. Their wings push against the air to help them stay up. Nectar from flowers gives them energy!',
    'Animals',
    '🦋',
    'Today',
  ),
  Discovery(
    'Why do lions roar?',
    'Lions roar to talk to each other. Sometimes they say “I am here!” and sometimes they call their family.',
    'Animals',
    '🦁',
    'Yesterday',
  ),
  Discovery(
    'Where do ants live?',
    'Ants often live in nests made of tunnels under the ground. They work together to find food and care for their home.',
    'Animals',
    '🐜',
    'Yesterday',
  ),
  Discovery(
    'Why does the Moon look different?',
    'The Moon does not change shape. The Sun lights up half of it. As the Moon travels around Earth, we see its bright side from different angles.',
    'Space',
    '🌙',
    'Yesterday',
  ),
  Discovery(
    'How do plants grow?',
    'Plants take in water through their roots. Their leaves use sunlight to make food. Water, air and light help them grow!',
    'Nature',
    '🌱',
    '2 days ago',
  ),
  Discovery(
    'How does a rainbow form?',
    'Sunlight splits into different colors as it passes through raindrops. The colorful arc we see in the sky is a rainbow!',
    'Colors',
    '🌈',
    '3 days ago',
  ),
];

class QuizQuestion {
  final String title, emoji, explanation;
  final List<String> choices;
  final int correct;
  const QuizQuestion(
    this.title,
    this.emoji,
    this.choices,
    this.correct,
    this.explanation,
  );
}

const littleQuiz = [
  QuizQuestion(
    'What do butterflies use to fly?',
    '🦋',
    ['🪽  Their wings', '🐾  Their feet', '👂  Their ears'],
    0,
    'Yes! Butterflies flap their four wings to fly.',
  ),
  QuizQuestion(
    'Which animal roars?',
    '🔊',
    ['🐰  Rabbit', '🦁  Lion', '🐢  Turtle'],
    1,
    'Lions roar to talk to each other.',
  ),
  QuizQuestion(
    'What do plants need to grow?',
    '🌱',
    ['🧸  Toys', '☀️  Light and water', '🧤  Gloves'],
    1,
    'Plants grow with water, air and sunlight.',
  ),
];
const olderQuiz = [
  QuizQuestion(
    'What helps a butterfly fly?',
    '🦋',
    ['Wings pushing against the air', 'Antennae spinning', 'Feet swinging'],
    0,
    'Wings push against the air to help the butterfly stay up.',
  ),
  QuizQuestion(
    'Why does the Moon seem to change shape?',
    '🌙',
    [
      'It shrinks every day',
      'We see its bright side from different angles',
      'Clouds paint it',
    ],
    1,
    'The Moon keeps its shape. We see the sunlit part from different angles.',
  ),
  QuizQuestion(
    'What energy do plants use to make food?',
    '🌱',
    ['Sound energy', 'Sunlight', 'Battery energy'],
    1,
    'Plants use sunlight to make food. This is called photosynthesis.',
  ),
];

const demoHeritageInvestigation = InvestigationView(
  domain: 'heritage',
  confidence: 'medium',
  status: 'needs_evidence',
  uncertainty:
      'We should not name the structure from one photo. The inscription or side geometry can change the answer.',
  parentSummary:
      'Curiosity Quest is running an evidence loop: it starts with hypotheses, asks for the most useful missing clue, and keeps the conclusion provisional until a second observation arrives.',
  kidSummary:
      'We have a smart guess, but we need one more clue. The writing or the side shape can help us change or strengthen our idea.',
  hypotheses: [
    HypothesisView(
      'Ottoman-era public fountain',
      'medium',
      'Stonework and an arch-like niche fit a civic water structure.',
    ),
    HypothesisView(
      'Restored replica',
      'low',
      'Fresh stone or missing wear could mean it was rebuilt.',
    ),
    HypothesisView(
      'Facade detail',
      'low',
      'A cropped image can confuse a fountain niche with another wall detail.',
    ),
  ],
  evidence: [
    EvidenceView(
      'photo',
      'Initial image shows stone, arch form, and possible inscription area.',
      'medium',
    ),
    EvidenceView(
      'policy',
      'Faces, plates, and precise child location should be stripped before storage.',
      'high',
    ),
  ],
  quest: QuestView(
    'Use zoom to capture the inscription or nearby information plaque, then take one side photo showing the arch and basin.',
    'photo + OCR',
    'One readable text clue or one side-angle clue is visible.',
    'Stay with an adult. Do not climb, cross traffic, or enter private areas.',
  ),
  curiosityQuestion: 'What clue should we look for first?',
  safetyFlags: [
    'child safe distance',
    'privacy minimization',
    'no private property',
  ],
  sources: [
    'Local heritage registry allowlist',
    'Plaque OCR',
    'Architectural feature checklist',
  ],
  notificationDeliveries: ['In-app alert ready'],
);

/// Replace with a server-backed implementation; never place AI keys in the app.
abstract class LearningService {
  Future<Discovery> ask(
    String question,
    bool older, {
    ParentContactView? parentContact,
  });
  Future<Discovery> askWithImage(
    String question,
    List<int> imageBytes, {
    required String filename,
    required String contentType,
    required bool older,
    ParentContactView? parentContact,
  });
  List<QuizQuestion> quiz(bool older);
  Future<List<QuizQuestion>> dynamicQuiz(bool older);
}

abstract class AccountService {
  Future<ParentProfileView> registerParent({
    required String parentName,
    required String childName,
    required ParentContactView contact,
  });
}

class DemoLearningService implements LearningService {
  @override
  List<QuizQuestion> quiz(bool older) => older ? olderQuiz : littleQuiz;
  @override
  Future<List<QuizQuestion>> dynamicQuiz(bool older) async => quiz(older);
  @override
  Future<Discovery> ask(
    String question,
    bool older, {
    ParentContactView? parentContact,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final q = question.toLowerCase();
    if (RegExp(
      r'\b(fountain|historic|building|inscription|museum|monument|ottoman)\b',
    ).hasMatch(q)) {
      return Discovery(
        question,
        older
            ? demoHeritageInvestigation.parentSummary
            : demoHeritageInvestigation.kidSummary,
        'Heritage',
        '🏛️',
        'Today',
        investigation: demoHeritageInvestigation,
      );
    }
    final matches = {
      r'\bbutterfl(?:y|ies)\b': 1,
      r'\blions?\b': 2,
      r'\bants?\b': 3,
      r'\bmoon\b': 4,
      r'\bplants?\b': 5,
      r'\brainbows?\b': 6,
    };
    for (final entry in matches.entries) {
      if (RegExp(entry.key).hasMatch(q)) {
        final d = seedDiscoveries[entry.value];
        return Discovery(
          question,
          older ? d.answer : d.answer.split('. ').take(2).join('. '),
          d.topic,
          d.emoji,
          'Today',
        );
      }
    }
    return Discovery(
      question,
      'I saved your question! In this demo, I can talk about butterflies, lions, ants, the Moon, plants and rainbows. Which one shall we explore?',
      'Science',
      '✨',
      'Today',
    );
  }

  @override
  Future<Discovery> askWithImage(
    String question,
    List<int> imageBytes, {
    required String filename,
    required String contentType,
    required bool older,
    ParentContactView? parentContact,
  }) =>
      ask(question, older);
}

class DemoAccountService implements AccountService {
  @override
  Future<ParentProfileView> registerParent({
    required String parentName,
    required String childName,
    required ParentContactView contact,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return ParentProfileView(
      parentId: 'parent_demo',
      parentName: parentName,
      childName: childName,
      contact: contact,
      channels: const ['in_app', 'push', 'email', 'sms'],
    );
  }
}

class AppModel extends ChangeNotifier {
  AppModel({LearningService? learning, AccountService? account})
      : learning = learning ?? ApiLearningService(),
        account = account ?? ApiAccountService();

  bool older = false;
  String parentId = '',
      parentName = 'Parent',
      childName = 'Elif',
      mascot = '⭐',
      email = 'parent@example.com',
      phone = '0532 000 00 00',
      parentPushToken = 'demo-parent-device-token',
      parentPassword = 'CurioParent!9';
  int dailyLimit = 45, quizCompleted = 0;
  bool voice = true,
      photos = true,
      reminders = true,
      emailVerified = true,
      phoneVerified = true,
      pushEnabled = true;
  bool safetyAlerts = true, weeklyDigest = true;
  final discoveries = <Discovery>[];
  final LearningService learning;
  final AccountService account;
  Color get accent => older ? blue : coral;
  void update(VoidCallback action) {
    action();
    notifyListeners();
  }

  List<Discovery> history(String topic) =>
      discoveries.where((d) => d.topic == topic).toList();

  List<Discovery> get flaggedQuestions => discoveries.where((discovery) {
        final hasSafetyEvent =
            discovery.investigation?.safetyEvents.isNotEmpty ?? false;
        return hasSafetyEvent || reviewReason(discovery.question) != null;
      }).toList();

  List<ParentNotification> get notifications {
    if (!safetyAlerts) {
      return const [
        ParentNotification(
          severity: 'safe',
          title: 'Safety alerts paused',
          body: 'Immediate parent alerts are disabled in settings.',
          action: 'Turn alerts back on before unsupervised photo questions.',
          time: 'Now',
          deliverySummary: 'All safety delivery channels paused',
          unread: false,
        ),
      ];
    }
    final items = <ParentNotification>[];
    for (final discovery in discoveries) {
      final investigation = discovery.investigation;
      if (investigation == null) continue;
      for (final event in investigation.safetyEvents) {
        if (!event.notifyParent) continue;
        items.add(
          ParentNotification(
            severity: event.severity,
            title: event.title,
            body: event.parentMessage,
            action: event.recommendedAction,
            time: discovery.date,
            deliverySummary: investigation.notificationDeliveries.isEmpty
                ? 'In-app queued; push, email and SMS use verified parent contact.'
                : investigation.notificationDeliveries.join('; '),
          ),
        );
      }
    }
    if (items.isEmpty) {
      items.add(
        const ParentNotification(
          severity: 'safe',
          title: 'No urgent alerts',
          body: 'Curio has not detected a safety event in this session.',
          action: 'Review learning settings anytime.',
          time: 'Now',
          deliverySummary: 'No delivery needed',
          unread: false,
        ),
      );
    }
    return items;
  }

  ParentContactView get parentContact => ParentContactView(
        email: email,
        phone: phone,
        pushToken: parentPushToken,
        emailVerified: emailVerified,
        phoneVerified: phoneVerified,
        pushEnabled: pushEnabled,
      );

  Future<bool> registerParentAccount({
    required String newParentName,
    required String newChildName,
    required String newEmail,
    required String newPhone,
    required String newParentPassword,
  }) async {
    final contact = ParentContactView(
      email: newEmail,
      phone: newPhone,
      pushToken: parentPushToken,
      emailVerified: true,
      phoneVerified: true,
      pushEnabled: true,
    );
    final profile = await account.registerParent(
      parentName: newParentName,
      childName: newChildName,
      contact: contact,
    );
    parentId = profile.parentId;
    parentName = profile.parentName;
    childName = profile.childName;
    email = profile.contact.email;
    phone = profile.contact.phone;
    parentPassword = newParentPassword;
    parentPushToken = profile.contact.pushToken;
    emailVerified = profile.contact.emailVerified;
    phoneVerified = profile.contact.phoneVerified;
    pushEnabled = profile.contact.pushEnabled;
    notifyListeners();
    return parentId.isNotEmpty;
  }
}

String? reviewReason(String question) {
  if (RegExp(
    r'\b(kill|hurt|weapon|gun|knife|blade|bomb|suicide|blood|fire|smoke)\b',
    caseSensitive: false,
  ).hasMatch(question)) {
    return 'Potential harm or emergency topic';
  }
  if (RegExp(
    r'\b(sex|porn|naked|drugs|alcohol)\b',
    caseSensitive: false,
  ).hasMatch(question)) {
    return 'Age-sensitive content';
  }
  return null;
}
