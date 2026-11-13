import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'activity_header.dart';
import 'answer_panel.dart';
import 'content/choice.dart';
import 'feedback_banner.dart';
import 'feedback_layout.dart';
import 'kid_avatar.dart';
import 'option_tile.dart';
import 'score.dart';
import 'shake.dart';

/// What one classmate says: [Right], or [Wrong] with why it is wrong.
class Claim {
  const Claim(this.kid, this.choice);

  final Kid kid;
  final Choice choice;
}

/// Classmates disagree; the learner decides who is right. Each wrong claim is
/// a common misconception, so picking it earns an explanation of the flaw.
/// Right first time earns full credit, otherwise half.
class WhoIsRightActivity implements ActivityPlugin, Validated {
  const WhoIsRightActivity({
    required this.situation,
    required this.claims,
    required this.explanation,
    this.maxXp = 10,
  });

  final String situation;
  final List<Claim> claims;
  final String explanation;
  final int maxXp;

  @override
  void validate() =>
      checkOneRight([for (final c in claims) c.choice], situation);

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _WhoIsRightView(activity: this, host: host);
}

class _WhoIsRightView extends StatefulWidget {
  const _WhoIsRightView({required this.activity, required this.host});

  final WhoIsRightActivity activity;
  final ActivityHost host;

  @override
  State<_WhoIsRightView> createState() => _WhoIsRightViewState();
}

class _WhoIsRightViewState extends State<_WhoIsRightView> {
  final List<int> _wrong = [];
  final Map<int, int> _shakes = {};
  bool _solved = false;

  WhoIsRightActivity get _a => widget.activity;

  void _pick(int i) {
    if (_solved || _wrong.contains(i)) return;
    setState(() {
      if (_a.claims[i].choice is Right) {
        HapticFeedback.selectionClick();
        _solved = true;
        return;
      }
      HapticFeedback.lightImpact();
      _wrong.add(i);
      _shakes[i] = (_shakes[i] ?? 0) + 1;
    });
  }

  void _finish() => widget.host.complete(
    ActivityResult(
      xp: scoreXp(
        firstTry: _wrong.isEmpty ? 1 : 0,
        recovered: _wrong.isEmpty ? 0 : 1,
        total: 1,
        max: _a.maxXp,
      ),
      mistakes: _wrong.length,
    ),
  );

  OptionState _stateOf(int i) {
    if (_solved && _a.claims[i].choice is Right) return OptionState.correct;
    if (_wrong.contains(i)) return OptionState.wrong;
    return _solved ? OptionState.dimmed : OptionState.open;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: FeedbackLayout(feedback: _feedback(), page: _page),
  );

  Widget? _feedback() {
    if (_solved) {
      final winner = _a.claims.firstWhere((c) => c.choice is Right).kid;
      return AnswerPanel(
        key: const ValueKey('solved'),
        title: 'Yes! ${winner.name} is right.',
        explanation: _a.explanation,
        onContinue: _finish,
      );
    }
    final lastWrong = _wrong.lastOrNull;
    if (lastWrong == null) return null;
    final claim = _a.claims[lastWrong];
    return FeedbackBanner(
      key: ValueKey(lastWrong),
      kind: FeedbackKind.wrong,
      title: 'Not ${claim.kid.name}',
      message: (claim.choice as Wrong).feedback,
    );
  }

  Widget _page(BuildContext context, double covered) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActivityHeader(kind: ActivityKind.whoIsRight),
        const SizedBox(height: 12),
        Text(_a.situation, style: text.titleLarge?.copyWith(height: 1.3)),
        const SizedBox(height: 4),
        Text(
          'Tap the one who is right.',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _a.claims.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Shake(
                      trigger: _shakes[i] ?? 0,
                      child: _ClaimCard(
                        claim: _a.claims[i],
                        state: _stateOf(i),
                        avatarOnRight: i.isOdd,
                        onTap: () => _pick(i),
                      ),
                    ),
                  ),
                SizedBox(height: covered),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.claim,
    required this.state,
    required this.avatarOnRight,
    required this.onTap,
  });

  final Claim claim;
  final OptionState state;
  final bool avatarOnRight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final edge = switch (state) {
      OptionState.correct => AnswerPanel.correctGreen,
      OptionState.wrong => scheme.error,
      _ => scheme.outlineVariant,
    };
    final marked = state == OptionState.correct || state == OptionState.wrong;
    final avatar = Column(
      children: [
        KidAvatar(kid: claim.kid),
        const SizedBox(height: 4),
        Text(claim.kid.name, style: text.labelLarge),
      ],
    );
    final bubble = Expanded(
      child: Material(
        color: marked
            ? Color.alphaBlend(
                edge.withValues(alpha: 0.1),
                scheme.surfaceContainerLowest,
              )
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(avatarOnRight ? 20 : 4),
            bottomRight: Radius.circular(avatarOnRight ? 4 : 20),
          ),
          side: BorderSide(color: edge, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: state == OptionState.open ? onTap : null,
          child: Semantics(
            button: true,
            enabled: state == OptionState.open,
            label: switch (state) {
              OptionState.correct =>
                '${claim.kid.name}: ${claim.choice.text}, right',
              OptionState.wrong =>
                '${claim.kid.name}: ${claim.choice.text}, wrong',
              _ => '${claim.kid.name}: ${claim.choice.text}',
            },
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '\u201C${claim.choice.text}\u201D',
                      style: text.titleMedium?.copyWith(height: 1.3),
                    ),
                  ),
                  if (marked) ...[
                    const SizedBox(width: 8),
                    Icon(
                      state == OptionState.correct
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: edge,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: state == OptionState.wrong || state == OptionState.dimmed
          ? 0.55
          : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: avatarOnRight
            ? [bubble, const SizedBox(width: 10), avatar]
            : [avatar, const SizedBox(width: 10), bubble],
      ),
    );
  }
}
