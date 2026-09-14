import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'model.dart';
import 'ui.dart';

typedef Go = void Function(String);

class HomeScreen extends StatelessWidget {
  final AppModel model;
  final Go go, category;
  final void Function(Discovery) open;
  const HomeScreen({
    super.key,
    required this.model,
    required this.go,
    required this.category,
    required this.open,
  });
  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      Row(
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: const BoxDecoration(
              color: peach,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👧🏻', style: TextStyle(fontSize: 35)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tx(
                  'A LOVELY DAY TO EXPLORE',
                  size: 9,
                  color: muted,
                  weight: FontWeight.w800,
                ),
                tx(
                  'Hello, ${model.childName} ☀️',
                  size: 23,
                  weight: FontWeight.w900,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Parent area',
            onPressed: () => go('gate'),
            icon: const Icon(Icons.tune_rounded, color: muted, size: 23),
          ),
        ],
      ),
      gap(24),
      SoftCard(
        color: sky,
        onTap: () => go('chat'),
        padding: const EdgeInsets.fromLTRB(22, 18, 8, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Tag('✨  YOUR LEARNING BUDDY'),
                  gap(12),
                  tx(
                    'Little questions,\nbig discoveries.',
                    size: 25,
                    weight: FontWeight.w900,
                  ),
                  gap(10),
                  tx(
                    'What are you curious about today?',
                    size: 12,
                    color: const Color(0xFF606F89),
                  ),
                  gap(15),
                  Row(
                    children: [
                      Flexible(
                        child: tx(
                          'Ask Curio',
                          size: 14,
                          color: const Color(0xFF426CC1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 19,
                        color: blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Mascot(size: 125),
          ],
        ),
      ),
      gap(20),
      Row(
        children: [
          Expanded(
            child: SoftCard(
              color: yellow,
              onTap: () => go('quiz'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧩', style: TextStyle(fontSize: 39)),
                  gap(10),
                  tx('Puzzle time', size: 16, weight: FontWeight.w900),
                  gap(4),
                  tx(
                    'Play, think, learn!',
                    size: 11,
                    color: const Color(0xFF7A694A),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SoftCard(
              color: peach,
              onTap: () => go('chat'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 39)),
                  gap(10),
                  tx('Let us chat', size: 16, weight: FontWeight.w900),
                  gap(4),
                  tx(
                    'Every question is a discovery.',
                    size: 11,
                    color: const Color(0xFF8E6463),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      gap(18),
      SectionHeading(
        'Pick up where you left off',
        link: 'My journal →',
        onTap: () => go('explore'),
      ),
      gap(10),
      if (model.discoveries.isEmpty)
        SoftCard(
          color: mint,
          onTap: () => go('chat'),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🔎', style: TextStyle(fontSize: 39)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx(
                      'CASE LAB',
                      size: 9,
                      color: const Color(0xFF63816A),
                    ),
                    gap(4),
                    tx('Start your first investigation.', size: 14),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_circle_right_rounded,
                color: Color(0xFF75A888),
                size: 29,
              ),
            ],
          ),
        )
      else
        SoftCard(
          color: mint,
          onTap: () => open(model.discoveries.first),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                model.discoveries.first.emoji,
                style: const TextStyle(fontSize: 39),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx(
                      model.discoveries.first.topic.toUpperCase(),
                      size: 9,
                      color: const Color(0xFF63816A),
                    ),
                    gap(4),
                    tx(model.discoveries.first.question, size: 14),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_circle_right_rounded,
                color: Color(0xFF75A888),
                size: 29,
              ),
            ],
          ),
        ),
      gap(19),
      const SectionHeading('Your learning world'),
      gap(12),
      Row(
        children: [
          for (final t in topics.take(3))
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: t == topics[2] ? 0 : 9),
                child: SoftCard(
                  color: t.color,
                  onTap: () => category(t.name),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 5,
                  ),
                  child: Column(
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 30)),
                      gap(5),
                      tx(t.name, size: 12),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      gap(18),
      SoftCard(
        color: lilac,
        onTap: () => go('badges'),
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Text('🏅', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tx('Your curiosity shines!', size: 13),
                  tx('Explore your badge collection', size: 11, color: muted),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9B83C6)),
          ],
        ),
      ),
    ],
  );
}

class WelcomeScreen extends StatelessWidget {
  final AppModel model;
  final Go go;
  const WelcomeScreen({super.key, required this.model, required this.go});
  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      gap(24),
      tx('curio', size: 32, weight: FontWeight.w900, align: TextAlign.center),
      gap(5),
      tx(
        'LITTLE QUESTIONS, BIG DISCOVERIES',
        size: 10,
        color: muted,
        align: TextAlign.center,
      ),
      gap(30),
      const SoftCard(
        color: sky,
        child: Center(child: Mascot(size: 235)),
      ),
      gap(30),
      tx(
        'A world of wonder\nstarts with curiosity.',
        size: 34,
        weight: FontWeight.w900,
        align: TextAlign.center,
      ),
      gap(12),
      tx(
        'A friendly learning buddy\nfor your curious little explorer.',
        color: muted,
        size: 15,
        align: TextAlign.center,
      ),
      gap(30),
      PrimaryButton(
        'Let us get started',
        onTap: () => go('signup'),
        icon: Icons.arrow_forward_rounded,
      ),
      gap(8),
      TextButton(
        onPressed: () => go('login'),
        child: tx('I have an account · Log in', size: 14),
      ),
      gap(12),
      tx(
        'Account creation and login are for parents.',
        size: 11,
        color: muted,
        align: TextAlign.center,
      ),
    ],
  );
}

class AuthScreen extends StatefulWidget {
  final AppModel model;
  final bool register;
  final Go go;
  final VoidCallback back;
  const AuthScreen({
    super.key,
    required this.model,
    required this.register,
    required this.go,
    required this.back,
  });
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final parentName = TextEditingController();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  bool consent = false;
  bool submitting = false;
  @override
  void dispose() {
    parentName.dispose();
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  String? requiredText(String? s) =>
      s == null || s.trim().isEmpty ? 'Please fill in this field.' : null;
  Future<void> submit() async {
    if (submitting) return;
    if (!form.currentState!.validate()) return;
    if (widget.register && !consent) {
      notice(context, 'Please confirm you are a parent or guardian.');
      return;
    }
    setState(() => submitting = true);
    try {
      if (widget.register) {
        await widget.model.registerParentAccount(
          newParentName: parentName.text.trim(),
          newChildName: name.text.trim(),
          newEmail: email.text.trim(),
          newPhone: phone.text.trim(),
          newParentPassword: password.text,
        );
      } else {
        widget.model.update(() {
          widget.model.email = email.text.trim();
        });
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Account service is unavailable. Continuing in demo mode.');
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
    widget.go('age');
  }

  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      PageHeader(
        'Parent area',
        back: widget.back,
        trailing: const Icon(Icons.shield_outlined, color: blue),
      ),
      gap(20),
      const Center(child: Mascot(size: 100)),
      gap(12),
      tx(
        widget.register ? 'Let the adventure\nbegin.' : 'Welcome back.',
        size: 29,
        weight: FontWeight.w900,
      ),
      gap(9),
      tx(
        widget.register
            ? 'A world of wonder for your little explorer.'
            : 'New questions and discoveries are waiting.',
        size: 14,
        color: muted,
      ),
      gap(25),
      Form(
        key: form,
        child: Column(
          children: [
            if (widget.register)
              Field('Your name', parentName, validator: requiredText),
            if (widget.register)
              Field('Your child’s name', name, validator: requiredText),
            Field(
              'Your email address',
              email,
              keyboard: TextInputType.emailAddress,
              validator: (s) =>
                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s ?? '')
                  ? null
                  : 'Enter a valid email address.',
            ),
            if (widget.register)
              Field(
                'Parent phone number',
                phone,
                keyboard: TextInputType.phone,
                validator: (s) =>
                    RegExp(r'^\+?[0-9\s]{10,16}$').hasMatch(s ?? '')
                    ? null
                    : 'Enter a valid phone number.',
              ),
            Field(
              'Password',
              password,
              secret: true,
              validator: (s) =>
                  (s ?? '').length >= 8 ? null : 'Use at least 8 characters.',
            ),
          ],
        ),
      ),
      if (widget.register)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: consent,
          activeColor: coral,
          onChanged: (v) => setState(() => consent = v!),
          title: tx('I confirm I am a parent or legal guardian.', size: 12),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      if (!widget.register)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Forgot password'),
                content: const Text(
                  'This UI prototype does not send email. In the production app, a reset link will be sent to your verified email address.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
            child: tx('Forgot password', size: 12, color: blue),
          ),
        ),
      gap(12),
      PrimaryButton(
        submitting
            ? 'Connecting...'
            : widget.register
            ? 'Create account'
            : 'Log in',
        onTap: submitting ? null : submit,
        icon: submitting ? Icons.more_horiz_rounded : Icons.arrow_forward_rounded,
      ),
      gap(12),
      TextButton(
        onPressed: () => widget.go(widget.register ? 'login' : 'signup'),
        child: tx(
          widget.register
              ? 'Already have an account? Log in'
              : 'New here? Create an account',
          size: 13,
        ),
      ),
      gap(15),
      const SoftCard(
        color: mint,
        padding: EdgeInsets.all(14),
        child: Text(
          'Parent contact is used for safety routing. Email, SMS and push require verified channels in production.',
          style: TextStyle(fontSize: 11, color: Color(0xFF5D7863)),
        ),
      ),
    ],
  );
}

class AgeScreen extends StatelessWidget {
  final AppModel model;
  final Go go;
  final VoidCallback back;
  const AgeScreen({
    super.key,
    required this.model,
    required this.go,
    required this.back,
  });
  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      PageHeader('Let us meet you', back: back),
      gap(38),
      tx(
        'How old are you?',
        size: 30,
        weight: FontWeight.w900,
        align: TextAlign.center,
      ),
      gap(10),
      tx(
        'Let us make your world of discovery just right.',
        size: 14,
        color: muted,
        align: TextAlign.center,
      ),
      gap(40),
      Row(
        children: [
          for (final older in [false, true])
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: older ? 0 : 14),
                child: Semantics(
                  selected: model.older == older,
                  child: SoftCard(
                    color: older ? sky : peach,
                    onTap: () => model.update(() => model.older = older),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 25,
                    ),
                    child: Column(
                      children: [
                        Text(
                          older ? '🧒🏻' : '👧🏻',
                          style: const TextStyle(fontSize: 75),
                        ),
                        gap(14),
                        tx(
                          older ? '7 – 9' : '3 – 6',
                          size: 30,
                          weight: FontWeight.w900,
                        ),
                        tx('years', size: 14, color: muted),
                        gap(16),
                        Icon(
                          model.older == older
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: model.older == older ? model.accent : muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      gap(28),
      SoftCard(
        color: Colors.white,
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFE8B44C)),
            const SizedBox(width: 12),
            Expanded(
              child: tx(
                model.older
                    ? 'More details, new questions and thoughtful puzzles.'
                    : 'Big pictures, simple words and playful discoveries.',
                size: 13,
                color: muted,
              ),
            ),
          ],
        ),
      ),
      gap(45),
      PrimaryButton(
        'Start exploring',
        color: model.accent,
        onTap: () => go('home'),
        icon: Icons.arrow_forward_rounded,
      ),
    ],
  );
}

class ExploreScreen extends StatefulWidget {
  final AppModel model;
  final Go category;
  const ExploreScreen({super.key, required this.model, required this.category});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final visible = topics
        .where((t) => t.name.toLowerCase().contains(search.toLowerCase()))
        .toList();
    return ScreenBody(
      children: [
        Row(
          children: [
            Expanded(child: tx('Explore', size: 29, weight: FontWeight.w900)),
            const Tag('🌱  MY JOURNAL', color: mint),
          ],
        ),
        gap(8),
        tx('Every question starts a new page.', size: 15, color: muted),
        gap(21),
        TextField(
          onChanged: (s) => setState(() => search = s),
          decoration: InputDecoration(
            hintText: 'Find a category…',
            hintStyle: const TextStyle(fontSize: 14, color: muted),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        gap(21),
        SoftCard(
          color: sky,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx(
                      '${widget.model.discoveries.length} questions, a world to explore',
                      size: 15,
                    ),
                    gap(3),
                    tx('Your curiosity grows here.', size: 12, color: muted),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap(23),
        const SectionHeading('Your discoveries'),
        gap(12),
        if (visible.isEmpty) tx('No matching category found.', color: muted),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 166,
          ),
          itemBuilder: (c, i) {
            final t = visible[i];
            final n = widget.model.history(t.name).length;
            return SoftCard(
              color: t.color,
              onTap: () => widget.category(t.name),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 42)),
                  const Spacer(),
                  tx(t.name, size: 17, weight: FontWeight.w900),
                  gap(3),
                  Row(
                    children: [
                      Expanded(
                        child: tx(
                          n == 0 ? 'Ask your first question' : '$n discoveries',
                          size: 11,
                          color: muted,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: muted,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        gap(20),
        tx(
          'Your questions are saved by topic.',
          size: 11,
          color: muted,
          align: TextAlign.center,
        ),
      ],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final AppModel model;
  final String topic;
  final VoidCallback back;
  final void Function(Discovery) open;
  final Go go;
  const HistoryScreen({
    super.key,
    required this.model,
    required this.topic,
    required this.back,
    required this.open,
    required this.go,
  });
  @override
  Widget build(BuildContext context) {
    final t = topics.firstWhere((t) => t.name == topic);
    final list = model.history(topic);
    return ScreenBody(
      children: [
        PageHeader('My learning journal', back: back),
        gap(22),
        SoftCard(
          color: t.color,
          child: Row(
            children: [
              Text(t.emoji, style: const TextStyle(fontSize: 55)),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx(topic, size: 26, weight: FontWeight.w900),
                    gap(3),
                    tx(
                      '${list.length} discoveries · Your curiosity journey',
                      size: 11,
                      color: muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap(27),
        tx('Your questions', size: 19, weight: FontWeight.w900),
        gap(6),
        tx(
          'Tap a question to revisit your conversation.',
          size: 12,
          color: muted,
        ),
        gap(20),
        if (list.isEmpty) ...[
          gap(20),
          const Center(child: Mascot(size: 130)),
          tx(
            'This page is waiting for you!',
            size: 21,
            align: TextAlign.center,
          ),
          gap(8),
          tx(
            'Explore this topic by asking your first question.',
            size: 13,
            color: muted,
            align: TextAlign.center,
          ),
          gap(24),
        ] else
          for (final d in list) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 7),
              child: tx(d.date, size: 11, color: muted),
            ),
            SoftCard(
              onTap: () => open(d),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(d.question, size: 15),
                        gap(6),
                        tx('Your chat with Curio', size: 11, color: muted),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: muted),
                ],
              ),
            ),
            gap(16),
          ],
        gap(12),
        PrimaryButton(
          'Ask a new question',
          color: model.accent,
          onTap: () => go('chat'),
          icon: Icons.add_rounded,
        ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final AppModel model;
  final VoidCallback back;
  const ChatScreen({super.key, required this.model, required this.back});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final picker = ImagePicker();
  final messages = <Discovery>[];
  String activeMission = '';
  int activeCaseIndex = 0;
  bool loading = false;
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> ask(String q) async {
    final visibleQuestion = q.trim();
    if (visibleQuestion.isEmpty || loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      activeMission = visibleQuestion;
      loading = true;
    });
    input.clear();
    try {
      final backendQuestion = _questionWithConversationContext(visibleQuestion);
      final d = await widget.model.learning.ask(
        backendQuestion,
        widget.model.older,
        parentContact: widget.model.parentContact,
      );
      final display = Discovery(
        visibleQuestion,
        d.answer,
        d.topic,
        d.emoji,
        d.date,
        investigation: d.investigation,
        photoBytes: d.photoBytes,
      );
      if (!mounted) return;
      widget.model.update(() => widget.model.discoveries.insert(0, display));
      setState(() {
        messages.add(display);
        activeCaseIndex = messages.length - 1;
        activeMission = '';
        loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          activeMission = '';
          loading = false;
        });
        notice(context, 'No answer yet. Please try again.');
      }
    }
  }

  String _questionWithConversationContext(String question) {
    for (final message in messages.reversed) {
      final investigation = message.investigation;
      if (investigation == null) continue;
      final parts = <String>[];
      if (investigation.hypotheses.isNotEmpty) {
        parts.add('Previous visual subject: ${_caseSubject(investigation.hypotheses.first.label)}.');
      }
      if (investigation.curiosityQuestion.trim().isNotEmpty) {
        parts.add('Curio asked: ${investigation.curiosityQuestion}.');
      }
      if (parts.isNotEmpty) {
        parts.add('Child says: $question');
        return parts.join(' ');
      }
    }
    return question;
  }

  String _caseSubject(String label) {
    var subject = label.trim();
    const suffixes = [
      ' text follow-up',
      ' learning question',
      ' color clue',
      ' body clue',
      ' diet question',
      ' habitat question',
      ' field note',
    ];
    var lowered = subject.toLowerCase();
    for (final suffix in suffixes) {
      while (lowered.endsWith(suffix)) {
        subject = subject.substring(0, subject.length - suffix.length).trim();
        lowered = subject.toLowerCase();
      }
    }
    return subject.isEmpty ? label : subject;
  }

  Future<void> askPhoto() async {
    if (loading) return;
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
    FocusScope.of(context).unfocus();
    try {
      final prompt = input.text.trim().isEmpty
          ? 'What is in this photo?'
          : input.text.trim();
      setState(() {
        activeMission = prompt;
        loading = true;
      });
      final bytes = await image.readAsBytes();
      final d = (await widget.model.learning.askWithImage(
        prompt,
        bytes,
        filename: image.name,
        contentType: image.mimeType ?? 'image/jpeg',
        older: widget.model.older,
        parentContact: widget.model.parentContact,
      )).withPhoto(bytes);
      if (!mounted) return;
      input.clear();
      widget.model.update(() => widget.model.discoveries.insert(0, d));
      setState(() {
        messages.add(d);
        activeCaseIndex = messages.length - 1;
        activeMission = '';
        loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          activeMission = '';
          loading = false;
        });
        notice(context, 'The photo could not be sent. Please try another image.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: PageHeader(
          'Investigator Portal',
          back: widget.back,
          trailing: const Tag('CASE LAB', color: sky),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
            if (messages.isEmpty && !loading) ...[
              const PortalWelcomeCard(),
              gap(22),
              tx(
                'OPEN A CASE',
                size: 10,
                color: muted,
                align: TextAlign.center,
              ),
              gap(12),
              for (final q in [
                '🏛️  What is this old fountain?',
                '🦋  How do butterflies fly?',
                '🍽️  Could this food have allergens?',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftCard(
                    onTap: () => ask(q.substring(q.indexOf('  ') + 2)),
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Expanded(child: tx(q, size: 13)),
                        const Icon(
                          Icons.north_east_rounded,
                          size: 16,
                          color: blue,
                        ),
                      ],
                    ),
                  ),
                ),
            ] else if (loading) ...[
              MissionBriefCard(
                question: activeMission.isEmpty ? 'Checking your clue' : activeMission,
                caseNumber: messages.length + 1,
              ),
              gap(12),
              const PortalLoadingCard(),
            ] else if (messages.isNotEmpty) ...[
              CaseArchiveControls(
                current: activeCaseIndex,
                total: messages.length,
                onPrevious: activeCaseIndex > 0
                    ? () => setState(() => activeCaseIndex--)
                    : null,
                onNext: activeCaseIndex < messages.length - 1
                    ? () => setState(() => activeCaseIndex++)
                    : null,
              ),
              gap(12),
              CasePortalDeck(
                d: messages[activeCaseIndex],
                caseNumber: activeCaseIndex + 1,
              ),
              gap(18),
            ],
            ],
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    maxLength: 300,
                    onSubmitted: ask,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Type your question…',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                IconButton.filled(
                  onPressed: loading ? null : () => ask(input.text),
                  tooltip: 'Send question',
                  style: IconButton.styleFrom(
                    backgroundColor: widget.model.accent,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
            gap(6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => notice(
                    context,
                    widget.model.voice
                        ? 'Voice questions need a microphone service connection.'
                        : 'Voice questions are disabled in parent settings.',
                  ),
                  icon: const Icon(Icons.mic_none_rounded, size: 20),
                  label: const Text('Voice', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: loading ? null : askPhoto,
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('Photo', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            tx('Photos start a safe evidence quest', size: 9, color: muted),
          ],
        ),
      ),
    ],
  );
}

class AnswerCard extends StatelessWidget {
  final Discovery d;
  const AnswerCard({super.key, required this.d});
  @override
  Widget build(BuildContext context) {
    final investigation = d.investigation;
    final statusLabel = investigation == null
        ? ''
        : investigation.status == 'concluded'
        ? 'CASE SOLVED'
        : 'CASE ${investigation.confidence.toUpperCase()}';
    return SoftCard(
      color: sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Mascot(size: 40),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx('Curio case board', size: 14, color: const Color(0xFF4E72B5)),
                    gap(2),
                    tx('Evidence checked', size: 10, color: muted, weight: FontWeight.w900),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (investigation != null)
                Tag(statusLabel),
              if (investigation != null) ...[
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CaseBoardSheet(discovery: d),
                  ),
                  tooltip: 'Open case board',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(.72),
                    foregroundColor: blue,
                    minimumSize: const Size(34, 34),
                  ),
                  icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
                ),
              ],
            ],
          ),
          if (investigation?.safetyEvents.isNotEmpty == true) ...[
            gap(13),
            SafetyAlertCard(investigation!.safetyEvents.first),
            gap(12),
            SafetyProtocolCard(investigation.safetyEvents.first),
          ],
          gap(13),
          if (d.photoBytes == null)
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.62),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 68))),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.memory(
                  d.photoBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          gap(14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.62),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tx('Finding', size: 11, color: const Color(0xFF4E72B5), weight: FontWeight.w900),
                gap(6),
                tx(d.answer, size: 16, weight: FontWeight.w700),
              ],
            ),
          ),
          if ((investigation?.curiosityQuestion ?? '').isNotEmpty) ...[
            gap(14),
            CuriosityQuestionCard(investigation!.curiosityQuestion),
          ],
          if (investigation != null && investigation.safetyEvents.isEmpty) ...[
            gap(18),
            if (investigation.status == 'concluded')
              ExplorerTrailCard(investigation)
            else
              InvestigationPanel(investigation),
          ],
          gap(15),
          Row(
            children: [
              const Icon(
                Icons.bookmark_added_outlined,
                size: 16,
                color: Color(0xFF658279),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: tx(
                  'Saved to your ${d.topic} journal',
                  size: 11,
                  color: const Color(0xFF658279),
                ),
              ),
            ],
          ),
          gap(5),
        ],
      ),
    );
  }
}

class CaseBoardSheet extends StatelessWidget {
  final Discovery discovery;
  const CaseBoardSheet({super.key, required this.discovery});

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
      initialChildSize: .94,
      maxChildSize: .98,
      minChildSize: .72,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx('CASE BOARD', size: 10, color: muted, weight: FontWeight.w900),
                        gap(2),
                        tx(discovery.question, size: 19, weight: FontWeight.w900),
                      ],
                    ),
                  ),
                  const Tag('+40 XP'),
                ],
              ),
              gap(16),
              if (discovery.photoBytes == null)
                Center(
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      color: sky,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(child: Text(discovery.emoji, style: const TextStyle(fontSize: 82))),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.memory(discovery.photoBytes!, fit: BoxFit.cover),
                  ),
                ),
              gap(16),
              CaseBoardSection(
                icon: Icons.search_rounded,
                title: 'Clues',
                body: clues.isEmpty ? 'Curio used the question as the first clue.' : clues.join('\n'),
                color: sky,
              ),
              gap(10),
              CaseBoardSection(
                icon: Icons.psychology_alt_outlined,
                title: 'My Theory',
                body: theory,
                color: lilac,
              ),
              gap(10),
              CaseBoardSection(
                icon: Icons.auto_awesome_rounded,
                title: 'Curio Finding',
                body: discovery.answer,
                color: mint,
              ),
              if ((investigation?.curiosityQuestion ?? '').isNotEmpty) ...[
                gap(10),
                CaseBoardSection(
                  icon: Icons.flag_outlined,
                  title: 'Next Mission',
                  body: investigation!.curiosityQuestion,
                  color: yellow,
                ),
              ],
              gap(16),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .86, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD7A8)),
                  ),
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
                            tx(_caseBoardBadge(investigation), size: 16, weight: FontWeight.w900),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _caseBoardBadge(InvestigationView? investigation) {
    if (investigation == null) return 'Curiosity Investigator';
    return _badgeTitleForInvestigation(investigation);
  }
}

class CaseBoardSection extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final Color color;
  const CaseBoardSection({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: blue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tx(title, size: 11, color: muted, weight: FontWeight.w900),
              gap(5),
              tx(body, size: 14, weight: FontWeight.w800),
            ],
          ),
        ),
      ],
    ),
  );
}

class PortalWelcomeCard extends StatelessWidget {
  const PortalWelcomeCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
    decoration: BoxDecoration(
      color: sky,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFCBDCFA)),
    ),
    child: Column(
      children: [
        const Mascot(size: 155),
        gap(8),
        tx(
          'Open a tiny mystery',
          size: 28,
          weight: FontWeight.w900,
          align: TextAlign.center,
        ),
        gap(8),
        tx(
          'Snap a clue, make a guess, unlock the next mission.',
          color: muted,
          size: 14,
          align: TextAlign.center,
        ),
        gap(16),
        Row(
          children: const [
            Expanded(child: _PortalStat(Icons.camera_alt_outlined, 'Clue')),
            SizedBox(width: 8),
            Expanded(child: _PortalStat(Icons.psychology_alt_outlined, 'Theory')),
            SizedBox(width: 8),
            Expanded(child: _PortalStat(Icons.flag_outlined, 'Mission')),
          ],
        ),
      ],
    ),
  );
}

class PortalLoadingCard extends StatelessWidget {
  const PortalLoadingCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: sky,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: tx('Curio is checking the clue board...', size: 13, color: muted),
        ),
      ],
    ),
  );
}

class _PortalStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PortalStat(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.72),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, size: 19, color: blue),
        gap(4),
        tx(label, size: 10, weight: FontWeight.w900),
      ],
    ),
  );
}

class CasePortalDeck extends StatelessWidget {
  final Discovery d;
  final int caseNumber;
  const CasePortalDeck({super.key, required this.d, required this.caseNumber});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ActiveCaseHeader(question: d.question, caseNumber: caseNumber),
      gap(10),
      AnswerCard(d: d),
    ],
  );
}

class ActiveCaseHeader extends StatelessWidget {
  final String question;
  final int caseNumber;
  const ActiveCaseHeader({
    super.key,
    required this.question,
    required this.caseNumber,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: lilac,
          borderRadius: BorderRadius.circular(21),
        ),
        child: const Icon(Icons.folder_special_outlined, color: Color(0xFF7B65B1), size: 22),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tx('Active case ${caseNumber.toString().padLeft(2, '0')}', size: 10, color: muted, weight: FontWeight.w900),
            gap(3),
            tx(question, size: 14, weight: FontWeight.w900),
          ],
        ),
      ),
    ],
  );
}

class CaseArchiveControls extends StatelessWidget {
  final int current, total;
  final VoidCallback? onPrevious, onNext;
  const CaseArchiveControls({
    super.key,
    required this.current,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5EDF9)),
    ),
    child: Row(
      children: [
        IconButton.filledTonal(
          onPressed: onPrevious,
          tooltip: 'Previous case',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF0F4FF),
            foregroundColor: ink,
            disabledForegroundColor: muted.withOpacity(.35),
            minimumSize: const Size(38, 38),
          ),
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
        ),
        Expanded(
          child: Column(
            children: [
              tx('Case archive', size: 10, color: muted, weight: FontWeight.w900),
              gap(2),
              tx(
                '${current + 1} / $total',
                size: 15,
                weight: FontWeight.w900,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onNext,
          tooltip: 'Next case',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF0F4FF),
            foregroundColor: ink,
            disabledForegroundColor: muted.withOpacity(.35),
            minimumSize: const Size(38, 38),
          ),
          icon: const Icon(Icons.chevron_right_rounded, size: 22),
        ),
      ],
    ),
  );
}

class MissionBriefCard extends StatelessWidget {
  final String question;
  final int caseNumber;
  const MissionBriefCard({
    super.key,
    required this.question,
    required this.caseNumber,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: lilac,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDAD1F3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.82),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.assignment_outlined, color: Color(0xFF7B65B1), size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tx('Mission ${caseNumber.toString().padLeft(2, '0')}', size: 10, color: muted, weight: FontWeight.w900),
              gap(4),
              tx(question, size: 14, weight: FontWeight.w900),
            ],
          ),
        ),
      ],
    ),
  );
}

class CuriosityQuestionCard extends StatelessWidget {
  final String question;
  const CuriosityQuestionCard(this.question, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFFFD7A8)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFB06F1F), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tx('Curio wonders', size: 11, color: const Color(0xFFB06F1F), weight: FontWeight.w900),
              gap(5),
              tx(question, size: 15, weight: FontWeight.w900),
            ],
          ),
        ),
      ],
    ),
  );
}

class ExplorerTrailCard extends StatelessWidget {
  final InvestigationView investigation;
  const ExplorerTrailCard(this.investigation, {super.key});

  @override
  Widget build(BuildContext context) {
    final mainClue = investigation.evidence.isEmpty
        ? 'Curio used your question as the clue.'
        : investigation.evidence.first.observation;
    final badge = _badgeName(investigation);
    final level = _badgeLevel(investigation);
    final progress = _badgeProgress(investigation);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD7A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: yellow,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFB06F1F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx('Badge upgraded', size: 13, weight: FontWeight.w900),
                    gap(2),
                    tx('$badge • $level', size: 11, color: const Color(0xFFB06F1F), weight: FontWeight.w900),
                  ],
                ),
              ),
              const Tag('+40 XP'),
            ],
          ),
          gap(14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFFFEAC1),
              color: const Color(0xFFFFB84A),
            ),
          ),
          gap(10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _BadgeChip(Icons.search_rounded, 'Clue logged'),
              _BadgeChip(Icons.psychology_alt_outlined, 'Theory tested'),
              _BadgeChip(_domainIcon(investigation.domain), badge),
            ],
          ),
          gap(14),
          Row(
            children: const [
              _TrailStep(done: true, label: 'Clue'),
              _TrailLine(),
              _TrailStep(done: true, label: 'Guess'),
              _TrailLine(),
              _TrailStep(done: true, label: 'Aha!'),
              _TrailLine(),
              _TrailStep(done: false, label: 'Next'),
            ],
          ),
          gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: tx('Field note: $mainClue', size: 11, color: muted),
          ),
        ],
      ),
    );
  }

  String _badgeName(InvestigationView investigation) {
    return _badgeTitleForInvestigation(investigation);
  }

  String _badgeLevel(InvestigationView investigation) {
    if (investigation.confidence == 'high') return 'Level 3';
    if (investigation.confidence == 'medium') return 'Level 2';
    return 'Level 1';
  }

  double _badgeProgress(InvestigationView investigation) {
    if (investigation.confidence == 'high') return .92;
    if (investigation.confidence == 'medium') return .68;
    return .42;
  }

  IconData _domainIcon(String domain) {
    if (domain == 'heritage') return Icons.account_balance_outlined;
    if (domain == 'safe_dining') return Icons.shield_outlined;
    if (domain == 'general') return Icons.auto_awesome_outlined;
    return Icons.eco_outlined;
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BadgeChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.78),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFFE0A8)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFFB06F1F)),
        const SizedBox(width: 5),
        tx(label, size: 10, weight: FontWeight.w900, color: ink),
      ],
    ),
  );
}

class _TrailStep extends StatelessWidget {
  final bool done;
  final String label;
  const _TrailStep({required this.done, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: done ? const Color(0xFFFFC857) : const Color(0xFFF0F3FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          done ? Icons.check_rounded : Icons.flag_outlined,
          color: done ? const Color(0xFF74500A) : muted,
          size: 17,
        ),
      ),
      gap(5),
      tx(label, size: 9, weight: FontWeight.w900, color: done ? ink : muted),
    ],
  );
}

class _TrailLine extends StatelessWidget {
  const _TrailLine();

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(height: 2, color: const Color(0xFFFFE2A8)),
    ),
  );
}

class SafetyAlertCard extends StatelessWidget {
  final SafetyEventView event;
  const SafetyAlertCard(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    final emergency = event.severity == 'emergency';
    final color = emergency ? const Color(0xFFFFDFDE) : const Color(0xFFFFE9C8);
    final iconColor = emergency ? const Color(0xFFC94444) : const Color(0xFFB06F1F);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconColor.withOpacity(.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            emergency ? Icons.emergency_share_outlined : Icons.warning_amber_rounded,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tx(event.title, size: 13, weight: FontWeight.w900, color: iconColor),
                gap(5),
                tx(event.childMessage, size: 12, color: ink),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyProtocolCard extends StatelessWidget {
  final SafetyEventView event;
  const SafetyProtocolCard(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    final emergency = event.severity == 'emergency';
    final steps = emergency
        ? const [
            'Move back from the object or place.',
            'Call a grown-up right now.',
            'Do not touch, taste, or pick it up.',
            'Wait in a safe spot until help arrives.',
          ]
        : const [
            'Pause and keep a safe distance.',
            'Ask a grown-up to check this clue.',
            'Use words or a safer photo instead.',
          ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: emergency ? peach : yellow,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  emergency ? Icons.shield_outlined : Icons.task_alt_rounded,
                  color: emergency ? coral : const Color(0xFFB06F1F),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(child: tx('Safety protocol', size: 13, weight: FontWeight.w900)),
              if (event.notifyParent) const Tag('Parent pinged'),
            ],
          ),
          gap(12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: tx('${i + 1}', size: 11, weight: FontWeight.w900, color: blue),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: tx(steps[i], size: 12, weight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class InvestigationPanel extends StatelessWidget {
  final InvestigationView investigation;
  const InvestigationPanel(this.investigation, {super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PanelSection(
        icon: Icons.psychology_alt_outlined,
        title: 'Hypotheses',
        child: Column(
          children: [
            for (final h in investigation.hypotheses)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Dot(h.confidence),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tx(h.label, size: 13, weight: FontWeight.w900),
                          gap(2),
                          tx(h.rationale, size: 11, color: muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      if (investigation.quest.modality != 'curiosity_question') ...[
        gap(12),
        _PanelSection(
          icon: Icons.travel_explore_rounded,
          title: 'Next evidence quest',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tx(investigation.quest.instruction, size: 13),
              gap(8),
              tx(
                investigation.quest.safetyRule,
                size: 11,
                color: const Color(0xFF8A5E36),
              ),
            ],
          ),
        ),
      ],
      gap(12),
      _PanelSection(
        icon: Icons.verified_outlined,
        title: 'Evidence graph',
        child: Column(
          children: [
            for (final e in investigation.evidence)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx(e.type.toUpperCase(), size: 9, color: muted),
                    const SizedBox(width: 10),
                    Expanded(child: tx(e.observation, size: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
      if (investigation.parentSummary != investigation.kidSummary) ...[
        gap(12),
        tx('Parent note', size: 12, weight: FontWeight.w900),
        tx(investigation.parentSummary, size: 12, color: muted),
      ],
    ],
  );
}

class _PanelSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _PanelSection({
    required this.icon,
    required this.title,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.72),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5EDF9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: blue),
            const SizedBox(width: 8),
            tx(title, size: 12, weight: FontWeight.w900),
          ],
        ),
        gap(10),
        child,
      ],
    ),
  );
}

class _Dot extends StatelessWidget {
  final String confidence;
  const _Dot(this.confidence);
  @override
  Widget build(BuildContext context) {
    final color = confidence == 'high'
        ? const Color(0xFF6D9A71)
        : confidence == 'medium'
        ? const Color(0xFFE0A842)
        : const Color(0xFFB9C2D4);
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Icon(Icons.circle, size: 10, color: color),
    );
  }
}

class AnswerScreen extends StatelessWidget {
  final Discovery discovery;
  final VoidCallback back;
  final Go go;
  const AnswerScreen({
    super.key,
    required this.discovery,
    required this.back,
    required this.go,
  });
  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      PageHeader('Investigator Portal', back: back, trailing: const Tag('CASE LAB', color: sky)),
      gap(20),
      CasePortalDeck(d: discovery, caseNumber: 1),
      gap(22),
      tx('Ready to explore something else?', size: 16, align: TextAlign.center),
      gap(14),
      PrimaryButton(
        'Ask another question',
        onTap: () => go('chat'),
        color: blue,
        icon: Icons.auto_awesome,
      ),
    ],
  );
}

class QuizScreen extends StatefulWidget {
  final AppModel model;
  final VoidCallback back;
  const QuizScreen({super.key, required this.model, required this.back});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int step = -1, score = 0;
  int? selected;
  bool checked = false;
  bool loadingQuestions = true;
  String? loadingError;
  List<QuizQuestion> questions = const [];

  @override
  void initState() {
    super.initState();
    questions = widget.model.learning.quiz(widget.model.older);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final loaded = await widget.model.learning.dynamicQuiz(widget.model.older);
      if (!mounted) return;
      setState(() {
        questions = loaded.isEmpty ? questions : loaded;
        loadingQuestions = false;
        loadingError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadingQuestions = false;
        loadingError = 'Curio could not build live mission cards yet.';
      });
    }
  }

  void next() {
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
    if (step == -1) {
      return ScreenBody(
        children: [
          PageHeader('Puzzle time', back: widget.back),
          gap(28),
          const Center(child: Tag('🧩  YOUR MINI QUIZ', color: yellow)),
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
            color: yellow,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 5,
              children: [
                Tag('3 questions', color: yellow),
                Tag('~3 minutes', color: yellow),
                Tag('No time pressure', color: yellow),
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
            color: widget.model.accent,
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
            color: mint,
            child: Column(
              children: [
                tx(
                  '$score / ${questions.length}',
                  size: 43,
                  weight: FontWeight.w900,
                ),
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
            color: widget.model.accent,
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
          trailing: Tag('${step + 1} / ${questions.length}', color: yellow),
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
        gap(25),
        Row(
          children: [
            const Mascot(size: 45),
            const SizedBox(width: 10),
            Expanded(
              child: tx('Let us think together!', size: 14, color: muted),
            ),
          ],
        ),
        gap(18),
        SoftCard(
          color: yellow,
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
              gap(7),
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
                    ? mint
                    : selected == i
                    ? sky
                    : Colors.white,
                onTap: checked ? null : () => setState(() => selected = i),
                padding: const EdgeInsets.all(18),
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
                          ? blue
                          : const Color(0xFFC8CAD1),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (checked) ...[
          gap(9),
          SoftCard(
            color: mint,
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
              ? (step == questions.length - 1
                    ? 'See my result'
                    : 'Next question')
              : 'Check my answer',
          onTap: selected == null ? null : next,
          color: widget.model.accent,
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final AppModel model;
  final Go go;
  const ProfileScreen({super.key, required this.model, required this.go});
  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      Row(
        children: [
          Expanded(child: tx('My world', size: 25, weight: FontWeight.w900)),
          IconButton(
            tooltip: 'Change age group',
            onPressed: () => go('age'),
            icon: const Icon(Icons.tune_rounded, color: muted),
          ),
        ],
      ),
      gap(19),
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(color: peach, shape: BoxShape.circle),
          child: const Center(
            child: Text('👧🏻', style: TextStyle(fontSize: 69)),
          ),
        ),
      ),
      gap(12),
      tx(
        model.childName,
        size: 27,
        weight: FontWeight.w900,
        align: TextAlign.center,
      ),
      gap(4),
      tx(
        '${model.older ? '7–9' : '3–6'} years · Little explorer',
        size: 13,
        color: muted,
        align: TextAlign.center,
      ),
      gap(26),
      Row(
        children: [
          Expanded(
            child: SoftCard(
              color: yellow,
              onTap: () => go('explore'),
              child: Column(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 34)),
                  gap(8),
                  tx(
                    '${model.discoveries.length}',
                    size: 28,
                    weight: FontWeight.w900,
                  ),
                  tx('Discovery', size: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: SoftCard(
              color: lilac,
              onTap: () => go('badges'),
              child: Column(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 34)),
                  gap(8),
                  tx(
                    '${_earnedBadgeCount(model)}',
                    size: 28,
                    weight: FontWeight.w900,
                  ),
                  tx('Badge', size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
      gap(21),
      SoftCard(
        color: sky,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tx('Choose your buddy', size: 17),
            gap(5),
            tx('Who will explore with you?', size: 12, color: muted),
            gap(15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final e in ['⭐', '🐱', '🐶', '🐰'])
                  Semantics(
                    selected: model.mascot == e,
                    child: InkWell(
                      onTap: () => model.update(() => model.mascot = e),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 54,
                        height: 62,
                        decoration: BoxDecoration(
                          color: model.mascot == e
                              ? Colors.white
                              : Colors.white.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(18),
                          border: model.mascot == e
                              ? Border.all(color: blue, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(e, style: const TextStyle(fontSize: 34)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            gap(10),
            tx('Your buddy: ${model.mascot}', size: 11, color: muted),
          ],
        ),
      ),
      gap(18),
      SoftCard(
        color: mint,
        onTap: () => go('gate'),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF61856B),
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tx('Parental controls', size: 16),
                  tx(
                    'Learning, time and account settings',
                    size: 11,
                    color: muted,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
      gap(12),
      TextButton(
        onPressed: () => go('welcome'),
        child: tx('Back to welcome', size: 12, color: muted),
      ),
    ],
  );
}

class BadgesScreen extends StatelessWidget {
  final AppModel model;
  final VoidCallback back;
  const BadgesScreen({super.key, required this.model, required this.back});
  @override
  Widget build(BuildContext context) {
    final entries = _badgeEntries(model);
    return ScreenBody(
      children: [
        PageHeader('My badge collection', back: back),
        gap(25),
        tx('Your curiosity shines!', size: 26, weight: FontWeight.w900),
        gap(8),
        tx('Every case can unlock a different badge.', size: 14, color: muted),
        gap(26),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: SoftCard(
              color: entry.earned ? yellow : const Color(0xFFF0EFEC),
              child: Row(
                children: [
                  Text(
                    entry.earned ? entry.emoji : '🔒',
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        tx(entry.title, size: 17),
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

List<({String emoji, String title, String description, bool earned})> _badgeEntries(
  AppModel model,
) {
  final earned = <String, ({String emoji, String title, String description, bool earned})>{};
  for (final discovery in model.discoveries) {
    final investigation = discovery.investigation;
    final title = investigation == null
        ? 'First steps'
        : _badgeTitleForInvestigation(investigation);
    earned[title] = (
      emoji: investigation == null
          ? discovery.emoji
          : _badgeEmojiForDomain(investigation.domain),
      title: title,
      description: investigation == null
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

int _earnedBadgeCount(AppModel model) =>
    _badgeEntries(model).where((entry) => entry.earned).length;

String _badgeTitleForInvestigation(InvestigationView investigation) {
  final policyBadge = _policyBadgeName(investigation);
  if (policyBadge != null && policyBadge.isNotEmpty) return policyBadge;
  if (investigation.safetyEvents.isNotEmpty) return 'Safety Captain';
  if (investigation.domain == 'heritage') return 'Time Detective';
  if (investigation.domain == 'safe_dining') return 'Ingredient Investigator';
  if (investigation.domain == 'general') return 'Question Explorer';
  return 'Nature Explorer';
}

String? _policyBadgeName(InvestigationView investigation) {
  final policy = investigation.policyMessage;
  if (!policy.contains('Badge earned:')) return null;
  return policy.split('Badge earned:').last.split('.').first.trim();
}

String _badgeEmojiForDomain(String domain) {
  if (domain == 'heritage') return '🏛️';
  if (domain == 'safe_dining') return '🛡️';
  if (domain == 'general') return '💡';
  return '🌿';
}
