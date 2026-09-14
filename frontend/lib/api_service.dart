import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'model.dart';

const defaultApiBaseUrl = String.fromEnvironment(
  'CURIO_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

class ApiLearningService implements LearningService {
  final String baseUrl;
  final http.Client client;
  final LearningService fallback;

  ApiLearningService({
    this.baseUrl = defaultApiBaseUrl,
    http.Client? client,
    LearningService? fallback,
  }) : client = client ?? http.Client(),
       fallback = fallback ?? DemoLearningService();

  @override
  List<QuizQuestion> quiz(bool older) => fallback.quiz(older);

  @override
  Future<List<QuizQuestion>> dynamicQuiz(bool older) async {
    try {
      final response = await client
              .get(Uri.parse('$baseUrl/puzzles?age_band=${older ? '7-9' : '3-6'}'))
          .timeout(const Duration(seconds: 24));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Curio puzzle API returned ${response.statusCode}');
      }
      final items = jsonDecode(response.body);
      if (items is! List) {
        throw Exception('Curio puzzle API returned an unexpected shape');
      }
      final parsed = items
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => QuizQuestion(
              _string(item['title'], 'Mystery puzzle'),
              _string(item['emoji'], '🔎'),
              _list(item['choices']).map((choice) => choice.toString()).toList(),
              item['correct'] is int ? item['correct'] as int : 0,
              _string(item['explanation'], 'Every clue helps us learn.'),
            ),
          )
          .where((question) => question.choices.length >= 2)
          .toList();
      if (parsed.isEmpty) {
        throw Exception('Curio puzzle API returned no usable cards');
      }
      return parsed;
    } catch (error) {
      throw Exception('Curio puzzle API unavailable: $error');
    }
  }

  @override
  Future<Discovery> ask(
    String question,
    bool older, {
    ParentContactView? parentContact,
  }) async {
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/investigations'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'prompt': question,
              'user_mode': 'kid',
              'age_band': older ? '7-9' : '3-6',
              if (parentContact != null)
                'parent_contact': parentContactToJson(parentContact),
            }),
          )
          .timeout(const Duration(seconds: 24));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Curio API returned ${response.statusCode}');
      }
      return discoveryFromInvestigation(
        question,
        jsonDecode(response.body) as Map<String, dynamic>,
        older: older,
      );
    } catch (error) {
      throw Exception('Curio API unavailable: $error');
    }
  }

  @override
  Future<Discovery> askWithImage(
    String question,
    List<int> imageBytes, {
    required String filename,
    required String contentType,
    required bool older,
    ParentContactView? parentContact,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/investigations/from-image'),
      )
        ..fields['prompt'] = question
        ..fields['user_mode'] = 'kid'
        ..fields['coarse_location'] = ''
        ..fields['parent_email'] = parentContact?.email ?? ''
        ..fields['parent_phone'] = parentContact?.phone ?? ''
        ..fields['parent_push_token'] = parentContact?.pushToken ?? ''
        ..fields['parent_email_verified'] =
            (parentContact?.emailVerified ?? false).toString()
        ..fields['parent_phone_verified'] =
            (parentContact?.phoneVerified ?? false).toString()
        ..fields['parent_push_enabled'] =
            (parentContact?.pushEnabled ?? false).toString()
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: filename,
            contentType: _mediaType(contentType),
          ),
        );
      final streamed = await client.send(request).timeout(
            const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Curio image API returned ${response.statusCode}');
      }
      return discoveryFromInvestigation(
        question,
        jsonDecode(response.body) as Map<String, dynamic>,
        older: older,
      );
    } catch (error) {
      throw Exception('Curio image API unavailable: $error');
    }
  }
}

class ApiAccountService implements AccountService {
  final String baseUrl;
  final http.Client client;
  final AccountService fallback;

  ApiAccountService({
    this.baseUrl = defaultApiBaseUrl,
    http.Client? client,
    AccountService? fallback,
  }) : client = client ?? http.Client(),
       fallback = fallback ?? DemoAccountService();

  @override
  Future<ParentProfileView> registerParent({
    required String parentName,
    required String childName,
    required ParentContactView contact,
  }) async {
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/parents/register'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'parent_name': parentName,
              'child_name': childName,
              'contact': parentContactToJson(contact),
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback.registerParent(
          parentName: parentName,
          childName: childName,
          contact: contact,
        );
      }
      return parentProfileFromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      return fallback.registerParent(
        parentName: parentName,
        childName: childName,
        contact: contact,
      );
    }
  }
}

Discovery discoveryFromInvestigation(
  String question,
  Map<String, dynamic> data, {
  required bool older,
}) {
  final investigation = investigationFromJson(data);
  final answer = investigation.kidSummary;
  return Discovery(
    question,
    answer,
    topicFromDomain(investigation.domain),
    emojiFromInvestigation(investigation),
    'Today',
    investigation: investigation,
  );
}

InvestigationView investigationFromJson(Map<String, dynamic> data) {
  final conclusion = data['conclusion'] as Map<String, dynamic>?;
  final hypotheses = _list(data['hypotheses'])
      .map(
        (h) => HypothesisView(
          _string(h['label'], 'Possible answer'),
          _string(h['probability_band'], 'low'),
          _string(h['rationale'], 'Curio is checking the evidence.'),
          status: _string(h['status'], 'active'),
        ),
      )
      .toList();
  final evidence = _list(data['evidence'])
      .map(
        (e) => EvidenceView(
          _string(e['type'], 'evidence'),
          _string(e['observation'], 'Observation recorded.'),
          _string(e['reliability'], 'medium'),
        ),
      )
      .toList();
  final quest = data['selected_quest'] as Map<String, dynamic>? ?? {};
  final questModality = _string(quest['modality'], 'photo');
  final questInstruction = _string(quest['instruction'], 'Collect one more safe clue.');
  final safetyEvents = _list(data['safety_events'])
      .map(
        (event) => SafetyEventView(
          severity: _string(event['severity'], 'safe'),
          title: _string(event['title'], 'Safety notice'),
          childMessage: _string(
            event['child_message'],
            'Please ask a grown-up for help.',
          ),
          parentMessage: _string(
            event['parent_message'],
            'Curio detected something that may need parent review.',
          ),
          recommendedAction: _string(
            event['recommended_action'],
            'Review this discovery with your child.',
          ),
          notifyParent: event['notify_parent'] != false,
        ),
      )
      .toList();
  return InvestigationView(
    domain: _string(data['domain'], 'general'),
    confidence: _string(data['confidence_band'], 'low'),
    status: _string(data['status'], 'needs_evidence'),
    policyMessage: _string(data['policy_message'], ''),
    uncertainty: _string(
      data['uncertainty_note'],
      'We need one more clue before making a strong conclusion.',
    ),
    parentSummary: conclusion == null
        ? _string(
            data['uncertainty_note'],
            'The agent is waiting for one more useful piece of evidence.',
          )
        : _string(
            conclusion['parent_summary'],
            'The evidence chain is ready for parent review.',
          ),
    kidSummary: conclusion == null
        ? _string(
            data['uncertainty_note'],
            'We need one more clue before we decide.',
          )
        : _string(
            conclusion['kid_summary'],
            'We used new evidence to update our idea.',
          ),
    hypotheses: hypotheses,
    evidence: evidence,
    quest: QuestView(
      questInstruction,
      questModality,
      _string(quest['completion_rule'], 'A useful clue is visible.'),
      _firstString(data['safety_flags']) ??
          _string(data['policy_message'], 'Stay safe with an adult.'),
    ),
    curiosityQuestion: questModality == 'curiosity_question'
        ? questInstruction
        : '',
    safetyFlags: _list(data['safety_flags'])
        .map((item) => item.toString())
        .toList(),
    sources: conclusion == null
        ? const []
        : _list(conclusion['sources']).map((item) => item.toString()).toList(),
    safetyEvents: safetyEvents,
    notificationDeliveries: _deliverySummaries(data['notification_deliveries']),
  );
}

String topicFromDomain(String domain) => switch (domain) {
  'heritage' => 'Heritage',
  'nature' => 'Nature',
  'safe_dining' => 'Food',
  _ => 'Science',
};

String emojiFromDomain(String domain) => switch (domain) {
  'heritage' => '🏛️',
  'nature' => '🌿',
  'safe_dining' => '🍽️',
  _ => '✨',
};

String emojiFromInvestigation(InvestigationView investigation) {
  final labels = [
    if (investigation.hypotheses.isNotEmpty) investigation.hypotheses.first.label,
    investigation.kidSummary,
    investigation.curiosityQuestion,
  ].join(' ').toLowerCase();
  if (labels.contains('squirrel')) return '🐿️';
  if (labels.contains('rabbit')) return '🐇';
  if (labels.contains('bird')) return '🐦';
  if (labels.contains('cat')) return '🐈';
  if (labels.contains('dog')) return '🐕';
  if (labels.contains('butterfly')) return '🦋';
  if (labels.contains('acorn')) return '🌰';
  if (labels.contains('oak')) return '🌳';
  if (labels.contains('knife') || labels.contains('blade')) return '⚠️';
  return emojiFromDomain(investigation.domain);
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String _string(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _firstString(Object? value) {
  final items = _list(value);
  if (items.isEmpty) return null;
  return items.first.toString();
}

List<String> _deliverySummaries(Object? value) => _list(value)
    .map((item) {
      if (item is! Map<String, dynamic>) return item.toString();
      final channel = _string(item['channel'], 'channel');
      final status = _string(item['status'], 'pending');
      final target = _string(item['target_hint'], '');
      if (target.isEmpty) return '$channel $status';
      return '$channel $status to $target';
    })
    .where((item) => item.trim().isNotEmpty)
    .toList();

MediaType _mediaType(String contentType) {
  final parts = contentType.split('/');
  if (parts.length == 2) return MediaType(parts[0], parts[1]);
  return MediaType('image', 'jpeg');
}

Map<String, dynamic> parentContactToJson(ParentContactView contact) => {
      'email': contact.email,
      'phone': contact.phone,
      'push_token': contact.pushToken,
      'email_verified': contact.emailVerified,
      'phone_verified': contact.phoneVerified,
      'push_enabled': contact.pushEnabled,
    };

ParentProfileView parentProfileFromJson(Map<String, dynamic> data) {
  final contact = data['contact'] as Map<String, dynamic>? ?? {};
  return ParentProfileView(
    parentId: _string(data['parent_id'], 'parent_demo'),
    parentName: _string(data['parent_name'], 'Parent'),
    childName: _string(data['child_name'], 'Child'),
    contact: ParentContactView(
      email: _string(contact['email'], ''),
      phone: _string(contact['phone'], ''),
      pushToken: _string(contact['push_token'], ''),
      emailVerified: contact['email_verified'] == true,
      phoneVerified: contact['phone_verified'] == true,
      pushEnabled: contact['push_enabled'] == true,
    ),
    channels: _list(data['notification_channels'])
        .map((item) => item is Map<String, dynamic>
            ? _string(item['channel'], '')
            : item.toString())
        .where((item) => item.isNotEmpty)
        .toList(),
  );
}
