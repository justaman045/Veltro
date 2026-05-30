import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/app_colors.dart';

class AiBriefingCard extends ConsumerStatefulWidget {
  const AiBriefingCard({super.key});

  @override
  ConsumerState<AiBriefingCard> createState() => _AiBriefingCardState();
}

class _AiBriefingCardState extends ConsumerState<AiBriefingCard> {
  String? _briefing;
  bool _isLoading = false;
  bool _expanded = true;

  Future<void> _generateBriefing() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final allTasks = await ref.read(allTasksProvider.future);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayTasks = allTasks.where((t) {
        if (t.startTime == null || t.isCompleted) return false;
        final d = t.startTime!;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList();

      if (todayTasks.isEmpty) {
        setState(() {
          _briefing = 'No tasks scheduled for today. Add a task to get started!';
          _isLoading = false;
          _expanded = true;
        });
        return;
      }

      final aiService = ref.read(aiServiceProvider);
      final userName = ref.read(authServiceProvider).currentUser?.displayName ?? 'there';
      final result = await aiService.dailyBriefing(todayTasks, userName);

      if (!mounted) return;
      setState(() {
        _briefing = result.isNotEmpty ? result : 'Could not generate briefing. Try again later.';
        _isLoading = false;
        _expanded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _briefing = 'Failed to generate briefing. Check your connection and try again.';
        _isLoading = false;
        _expanded = true;
      });
    }
  }

  void _dismiss() {
    setState(() {
      _briefing = null;
      _isLoading = false;
      _expanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_briefing != null) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                context.gradientPrimary.withValues(alpha: 0.08),
                context.gradientSecondary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(color: context.gradientPrimary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: context.gradientPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.auto_awesome, size: 16, color: context.gradientPrimary),
                  ),
                  const SizedBox(width: 10),
                  const Text('AI Briefing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.close, size: 14, color: isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _briefing!,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isLoading ? null : _generateBriefing,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              context.gradientPrimary.withValues(alpha: 0.08),
              context.gradientSecondary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          border: Border.all(color: context.gradientPrimary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.gradientPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.gradientPrimary,
                      ),
                    )
                  : Icon(Icons.auto_awesome, size: 16, color: context.gradientPrimary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isLoading ? 'Generating briefing\u2026' : 'Summarize today with AI',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: context.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Summarize',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
