import 'package:flutter/material.dart';
import 'model.dart';
import 'ui.dart';

class ParentGate extends StatefulWidget {
  final AppModel model;
  final VoidCallback back, onSuccess;
  const ParentGate({
    super.key,
    required this.model,
    required this.back,
    required this.onSuccess,
  });
  @override
  State<ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<ParentGate> {
  final answer = TextEditingController();
  String? error;
  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      PageHeader('Parent area', back: widget.back),
      gap(45),
      const Center(child: Text('🔐', style: TextStyle(fontSize: 75))),
      gap(24),
      tx(
        'This area is\nfor grown-ups.',
        size: 31,
        weight: FontWeight.w900,
        align: TextAlign.center,
      ),
      gap(13),
      tx(
        'Please hand the device to your parent.',
        size: 16,
        color: muted,
        align: TextAlign.center,
      ),
      gap(31),
      SoftCard(
        color: mint,
        child: Column(
          children: [
            tx('Enter your parent password.', size: 14),
            gap(17),
            const Icon(Icons.password_rounded, size: 40, color: blue),
            gap(18),
            TextField(
              controller: answer,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Parent password',
                errorText: error,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      gap(24),
      PrimaryButton(
        'Open parent dashboard',
        color: const Color(0xFF739B83),
        onTap: () {
          if (answer.text == widget.model.parentPassword) {
            widget.onSuccess();
          } else {
            setState(() => error = 'Incorrect parent password. Try again.');
          }
        },
        icon: Icons.lock_open_rounded,
      ),
      gap(20),
      tx(
        'Use the separate password created during sign-up. This preview keeps it only for this session.',
        size: 11,
        color: muted,
        align: TextAlign.center,
      ),
    ],
  );
}

class ParentScreen extends StatelessWidget {
  final AppModel model;
  final void Function(String) go;
  final VoidCallback back;
  const ParentScreen({
    super.key,
    required this.model,
    required this.go,
    required this.back,
  });
  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      PageHeader(
        'Parent dashboard',
        back: back,
        trailing: IconButton(
          onPressed: () => go('settings'),
          tooltip: 'Account & permissions',
          icon: const Icon(Icons.settings_outlined, color: muted),
        ),
      ),
      gap(20),
      Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: const BoxDecoration(
              color: peach,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👧🏻', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tx(
                  '${model.childName}’s learning journey',
                  size: 18,
                  weight: FontWeight.w900,
                ),
                tx('Sample weekly overview', size: 11, color: muted),
              ],
            ),
          ),
        ],
      ),
      gap(20),
      const SectionHeading('Questions to review'),
      gap(12),
      ReviewQueue(model),
      gap(21),
      Row(
        children: [
          Expanded(
            child: SoftCard(
              color: mint,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_stories_outlined,
                    color: Color(0xFF759581),
                    size: 22,
                  ),
                  gap(12),
                  tx(
                    '${model.discoveries.length}',
                    size: 30,
                    weight: FontWeight.w900,
                  ),
                  tx('Questions explored', size: 11, color: muted),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SoftCard(
              color: yellow,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.extension_outlined,
                    color: Color(0xFFB89A4F),
                    size: 22,
                  ),
                  gap(12),
                  tx(
                    '${model.quizCompleted}',
                    size: 30,
                    weight: FontWeight.w900,
                  ),
                  tx('Quizzes completed', size: 11, color: muted),
                ],
              ),
            ),
          ),
        ],
      ),
      gap(20),
      const SectionHeading('Safety notifications'),
      gap(12),
      NotificationCenter(model.notifications),
      gap(20),
      SoftCard(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: tx('Screen time', size: 17, weight: FontWeight.w900),
                ),
                const Tag('THIS WEEK', color: mint),
              ],
            ),
            gap(13),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                tx('24', size: 35, weight: FontWeight.w900),
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 6),
                  child: tx('min today', size: 12, color: muted),
                ),
                const Spacer(),
                tx('Sample data', size: 10, color: muted),
              ],
            ),
            gap(18),
            SizedBox(
              height: 102,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          tx(
                            '${[18, 28, 16, 35, 22, 24, 0][i]}',
                            size: 9,
                            color: muted,
                          ),
                          gap(4),
                          Container(
                            width: 22,
                            height: [18, 28, 16, 35, 22, 24, 0][i] * 1.5 + 3,
                            decoration: BoxDecoration(
                              color: i == 5 ? const Color(0xFF81A98E) : mint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          gap(7),
                          tx(
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][i],
                            size: 9,
                            color: muted,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            gap(18),
            const Divider(color: Color(0xFFF0F0ED)),
            gap(9),
            Row(
              children: [
                Expanded(child: tx('Daily time limit', size: 13)),
                tx(
                  '${model.dailyLimit} min',
                  size: 14,
                  color: const Color(0xFF62846C),
                ),
              ],
            ),
            Slider(
              value: model.dailyLimit.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              label: '${model.dailyLimit} min',
              activeColor: const Color(0xFF81A98E),
              onChanged: (v) =>
                  model.update(() => model.dailyLimit = v.round()),
            ),
            tx(
              'This preference lasts for this session.',
              size: 10,
              color: muted,
            ),
          ],
        ),
      ),
      gap(20),
      const SectionHeading('What sparks their curiosity?'),
      gap(12),
      SoftCard(
        color: sky,
        child: Column(
          children: [
            for (final t in topics.where(
              (t) => model.history(t.name).isNotEmpty,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(t.emoji, style: const TextStyle(fontSize: 23)),
                    const SizedBox(width: 10),
                    Expanded(child: tx(t.name, size: 13)),
                    tx(
                      '${model.history(t.name).length} questions',
                      size: 12,
                      color: muted,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      gap(16),
      SoftCard(
        color: lilac,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tx('Try learning together', size: 15),
            gap(8),
            tx(
              'Animals are one of their favorite topics. On a nature walk, talk about the creatures you spot together.',
              size: 13,
              weight: FontWeight.w600,
            ),
          ],
        ),
      ),
      gap(20),
      PrimaryButton(
        'Manage account & permissions',
        onTap: () => go('settings'),
        color: const Color(0xFF739B83),
        icon: Icons.tune_rounded,
      ),
    ],
  );
}

class ReviewQueue extends StatelessWidget {
  final AppModel model;
  const ReviewQueue(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    final flagged = model.flaggedQuestions;
    return SoftCard(
      color: peach,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: coral, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: tx(
                  flagged.isEmpty ? 'No parent review needed' : 'Review queue',
                  size: 16,
                  weight: FontWeight.w900,
                ),
              ),
              Tag('${flagged.length}', color: Colors.white),
            ],
          ),
          gap(12),
          if (flagged.isEmpty)
            tx(
              'Curio will surface urgent or age-sensitive moments here for a grown-up check.',
              size: 12,
              color: muted,
            )
          else
            for (final item in flagged.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tx(item.question, size: 13, weight: FontWeight.w800),
                    gap(4),
                    tx(_reviewLabel(item), size: 11, color: muted),
                  ],
                ),
              ),
          gap(6),
          tx(
            'Immediate danger still goes to Safety notifications first.',
            size: 10,
            color: muted,
          ),
        ],
      ),
    );
  }

  String _reviewLabel(Discovery item) {
    final safety = item.investigation?.safetyEvents;
    if (safety != null && safety.isNotEmpty) {
      return '${safety.first.title} · ${item.date}';
    }
    return '${reviewReason(item.question) ?? 'Needs parent context'} · ${item.date}';
  }
}

class NotificationCenter extends StatelessWidget {
  final List<ParentNotification> notifications;
  const NotificationCenter(this.notifications, {super.key});

  @override
  Widget build(BuildContext context) => SoftCard(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    child: Column(
      children: [
        for (final item in notifications.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _NotificationRow(item),
          ),
      ],
    ),
  );
}

class _NotificationRow extends StatelessWidget {
  final ParentNotification item;
  const _NotificationRow(this.item);

  @override
  Widget build(BuildContext context) {
    final urgent = item.severity == 'emergency' || item.severity == 'danger';
    final color = item.severity == 'emergency'
        ? const Color(0xFFC94444)
        : item.severity == 'danger'
        ? const Color(0xFFB06F1F)
        : const Color(0xFF739B83);
    return ListTile(
      minLeadingWidth: 32,
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: color.withOpacity(.14),
        child: Icon(
          urgent ? Icons.notification_important_outlined : Icons.check_rounded,
          size: 19,
          color: color,
        ),
      ),
      title: Row(
        children: [
          Expanded(child: tx(item.title, size: 13, weight: FontWeight.w900)),
          if (item.unread && urgent)
            const Tag('NEW', color: Color(0xFFFFDFDE)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.body,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                height: 1.3,
                color: muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.action,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                height: 1.3,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.deliverySummary,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                height: 1.25,
                color: Color(0xFF8A8F9E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final AppModel model;
  final VoidCallback back;
  const SettingsScreen({super.key, required this.model, required this.back});
  Future<void> edit(BuildContext context, String type) async {
    final controller = TextEditingController(
      text: type == 'Email'
          ? model.email
          : type == 'Phone number'
          ? model.phone
          : model.childName,
    );
    final form = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Edit $type'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Changes are saved only for this demo session.',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
              gap(18),
              TextFormField(
                controller: controller,
                keyboardType: type == 'Email'
                    ? TextInputType.emailAddress
                    : type == 'Phone number'
                    ? TextInputType.phone
                    : TextInputType.name,
                decoration: InputDecoration(labelText: type),
                validator: (s) {
                  final v = (s ?? '').trim();
                  if (type == 'Email' &&
                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
                    return 'Enter a valid email address.';
                  }
                  if (type == 'Phone number' &&
                      !RegExp(r'^\+?[0-9\s]{10,16}$').hasMatch(v)) {
                    return 'Enter a valid phone number.';
                  }
                  return v.isEmpty ? 'This field cannot be empty.' : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(c, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      model.update(() {
        if (type == 'Email') {
          model.email = result;
        } else if (type == 'Phone number') {
          model.phone = result;
        } else {
          model.childName = result;
        }
      });
      if (context.mounted) notice(context, '$type updated for this session.');
    }
    // Delay disposal until the dialog exit transition has completed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => ScreenBody(
    children: [
      PageHeader('Account & permissions', back: back),
      gap(25),
      tx('Make it work for your family.', size: 25, weight: FontWeight.w900),
      gap(9),
      tx('Account details and learning preferences.', size: 14, color: muted),
      gap(26),
      const SectionHeading('Account details'),
      gap(12),
      SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        child: Column(
          children: [
            for (final item in [
              ('Email', model.email, Icons.mail_outline_rounded),
              ('Phone number', model.phone, Icons.phone_outlined),
              ('Child name', model.childName, Icons.face_outlined),
            ])
              ListTile(
                onTap: () => edit(context, item.$1),
                leading: Icon(item.$3, color: const Color(0xFF7F9988)),
                title: tx(item.$1, size: 13),
                subtitle: Text(
                  item.$2,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: muted,
                  ),
                ),
                trailing: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: muted,
                ),
              ),
          ],
        ),
      ),
      gap(25),
      const SectionHeading('Parent notifications'),
      gap(12),
      SoftCard(
        color: yellow,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        child: Column(
          children: [
            SwitchListTile(
              value: model.safetyAlerts,
              onChanged: (v) => model.update(() => model.safetyAlerts = v),
              activeThumbColor: const Color(0xFFB89A4F),
              title: tx('Immediate safety alerts', size: 14),
              subtitle: tx(
                'Notify parent for danger or emergency detections',
                size: 11,
                color: muted,
              ),
            ),
            SwitchListTile(
              value: model.weeklyDigest,
              onChanged: (v) => model.update(() => model.weeklyDigest = v),
              activeThumbColor: const Color(0xFFB89A4F),
              title: tx('Weekly learning digest', size: 14),
              subtitle: tx(
                'Summarize curiosity topics and open questions',
                size: 11,
                color: muted,
              ),
            ),
          ],
        ),
      ),
      gap(25),
      const SectionHeading('Learning permissions'),
      gap(12),
      SoftCard(
        color: mint,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        child: Column(
          children: [
            SwitchListTile(
              value: model.voice,
              onChanged: (v) => model.update(() => model.voice = v),
              activeThumbColor: const Color(0xFF739B83),
              title: tx('Voice questions', size: 14),
              subtitle: tx(
                'Explore using the microphone',
                size: 11,
                color: muted,
              ),
            ),
            SwitchListTile(
              value: model.photos,
              onChanged: (v) => model.update(() => model.photos = v),
              activeThumbColor: const Color(0xFF739B83),
              title: tx('Photo questions', size: 14),
              subtitle: tx('Camera and gallery access', size: 11, color: muted),
            ),
            SwitchListTile(
              value: model.reminders,
              onChanged: (v) => model.update(() => model.reminders = v),
              activeThumbColor: const Color(0xFF739B83),
              title: tx('Break reminders', size: 14),
              subtitle: tx('Remember to take a break', size: 11, color: muted),
            ),
          ],
        ),
      ),
      gap(22),
      const SoftCard(
        color: sky,
        child: Text(
          'This prototype does not enforce account verification, device permissions or time limits. Email and phone changes must be verified in the production app.',
          style: TextStyle(fontSize: 12, color: Color(0xFF60789B)),
        ),
      ),
      gap(24),
      PrimaryButton(
        'Back to dashboard',
        onTap: back,
        color: const Color(0xFF739B83),
      ),
    ],
  );
}
