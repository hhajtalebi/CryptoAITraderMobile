import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/design.dart';
import '../../analysis/application/analysis_provider.dart';
import '../data/assistant_service.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});
  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final input = TextEditingController();
  late final AssistantService service;
  bool busy = false;
  String? answer, question;
  @override
  void initState() {
    super.initState();
    service = AssistantService(ref.read(vaultProvider));
  }

  @override
  void dispose() {
    input.dispose();
    service.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (input.text.trim().isEmpty || busy) return;
    setState(() {
      busy = true;
      question = input.text.trim();
      answer = null;
    });
    final a = ref.read(analysisProvider).valueOrNull?.analysis;
    try {
      final reply = await service.ask(
        question!,
        a == null
            ? 'unavailable'
            : '${a.symbol}, ${a.interval}, ${a.direction.name}, score ${a.confidence}, reason ${a.reason}; score is not calibrated probability.',
      );
      if (mounted) setState(() => answer = reply);
    } catch (e) {
      if (mounted) {
        toast(context, tr(ref, e is StateError ? e.message : 'ai_error'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr(ref, 'assistant'))),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, size: 30, color: mint),
              const SizedBox(height: 12),
              Text(
                tr(ref, 'assistant_sub'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Notice(tr(ref, 'ai_note')),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: input,
          maxLines: 4,
          maxLength: 2000,
          decoration: InputDecoration(hintText: tr(ref, 'ask')),
        ),
        FilledButton(
          onPressed: busy ? null : send,
          child: Text(tr(ref, 'send')),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          ),
        if (answer != null) ...[
          const SizedBox(height: 20),
          Surface(
            child: SelectableText(
              answer!,
              style: const TextStyle(fontFamily: 'Vazirmatn', height: 1.8),
            ),
          ),
        ],
        Notice(tr(ref, 'assistant_disclaimer')),
      ],
    ),
  );
}
