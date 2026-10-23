import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/design.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final keyInput = TextEditingController(),
      secret = TextEditingController(),
      endpoint = TextEditingController(),
      model = TextEditingController(),
      aiKey = TextEditingController();
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load().catchError((Object _) {});
  }

  Future<void> load() async {
    final vault = ref.read(vaultProvider);
    final e = await vault.read('assistant', 'endpoint'),
        m = await vault.read('assistant', 'model');
    if (mounted) {
      endpoint.text = e ?? '';
      model.text = m ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [keyInput, secret, endpoint, model, aiKey]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> action(Future<void> Function() f) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await f();
      if (mounted) toast(context, tr(ref, 'saved'));
    } catch (_) {
      if (mounted) toast(context, tr(ref, 'storage_error'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> preference(String key, String value) => ref
      .read(databaseProvider)
      .insert('preferences', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace)
      .then((_) {});
  @override
  Widget build(BuildContext context) {
    final exchange = ref.watch(exchangeProvider),
        vault = ref.watch(vaultProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'settings'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Notice(tr(ref, 'no_live'), icon: Icons.lock_outline, color: mint),
          SectionTitle(tr(ref, 'language')),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'fa', label: Text('فارسی')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {ref.watch(localeProvider)},
            onSelectionChanged: (s) {
              ref.read(localeProvider.notifier).state = s.first;
              action(() => preference('locale', s.first));
            },
          ),
          SectionTitle(tr(ref, 'exchange')),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Toobit', label: Text('Toobit')),
              ButtonSegment(value: 'LBank', label: Text('LBank')),
            ],
            selected: {exchange},
            onSelectionChanged: (s) {
              ref.read(exchangeProvider.notifier).state = s.first;
              action(() => preference('exchange', s.first));
            },
          ),
          Notice(tr(ref, 'kcex')),
          SectionTitle(tr(ref, 'security')),
          Surface(
            child: Column(
              children: [
                Notice(tr(ref, 'credentials_note')),
                TextField(
                  controller: keyInput,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: tr(ref, 'api_key')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: secret,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: tr(ref, 'secret')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: busy
                            ? null
                            : () => action(() async {
                                if (keyInput.text.isEmpty ||
                                    secret.text.isEmpty) {
                                  return;
                                }
                                await vault.save(
                                  exchange,
                                  keyInput.text,
                                  secret.text,
                                );
                                keyInput.clear();
                                secret.clear();
                              }),
                        child: Text(tr(ref, 'save')),
                      ),
                    ),
                    IconButton(
                      tooltip: tr(ref, 'delete'),
                      onPressed: busy
                          ? null
                          : () => action(() => vault.clear(exchange)),
                      icon: const Icon(Icons.delete_outline, color: red),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionTitle(tr(ref, 'assistant')),
          Surface(
            child: Column(
              children: [
                Notice(tr(ref, 'ai_note')),
                TextField(
                  controller: endpoint,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: tr(ref, 'endpoint'),
                    hintText: 'https://…/v1',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: model,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: tr(ref, 'model')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aiKey,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(labelText: tr(ref, 'api_key')),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => action(() async {
                          final uri = Uri.tryParse(endpoint.text.trim());
                          if (uri == null ||
                              uri.scheme != 'https' ||
                              uri.host.isEmpty) {
                            throw ArgumentError('HTTPS required');
                          }
                          await vault.storage.write(
                            key: 'assistant.endpoint',
                            value: endpoint.text.trim(),
                          );
                          await vault.storage.write(
                            key: 'assistant.model',
                            value: model.text.trim(),
                          );
                          if (aiKey.text.isNotEmpty) {
                            await vault.storage.write(
                              key: 'assistant.key',
                              value: aiKey.text.trim(),
                            );
                          }
                          aiKey.clear();
                        }),
                  child: Text(tr(ref, 'save')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'CryptoAITrader Mobile • 0.1.0\nResearch build / paper-only',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: muted,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
