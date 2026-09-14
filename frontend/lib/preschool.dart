import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'model.dart';
import 'ui.dart';
import 'narration.dart';
import 'screens.dart' show HomeScreen;

const apricot = Color(0xFFFFE0C9);
const butter = Color(0xFFFFEFAF);
const rose = Color(0xFFFFDFDE);
const leaf = Color(0xFFEAF0CF);

class PreschoolNav extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;
  const PreschoolNav({super.key, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == i,
                label: ['Home', 'Explore', 'Ask', 'Me'][i],
                child: ExcludeSemantics(
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: selected == i ? apricot : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          i == 2
                              ? const Mascot(size: 32)
                              : Text(
                                  ['🏠', '🌍', '⭐', '👧🏻'][i],
                                  style: const TextStyle(fontSize: 28),
                                ),
                          gap(3),
                          tx(['Home', 'Explore', 'Ask', 'Me'][i], size: 11),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class PictureButton extends StatelessWidget {
  final String label, description;
  final String? emoji;
  final IconData? icon;
  final Widget? picture;
  final Color color;
  final VoidCallback? onTap;
  final bool selected;
  final double height;
  const PictureButton({
    super.key,
    required this.label,
    required this.description,
    this.emoji,
    this.icon,
    this.picture,
    this.color = butter,
    this.onTap,
    this.selected = false,
    this.height = 140,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: description,
    selected: selected,
    enabled: onTap != null,
    child: ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: selected ? Border.all(color: coral, width: 3) : null,
        ),
        child: SoftCard(
          color: color,
          onTap: onTap,
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child:
                        picture ??
                        (emoji != null
                            ? Text(emoji!, style: const TextStyle(fontSize: 64))
                            : Icon(icon, size: 64, color: ink)),
                  ),
                ),
                gap(6),
                tx(label, size: 12, weight: FontWeight.w800),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ListenButton extends StatefulWidget {
  final String text;
  const ListenButton(this.text, {super.key});
  @override
  State<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<ListenButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Listen aloud',
    button: true,
    child: IconButton.filledTonal(
      tooltip: 'Listen',
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        minimumSize: const Size(56, 56),
      ),
      onPressed: busy
          ? null
          : () async {
              setState(() => busy = true);
              final ok = await Narration.speak(widget.text);
              if (!context.mounted) return;
              setState(() => busy = false);
              if (!ok) {
                notice(
                  context,
                  'No English voice found. Add an English voice in your device speech settings.',
                );
              }
            },
      icon: Icon(busy ? Icons.more_horiz : Icons.volume_up_rounded, size: 30),
    ),
  );
}

Widget pictureGrid(List<Widget> children) => GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 14,
  mainAxisSpacing: 14,
  childAspectRatio: .98,
  children: children,
);
String pictureName(Discovery d) => switch (d.emoji) {
  '🏛️' => 'Fountain',
  '🦋' => 'Butterfly',
  '🦁' => 'Lion',
  '🐜' => 'Ant',
  '🌙' => 'Moon',
  '🌱' => 'Plant',
  '🌿' => 'Nature',
  '🌈' => 'Rainbow',
  _ => 'Discovery',
};

String preschoolBadgeTitle(Discovery discovery) {
  final investigation = discovery.investigation;
  if (investigation == null) return 'First Question';
  final policy = investigation.policyMessage;
  if (policy.contains('Badge earned:')) {
    return policy.split('Badge earned:').last.split('.').first.trim();
  }
  if (investigation.safetyEvents.isNotEmpty) return 'Safety Star';
  if (investigation.domain == 'heritage') return 'Time Detective';
  if (investigation.domain == 'safe_dining') return 'Careful Taster';
  if (investigation.domain == 'general') return 'Question Explorer';
  return 'Nature Explorer';
}

String preschoolNextPrompt(Discovery discovery) {
  final investigation = discovery.investigation;
  final curiosity = investigation?.curiosityQuestion.trim() ?? '';
  if (curiosity.isNotEmpty) return curiosity;
  final mission = investigation?.quest.instruction.trim() ?? '';
  if (mission.isNotEmpty) return mission;
  return 'What is one tiny clue you can notice next?';
}

String preschoolBadgeEmoji(InvestigationView? investigation, String fallback) {
  if (investigation == null) return fallback;
  if (investigation.domain == 'heritage') return '🏛️';
  if (investigation.domain == 'safe_dining') return '🛡️';
  if (investigation.domain == 'general') return '💡';
  return '🌿';
}

List<({String emoji, String title, String description, bool earned})>
preschoolBadgeEntries(AppModel model) {
  final earned =
      <String, ({String emoji, String title, String description, bool earned})>{};
  for (final discovery in model.discoveries) {
    final title = preschoolBadgeTitle(discovery);
    earned[title] = (
      emoji: preschoolBadgeEmoji(discovery.investigation, discovery.emoji),
      title: title,
      description: discovery.investigation == null
          ? 'You asked a question and saved it.'
          : 'Unlocked from your ${discovery.topic.toLowerCase()} case.',
      earned: true,
    );
  }
  if (model.quizCompleted > 0) {
    earned['Puzzle Solver'] = (
      emoji: '🧩',
      title: 'Puzzle Solver',
      description: 'You completed a live mission deck.',
      earned: true,
    );
  }
  if (model.discoveries.length >= 3) {
    earned['Case Archivist'] = (
      emoji: '🗂️',
      title: 'Case Archivist',
      description: 'You saved three investigation cards.',
      earned: true,
    );
  }
  final entries = earned.values.toList();
  entries.addAll([
    if (!earned.containsKey('Puzzle Solver'))
      (
        emoji: '🧩',
        title: 'Puzzle Solver',
        description: 'Complete a live puzzle deck.',
        earned: false,
      ),
    if (!earned.containsKey('Case Archivist'))
      (
        emoji: '🗂️',
        title: 'Case Archivist',
        description: 'Save three investigation cards.',
        earned: false,
      ),
  ]);
  return entries.isEmpty
      ? [
          (
            emoji: '🔎',
            title: 'First Case',
            description: 'Start an investigation to unlock your first badge.',
            earned: false,
          ),
        ]
      : entries;
}

List<Discovery> preschoolStarterCases(AppModel model) {
  final fromHistory = model.discoveries
      .where((d) => d.question.trim().isNotEmpty)
      .take(4)
      .toList();
  if (fromHistory.length >= 2) return fromHistory;

  final starters = <Discovery>[
    Discovery(
      'What is in this photo?',
      'Open a new visual case.',
      'Science',
      '🔎',
      'Now',
    ),
    Discovery(
      'What clue should we check first?',
      'Practice looking closely.',
      'Science',
      '👀',
      'Now',
    ),
    Discovery(
      'Is this safe to touch?',
      'Safety comes before curiosity.',
      'Science',
      '🛡️',
      'Now',
    ),
    Discovery(
      'Why does it look like that?',
      'Turn a question into a mini case.',
      'Science',
      '✨',
      'Now',
    ),
  ];

  return [
    ...fromHistory,
    ...starters,
  ].take(4).toList();
}

class PreschoolHome extends StatelessWidget {
  final AppModel model;
  final void Function(String) go;
  final void Function(Discovery) open;
  const PreschoolHome({
    super.key,
    required this.model,
    required this.go,
    required this.open,
  });
  @override
  Widget build(BuildContext context) =>
      HomeScreen(model: model, go: go, category: (_) {}, open: open);
}

class PreschoolExplore extends StatelessWidget {
  final AppModel model;
  final void Function(String) category;
  const PreschoolExplore({
    super.key,
    required this.model,
    required this.category,
  });
  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      Row(
        children: [
          Expanded(child: tx('Explore', size: 20)),
          ListenButton(
            'Tap a picture. Your discoveries about animals, plants, space and more are here.',
          ),
        ],
      ),
      gap(20),
      pictureGrid([
        for (var i = 0; i < topics.length; i++)
          PictureButton(
            label: topics[i].name,
            description:
                '${topics[i].name}, ${model.history(topics[i].name).length} discoveries',
            emoji: topics[i].emoji,
            color: [apricot, leaf, butter, rose][i % 4],
            onTap: () => category(topics[i].name),
          ),
      ]),
    ],
  );
}

class PreschoolHistory extends StatelessWidget {
  final AppModel model;
  final String topic;
  final VoidCallback back;
  final void Function(Discovery) open;
  final void Function(String) go;
  const PreschoolHistory({
    super.key,
    required this.model,
    required this.topic,
    required this.back,
    required this.open,
    required this.go,
  });
  @override
  Widget build(BuildContext context) {
    final items = model.history(topic);
    return ScreenBody(
      children: [
        PageHeader(
          topic,
          back: back,
          trailing: ListenButton(
            'Tap a picture. Let us listen to your earlier question again.',
          ),
        ),
        gap(20),
        if (items.isEmpty) ...[
          const Center(child: Mascot(size: 170)),
          gap(24),
          PictureButton(
            label: 'Ask',
            description: 'Ask your first question',
            icon: Icons.add_comment_rounded,
            color: apricot,
            onTap: () => go('chat'),
          ),
        ] else
          pictureGrid([
            for (final d in items)
              PictureButton(
                label: pictureName(d),
                description: d.question,
                emoji: d.emoji,
                color: butter,
                onTap: () => open(d),
              ),
          ]),
      ],
    );
  }
}

class PreschoolAnswer extends StatefulWidget {
  final AppModel model;
  final Discovery discovery;
  final VoidCallback back;
  final void Function(String) go;
  const PreschoolAnswer({
    super.key,
    required this.model,
    required this.discovery,
    required this.back,
    required this.go,
  });

  @override
  State<PreschoolAnswer> createState() => _PreschoolAnswerState();
}

class _PreschoolAnswerState extends State<PreschoolAnswer> {
  late Discovery current;
  final reply = TextEditingController();
  bool waiting = false;

  @override
  void initState() {
    super.initState();
    current = widget.discovery;
  }

  @override
  void didUpdateWidget(covariant PreschoolAnswer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discovery != widget.discovery) {
      current = widget.discovery;
      reply.clear();
    }
  }

  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  Future<void> sendReply() async {
    final childAnswer = reply.text.trim();
    if (childAnswer.isEmpty || waiting) return;
    setState(() => waiting = true);
    final prompt =
        'Previous Curio case: ${current.question}. Curio finding: ${current.answer}. '
        'Curio asked the child: ${preschoolNextPrompt(current)}. '
        'Child answer: $childAnswer. Reply warmly for a 3-6 year old, answer the child directly, and ask one next tiny follow-up question.';
    try {
      final result = await widget.model.learning.ask(
        prompt,
        false,
        parentContact: widget.model.parentContact,
      );
      if (!mounted) return;
      final displayResult = Discovery(
        childAnswer,
        result.answer,
        result.topic,
        result.emoji,
        result.date,
        investigation: result.investigation,
        photoBytes: current.photoBytes,
      );
      widget.model.update(() => widget.model.discoveries.insert(0, displayResult));
      setState(() {
        current = displayResult;
        waiting = false;
        reply.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => waiting = false);
      notice(context, 'Curio could not hear that clue. Try one more time.');
    }
  }

  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      PageHeader(
        'Case board',
        back: widget.back,
        trailing: ListenButton('${current.question} ${current.answer}'),
      ),
      gap(24),
      SoftCard(
        color: butter,
        child: Column(
          children: [
            Row(
              children: [
                const Mascot(size: 58),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tx('Curio case board', size: 14, color: const Color(0xFF4E72B5)),
                      tx('Evidence checked', size: 10, color: muted),
                    ],
                  ),
                ),
                Tag(
                  current.investigation?.status == 'concluded'
                      ? 'CASE SOLVED'
                      : 'CASE OPEN',
                ),
                if (current.investigation != null) ...[
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: 'Open case board',
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => PreschoolCaseBoardSheet(discovery: current),
                    ),
                    icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
                  ),
                ],
              ],
            ),
            gap(14),
            gap(12),
            if (current.photoBytes == null)
              Text(current.emoji, style: const TextStyle(fontSize: 132))
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(
                    current.photoBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            gap(18),
            tx(current.question, size: 17, weight: FontWeight.w900, align: TextAlign.center),
          ],
        ),
      ),
      gap(20),
      if (current.investigation?.safetyEvents.isNotEmpty == true) ...[
        PreschoolSafetyAlert(current.investigation!.safetyEvents.first),
        gap(20),
      ],
      SoftCard(
        color: leaf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tx('Curio found', size: 12, weight: FontWeight.w900),
            gap(8),
            tx(current.answer, size: 17, weight: FontWeight.w900),
            if (current.investigation != null) ...[
              gap(14),
              tx('Tiny mission', size: 12, weight: FontWeight.w900),
              gap(7),
              tx(current.investigation!.quest.instruction, size: 13),
              if (current.investigation!.quest.safetyRule.trim().isNotEmpty) ...[
                gap(8),
                tx(
                  current.investigation!.quest.safetyRule,
                  size: 12,
                  color: const Color(0xFF6F6639),
                ),
              ],
            ],
          ],
        ),
      ),
      gap(18),
      SoftCard(
        color: apricot,
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFC68124), size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tx('Badge unlocked', size: 12, weight: FontWeight.w900, color: const Color(0xFFC68124)),
                  gap(4),
                  tx(preschoolBadgeTitle(current), size: 17, weight: FontWeight.w900),
                ],
              ),
            ),
          ],
        ),
      ),
      gap(18),
      SoftCard(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tx('Curio asks', size: 12, weight: FontWeight.w900, color: const Color(0xFFC68124)),
            gap(8),
            tx(preschoolNextPrompt(current), size: 17, weight: FontWeight.w900),
            gap(14),
            TextField(
              controller: reply,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendReply(),
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                filled: true,
                fillColor: const Color(0xFFF8F6F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE9E5E2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE9E5E2)),
                ),
              ),
            ),
            gap(12),
            PrimaryButton(
              waiting ? 'Curio is thinking...' : 'Answer Curio',
              icon: Icons.arrow_forward_rounded,
              onTap: waiting ? null : sendReply,
              color: const Color(0xFF6387F2),
            ),
          ],
        ),
      ),
      gap(20),
      Row(
        children: [
          const Icon(Icons.bookmark_added_rounded, color: Color(0xFF718B48)),
          const SizedBox(width: 8),
          tx('Saved', size: 12),
        ],
      ),
      gap(24),
      PictureButton(
        label: 'Ask',
        description: 'Ask a new question',
        icon: Icons.add_comment_rounded,
        color: apricot,
        height: 90,
        onTap: () => widget.go('chat'),
      ),
    ],
  );
}

class PreschoolCaseBoardSheet extends StatelessWidget {
  final Discovery discovery;
  const PreschoolCaseBoardSheet({super.key, required this.discovery});

  @override
  Widget build(BuildContext context) {
    final investigation = discovery.investigation;
    final theory = investigation?.hypotheses.isNotEmpty == true
        ? investigation!.hypotheses.first.label
        : discovery.topic;
    final clues = investigation?.evidence
            .map((e) => e.observation)
            .where((item) => item.trim().isNotEmpty)
            .take(3)
            .toList() ??
        const <String>[];
    return DraggableScrollableSheet(
      initialChildSize: .9,
      maxChildSize: .96,
      minChildSize: .68,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DCE6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              gap(16),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close case board',
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: tx(discovery.question, size: 19, weight: FontWeight.w900)),
                  const Tag('+40 XP'),
                ],
              ),
              gap(16),
              if (discovery.photoBytes == null)
                Center(child: Text(discovery.emoji, style: const TextStyle(fontSize: 100)))
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.memory(discovery.photoBytes!, fit: BoxFit.cover),
                  ),
                ),
              gap(16),
              PreschoolCaseBoardSection(
                icon: Icons.search_rounded,
                title: 'Clues',
                body: clues.isEmpty ? 'Curio used your question as the first clue.' : clues.join('\n'),
                color: butter,
              ),
              gap(10),
              PreschoolCaseBoardSection(
                icon: Icons.psychology_alt_outlined,
                title: 'My Theory',
                body: theory,
                color: apricot,
              ),
              gap(10),
              PreschoolCaseBoardSection(
                icon: Icons.auto_awesome_rounded,
                title: 'Curio Finding',
                body: discovery.answer,
                color: leaf,
              ),
              gap(10),
              PreschoolCaseBoardSection(
                icon: Icons.flag_outlined,
                title: 'Next Mission',
                body: preschoolNextPrompt(discovery),
                color: Colors.white,
              ),
              gap(16),
              SoftCard(
                color: apricot,
                child: Row(
                  children: [
                    const Text('🏅', style: TextStyle(fontSize: 44)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tx('Badge unlocked', size: 12, color: const Color(0xFFB06F1F), weight: FontWeight.w900),
                          gap(3),
                          tx(preschoolBadgeTitle(discovery), size: 16, weight: FontWeight.w900),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreschoolCaseBoardSection extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Color color;
  const PreschoolCaseBoardSection({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SoftCard(
    color: color,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: coral),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tx(title, size: 12, weight: FontWeight.w900),
              gap(6),
              tx(body, size: 14, weight: FontWeight.w700),
            ],
          ),
        ),
      ],
    ),
  );
}

class PreschoolSafetyAlert extends StatelessWidget {
  final SafetyEventView event;
  const PreschoolSafetyAlert(this.event, {super.key});

  @override
  Widget build(BuildContext context) => SoftCard(
    color: event.severity == 'emergency' ? rose : apricot,
    child: Column(
      children: [
        Icon(
          event.severity == 'emergency'
              ? Icons.emergency_share_rounded
              : Icons.warning_amber_rounded,
          color: coral,
          size: 42,
        ),
        gap(10),
        tx(event.title, size: 16, weight: FontWeight.w900, align: TextAlign.center),
        gap(8),
        tx(event.childMessage, size: 14, align: TextAlign.center),
      ],
    ),
  );
}

class PreschoolChat extends StatefulWidget {
  final AppModel model;
  final VoidCallback back;
  const PreschoolChat({super.key, required this.model, required this.back});
  @override
  State<PreschoolChat> createState() => _PreschoolChatState();
}

class _PreschoolChatState extends State<PreschoolChat> {
  final picker = ImagePicker();
  final prompt = TextEditingController();
  Discovery? answer;
  bool waiting = false;

  @override
  void dispose() {
    prompt.dispose();
    super.dispose();
  }

  Future<void> ask(Discovery d) async {
    if (waiting) return;
    setState(() => waiting = true);
    try {
      final result = await widget.model.learning.ask(
        d.question,
        false,
        parentContact: widget.model.parentContact,
      );
      if (!mounted) return;
      widget.model.update(() => widget.model.discoveries.insert(0, result));
      setState(() {
        answer = result;
        waiting = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => waiting = false);
        notice(context, 'Let us try again.');
      }
    }
  }

  Future<void> askText() async {
    final question = prompt.text.trim();
    if (question.isEmpty || waiting) return;
    setState(() => waiting = true);
    try {
      final result = await widget.model.learning.ask(
        question,
        false,
        parentContact: widget.model.parentContact,
      );
      if (!mounted) return;
      widget.model.update(() => widget.model.discoveries.insert(0, result));
      setState(() {
        answer = result;
        waiting = false;
        prompt.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => waiting = false);
      notice(context, 'Curio could not answer yet. Try one more question.');
    }
  }

  Future<void> askPhoto() async {
    if (waiting) return;
    if (!widget.model.photos) {
      notice(context, 'Photo questions are disabled in parent settings.');
      return;
    }
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null) return;
    setState(() => waiting = true);
    try {
      final bytes = await image.readAsBytes();
      final result = (await widget.model.learning.askWithImage(
        'What is in this photo?',
        bytes,
        filename: image.name,
        contentType: image.mimeType ?? 'image/jpeg',
        older: false,
        parentContact: widget.model.parentContact,
      )).withPhoto(bytes);
      if (!mounted) return;
      widget.model.update(() => widget.model.discoveries.insert(0, result));
      setState(() {
        answer = result;
        waiting = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => waiting = false);
        notice(context, 'Let us try another photo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
	    if (answer != null) {
	      return PreschoolAnswer(
        model: widget.model,
	        discovery: answer!,
	        back: () {
	          Narration.stop();
	          setState(() => answer = null);
        },
        go: (_) => setState(() => answer = null),
      );
    }
	    return ScreenBody(
	      children: [
	        PageHeader(
	          'Ask',
	          back: widget.back,
	          trailing: const ListenButton(
	            'What should Curio investigate? Add a photo or type your idea.',
	          ),
	        ),
	        gap(16),
	        SoftCard(
	          color: butter,
	          child: Column(
	            children: [
	              const Mascot(size: 130),
	              gap(14),
	              tx(
	                'What are we investigating?',
	                size: 24,
	                weight: FontWeight.w900,
	                align: TextAlign.center,
	              ),
	              gap(8),
	              tx(
	                'Start one case. Curio answers, asks a tiny follow-up, and saves the badge.',
	                size: 14,
	                color: muted,
	                align: TextAlign.center,
	              ),
	              gap(18),
	              PrimaryButton(
	                waiting ? 'Building the case...' : 'Use a photo',
	                icon: Icons.camera_alt_rounded,
	                color: const Color(0xFF6387F2),
	                onTap: waiting ? null : askPhoto,
	              ),
	            ],
	          ),
	        ),
	        gap(18),
	        SoftCard(
	          color: Colors.white,
	          child: Column(
	            crossAxisAlignment: CrossAxisAlignment.start,
	            children: [
	              tx(
	                'Ask with words',
	                size: 12,
	                weight: FontWeight.w900,
	                color: const Color(0xFFC68124),
	              ),
	              gap(8),
	              TextField(
	                controller: prompt,
	                minLines: 1,
	                maxLines: 3,
	                textInputAction: TextInputAction.send,
	                onSubmitted: (_) => askText(),
	                decoration: InputDecoration(
	                  hintText: 'I wonder...',
	                  filled: true,
	                  fillColor: const Color(0xFFF8F6F2),
	                  prefixIcon: const Icon(Icons.psychology_alt_rounded),
	                  suffixIcon: IconButton(
	                    tooltip: 'Voice input',
	                    onPressed: () => notice(
	                      context,
	                      widget.model.voice
	                          ? 'Voice input needs speech-to-text. Type your idea here for now.'
	                          : 'Voice questions are disabled in parent settings.',
	                    ),
	                    icon: const Icon(Icons.mic_rounded),
	                  ),
	                  border: OutlineInputBorder(
	                    borderRadius: BorderRadius.circular(18),
	                    borderSide: const BorderSide(color: Color(0xFFE9E5E2)),
	                  ),
	                  enabledBorder: OutlineInputBorder(
	                    borderRadius: BorderRadius.circular(18),
	                    borderSide: const BorderSide(color: Color(0xFFE9E5E2)),
	                  ),
	                ),
	              ),
	              gap(12),
	              PrimaryButton(
	                waiting ? 'Curio is thinking...' : 'Ask Curio',
	                icon: Icons.arrow_forward_rounded,
	                onTap: waiting ? null : askText,
	              ),
	            ],
	          ),
	        ),
	        if (widget.model.discoveries.isNotEmpty) ...[
	          gap(18),
	          SoftCard(
	            color: leaf,
	            onTap: () => setState(() => answer = widget.model.discoveries.first),
	            child: Row(
	              children: [
	                const Icon(Icons.history_rounded, size: 38, color: Color(0xFF718B48)),
	                const SizedBox(width: 12),
	                Expanded(
	                  child: Column(
	                    crossAxisAlignment: CrossAxisAlignment.start,
	                    children: [
	                      tx('Continue last case', size: 12, weight: FontWeight.w900),
	                      gap(4),
	                      tx(
	                        widget.model.discoveries.first.question,
	                        size: 14,
	                        weight: FontWeight.w800,
	                      ),
	                    ],
	                  ),
	                ),
	              ],
	            ),
	          ),
	        ],
	        if (waiting) ...[
	          gap(18),
	          const Center(child: CircularProgressIndicator()),
	        ],
	      ],
	    );
	  }
}

class VisualQuestion {
  final String prompt, emoji;
  final List<String> pictures, labels;
  final int correct;
  final String explanation;
  const VisualQuestion(
    this.prompt,
    this.emoji,
    this.pictures,
    this.labels,
    this.correct,
    this.explanation,
  );
}

const visualQuestions = [
  VisualQuestion(
    'Which one can fly? Tap its picture.',
    '☁️',
    ['🦋', '🐰', '🐢'],
    ['Butterfly', 'Rabbit', 'Turtle'],
    0,
    'A butterfly uses its wings to fly.',
  ),
  VisualQuestion(
    'Which one roars? Tap its picture.',
    '🔊',
    ['🐑', '🦁', '🐰'],
    ['Sheep', 'Lion', 'Rabbit'],
    1,
    'A lion roars. Lions roar to talk to each other.',
  ),
  VisualQuestion(
    'Which one helps a plant grow?',
    '🌱',
    ['🧸', '☀️', '🧤'],
    ['Toy', 'Sun', 'Glove'],
    1,
    'Plants use sunlight to make food.',
  ),
];

class PreschoolQuiz extends StatefulWidget {
  final AppModel model;
  final VoidCallback back;
  const PreschoolQuiz({super.key, required this.model, required this.back});
  @override
  State<PreschoolQuiz> createState() => _PreschoolQuizState();
}

class _PreschoolQuizState extends State<PreschoolQuiz> {
  int step = -1, score = 0;
  int? selected;
  bool checked = false;
  bool loadingQuestions = true;
  String? loadingError;
  List<QuizQuestion> questions = const [];

  @override
  void initState() {
    super.initState();
    questions = widget.model.learning.quiz(false);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final loaded = await widget.model.learning.dynamicQuiz(false);
      if (!mounted) return;
      setState(() {
        questions = loaded.isEmpty ? questions : loaded;
        loadingQuestions = false;
        loadingError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loadingQuestions = false;
        loadingError = 'Curio could not build live mission cards yet.';
      });
    }
  }

  void next() {
    Narration.stop();
    if (!checked) {
      setState(() {
        checked = true;
        if (selected == questions[step].correct) score++;
      });
      return;
    }
    setState(() {
      step++;
      selected = null;
      checked = false;
    });
    if (step == questions.length) {
      widget.model.update(() => widget.model.quizCompleted++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (step < 0) {
      return ScreenBody(
        children: [
          PageHeader('Puzzle time', back: widget.back),
          gap(28),
          const Center(child: Tag('🧩  YOUR MINI QUIZ', color: butter)),
          gap(20),
          const Center(child: Mascot(size: 185)),
          gap(12),
          tx(
            'Turn your curiosity\ninto a game!',
            size: 32,
            weight: FontWeight.w900,
            align: TextAlign.center,
          ),
          gap(14),
          tx(
            'Little questions about your discoveries.\nThink, choose and learn together.',
            size: 15,
            color: muted,
            align: TextAlign.center,
          ),
          gap(27),
          const SoftCard(
            color: butter,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 5,
              children: [
                Tag('3 questions', color: butter),
                Tag('~3 minutes', color: butter),
                Tag('No time pressure', color: butter),
              ],
            ),
          ),
          gap(27),
          PrimaryButton(
            loadingQuestions
                ? 'Building mission cards...'
                : loadingError == null
                ? 'Ready, let us play!'
                : 'Try again',
            onTap: loadingQuestions
                ? null
                : loadingError == null
                ? () => setState(() => step = 0)
                : () {
                    setState(() {
                      loadingQuestions = true;
                      loadingError = null;
                    });
                    _loadQuestions();
                  },
            color: coral,
            icon: loadingError == null
                ? Icons.play_arrow_rounded
                : Icons.refresh_rounded,
          ),
          gap(14),
          tx(
            loadingQuestions
                ? 'Curio is loading today’s puzzle deck.'
                : loadingError != null
                ? loadingError!
                : 'Puzzle cards come from the case lab.',
            size: 10,
            color: muted,
            align: TextAlign.center,
          ),
        ],
      );
    }
    if (step == questions.length) {
      return ScreenBody(
        children: [
          PageHeader('Discovery complete', back: widget.back),
          gap(36),
          const Center(child: Text('🏅', style: TextStyle(fontSize: 105))),
          gap(24),
          tx(
            'Great effort,\n${widget.model.childName}!',
            size: 31,
            weight: FontWeight.w900,
            align: TextAlign.center,
          ),
          gap(14),
          tx(
            'Every try teaches us something new.',
            color: muted,
            size: 15,
            align: TextAlign.center,
          ),
          gap(28),
          SoftCard(
            color: leaf,
            child: Column(
            children: [
              tx('$score / ${questions.length}', size: 43, weight: FontWeight.w900),
              tx('questions explored together', size: 14),
              gap(14),
              tx(
                score == questions.length
                    ? 'You got them all! Stay curious.'
                    : 'Thinking about answers again is part of learning.',
                size: 13,
                color: const Color(0xFF5F7C65),
                align: TextAlign.center,
              ),
            ],
          ),
          ),
          gap(26),
          PrimaryButton(
            'Play again',
            onTap: () => setState(() {
              step = 0;
              score = 0;
              selected = null;
              checked = false;
            }),
            color: coral,
          ),
          gap(10),
          TextButton(onPressed: widget.back, child: tx('Back home', size: 14)),
        ],
      );
    }
    final q = questions[step];
    return ScreenBody(
      children: [
        PageHeader(
          'Puzzle',
          back: widget.back,
          trailing: Tag('${step + 1} / ${questions.length}', color: butter),
        ),
        gap(24),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (step + 1) / questions.length,
            minHeight: 8,
            backgroundColor: const Color(0xFFEEEAE4),
            color: const Color(0xFFE8BB54),
          ),
        ),
        gap(20),
        Row(
          children: [
            const Mascot(size: 45),
            const SizedBox(width: 10),
            Expanded(child: tx('Let us think together!', size: 14, color: muted)),
          ],
        ),
        gap(18),
        SoftCard(
          color: butter,
          child: Column(
            children: [
              Text(q.emoji, style: const TextStyle(fontSize: 90)),
              gap(15),
              tx(
                q.title,
                size: 24,
                weight: FontWeight.w900,
                align: TextAlign.center,
              ),
              gap(10),
              ListenButton(q.title),
            ],
          ),
        ),
        gap(22),
        for (var i = 0; i < q.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Semantics(
              selected: selected == i,
              child: SoftCard(
                color: checked && i == q.correct
                    ? leaf
                    : selected == i
                    ? apricot
                    : Colors.white,
                onTap: checked ? null : () => setState(() => selected = i),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: tx(q.choices[i], size: 15)),
                    const SizedBox(width: 8),
                    Icon(
                      checked && i == q.correct
                          ? Icons.check_circle_rounded
                          : selected == i
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: checked && i == q.correct
                          ? const Color(0xFF5B9971)
                          : selected == i
                          ? coral
                          : const Color(0xFFC8CAD1),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (checked) ...[
          gap(9),
          SoftCard(
            color: leaf,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tx(
                  selected == q.correct
                      ? '✨  Yes, you got it!'
                      : '🌱  Let us learn together',
                  size: 16,
                ),
                gap(7),
                tx(q.explanation, size: 13, weight: FontWeight.w600),
              ],
            ),
          ),
        ],
        gap(18),
        PrimaryButton(
          checked
              ? (step == questions.length - 1 ? 'See my result' : 'Next question')
              : 'Check my answer',
          onTap: selected == null ? null : next,
          color: coral,
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }
}

class PreschoolProfile extends StatelessWidget {
  final AppModel model;
  final void Function(String) go;
  const PreschoolProfile({super.key, required this.model, required this.go});
  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      Row(
        children: [
          Expanded(child: tx('Me', size: 20)),
          IconButton(
            tooltip: 'Age group',
            onPressed: () => go('age'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      gap(20),
      const Center(child: Text('👧🏻', style: TextStyle(fontSize: 90))),
      gap(12),
      tx(model.childName, size: 22, align: TextAlign.center),
      gap(24),
      pictureGrid([
        PictureButton(
          label: 'Discoveries',
          description: 'See your discoveries',
          emoji: '🌍',
          color: leaf,
          onTap: () => go('explore'),
        ),
        PictureButton(
          label: 'Badges',
          description: 'See your badges',
          emoji: '🏅',
          color: butter,
          onTap: () => go('badges'),
        ),
      ]),
      gap(22),
      SoftCard(
        color: apricot,
        child: Column(
          children: [
            tx('Buddy', size: 12),
            gap(14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final e in ['⭐', '🐱', '🐶', '🐰'])
                  Semantics(
                    label: 'Choose buddy $e',
                    button: true,
                    selected: model.mascot == e,
                    child: InkWell(
                      onTap: () => model.update(() => model.mascot = e),
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        width: 56,
                        height: 66,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: model.mascot == e
                              ? Border.all(color: coral, width: 3)
                              : null,
                        ),
                        child: Center(
                          child: Text(e, style: const TextStyle(fontSize: 36)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      gap(22),
      PictureButton(
        label: 'Parent',
        description: 'Parental controls',
        icon: Icons.lock_rounded,
        color: rose,
        height: 75,
        onTap: () => go('gate'),
      ),
      gap(12),
      TextButton(
        onPressed: () => go('welcome'),
        child: tx('Welcome', size: 12, color: muted),
      ),
    ],
  );
}

class PreschoolBadges extends StatelessWidget {
  final AppModel model;
  final VoidCallback back;
  const PreschoolBadges({super.key, required this.model, required this.back});
  @override
  Widget build(BuildContext context) {
    final entries = preschoolBadgeEntries(model);
    final earnedCount = entries.where((entry) => entry.earned).length;
    return ScreenBody(
      children: [
        PageHeader(
          'Badges',
          back: back,
          trailing: const ListenButton(
            'These are your badges. Every case can unlock a different badge.',
          ),
        ),
        gap(20),
        SoftCard(
          color: butter,
          child: Row(
            children: [
              const Mascot(size: 86),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx('$earnedCount badge${earnedCount == 1 ? '' : 's'} found', size: 22, weight: FontWeight.w900),
                    gap(6),
                    tx('Every case can unlock a different badge.', size: 13, color: muted),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap(22),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SoftCard(
              color: entry.earned ? butter : const Color(0xFFF0EFEC),
              child: Row(
                children: [
                  Text(
                    entry.earned ? entry.emoji : '🔒',
                    style: const TextStyle(fontSize: 42),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(entry.title, size: 17, weight: FontWeight.w900),
                        gap(4),
                        tx(entry.description, size: 12, color: muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
