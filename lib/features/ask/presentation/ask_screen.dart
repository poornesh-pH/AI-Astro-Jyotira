import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/payments/subscription_service.dart';
import '../../../core/prefs/birth_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../kundli/application/kundli_providers.dart';
import '../../kundli/data/interpretation_repo.dart';
 
class _Msg {
  final String text;
  final bool fromUser;
  const _Msg(this.text, this.fromUser);
}
 
/// "Ask AI Jyotish" — answers grounded strictly in the user's chart facts.
/// Premium-gated. Each answer is one short backend call (cheap model).
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});
  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}
 
class _AskScreenState extends ConsumerState<AskScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _sending = false;
 
  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }
 
  Future<void> _send() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Msg(q, true));
      _sending = true;
      _ctrl.clear();
    });
    _scrollDown();
    try {
      final kundli = await ref.read(kundliProvider.future);
      if (kundli == null) {
        setState(() => _messages
            .add(const _Msg('Please add your birth details first.', false)));
        return;
      }
      final lang = ref.read(localeStoreProvider).valueOrNull ?? 'en';
      final repo = ref.read(interpretationRepoProvider);
      final answer = await repo.interpret(
        chartHash: kundli.hash,
        ground: kundli.toGroundTruth(),
        type: ReadingType.ask,
        lang: lang,
        question: q,
      );
      setState(() => _messages.add(_Msg(answer, false)));
    } catch (e) {
      setState(() => _messages.add(_Msg(e.toString(), false)));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollDown();
      }
    }
  }
 
  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
 
  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ask AI Jyotish')),
      body: SafeArea(
        child: sub.when(
          loading: () => const LoadingView(),
          error: (_, __) => _locked(context),
          data: (active) => active ? _chat() : _locked(context),
        ),
      ),
    );
  }
 
  Widget _locked(BuildContext context) =>
      PremiumLock(onUnlock: () => context.push('/paywall'));
 
  Widget _chat() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const EmptyView(
                  icon: Icons.forum_outlined,
                  message:
                      'Ask about career, marriage, timing or remedies —\nanswers are grounded in your chart.',
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _Bubble(msg: _messages[i]),
                ),
        ),
        if (_sending)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Type your question…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
 
class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;
 
  @override
  Widget build(BuildContext context) {
    final align =
        msg.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = msg.fromUser ? AppTheme.saffron : AppTheme.surface;
    final textColor = msg.fromUser ? Colors.white : AppTheme.ink;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.gold.withValues(alpha: .35)),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(color: textColor, height: 1.4),
        ),
      ),
    );
  }
}
