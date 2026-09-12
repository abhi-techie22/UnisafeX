import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/admin/data/admin_remote_config_repository.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  var _category = 'general';
  var _priority = 'normal';
  var _submitting = false;
  int? _lastMarkedSeenAt;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final tickets = user == null ? null : ref.watch(mySupportTicketsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('help_support'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 34),
                const SizedBox(height: 18),
                Text(
                  'help_question'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'help_description'.tr(),
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SupportTicketForm(
            titleController: _title,
            messageController: _message,
            category: _category,
            priority: _priority,
            submitting: _submitting,
            signedIn: user != null,
            onCategoryChanged: (value) =>
                setState(() => _category = value ?? _category),
            onPriorityChanged: (value) =>
                setState(() => _priority = value ?? _priority),
            onSubmit: _submitTicket,
          ),
          const SizedBox(height: 20),
          Text(
            'Your support tickets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (tickets == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sign in to view support ticket history.'),
              ),
            )
          else
            tickets.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Could not load tickets: $error'),
              data: (items) {
                _markTicketsSeenAfterRender(user!.id, items);
                return items.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No support tickets yet.'),
                        ),
                      )
                    : Column(
                        children: items
                            .map((ticket) => _TicketStatusCard(ticket: ticket))
                            .toList(),
                      );
              },
            ),
          const SizedBox(height: 22),
          Text('quick_help'.tr(),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _SupportAction(
            icon: Icons.bug_report_outlined,
            title: 'report_problem'.tr(),
            subtitle: 'report_problem_subtitle'.tr(),
            onTap: () => _launch(
              context,
              Uri.parse(
                'https://github.com/abhi-techie22/UnisafeX/issues',
              ),
            ),
          ),
          _SupportAction(
            icon: Icons.phone_in_talk_outlined,
            title: 'tourist_helpline'.tr(),
            subtitle: 'tourist_helpline_subtitle'.tr(),
            onTap: () => _launch(context, Uri(scheme: 'tel', path: '1363')),
          ),
          _SupportAction(
            icon: Icons.emergency_outlined,
            title: 'emergency_assistance'.tr(),
            subtitle: 'emergency_assistance_subtitle'.tr(),
            onTap: () => _launch(context, Uri(scheme: 'tel', path: '112')),
          ),
          const SizedBox(height: 20),
          Text(
            'frequently_asked_questions'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _Faq(
            question: 'faq_profile_question'.tr(),
            answer: 'faq_profile_answer'.tr(),
          ),
          _Faq(
            question: 'faq_distance_question'.tr(),
            answer: 'faq_distance_answer'.tr(),
          ),
          _Faq(
            question: 'faq_currency_question'.tr(),
            answer: 'faq_currency_answer'.tr(),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(adminRemoteConfigRepositoryProvider).createSupportTicket(
            title: _title.text,
            message: _message.text,
            category: _category,
            priority: _priority,
          );
      _title.clear();
      _message.clear();
      ref.invalidate(mySupportTicketsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket sent to UniSafeX team.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit ticket: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _markTicketsSeenAfterRender(
    String userId,
    List<SupportTicket> tickets,
  ) {
    final latest = latestSupportAttentionUpdate(tickets);
    if (latest == null) return;
    final latestMs = latest.millisecondsSinceEpoch;
    if (_lastMarkedSeenAt == latestMs) return;
    _lastMarkedSeenAt = latestMs;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await markSupportTicketsSeen(userId: userId, tickets: tickets);
      if (!mounted) return;
      ref.invalidate(supportNeedsAttentionProvider);
    });
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('action_unavailable'.tr())),
      );
    }
  }
}

class _SupportTicketForm extends StatelessWidget {
  const _SupportTicketForm({
    required this.titleController,
    required this.messageController,
    required this.category,
    required this.priority,
    required this.submitting,
    required this.signedIn,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onSubmit,
  });

  final TextEditingController titleController;
  final TextEditingController messageController;
  final String category;
  final String priority;
  final bool submitting;
  final bool signedIn;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onPriorityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact UniSafeX support',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Send app problems to the admin team. You can track status and replies here.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleController,
              enabled: signedIn && !submitting,
              decoration: const InputDecoration(
                labelText: 'Problem title',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              enabled: signedIn && !submitting,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Explain the problem',
                hintText: 'What happened, where, and what should happen?',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(
                          value: 'general', child: Text('General')),
                      DropdownMenuItem(
                          value: 'profile', child: Text('Profile')),
                      DropdownMenuItem(value: 'places', child: Text('Places')),
                      DropdownMenuItem(value: 'guide', child: Text('Guide')),
                      DropdownMenuItem(value: 'map', child: Text('Map')),
                      DropdownMenuItem(value: 'bug', child: Text('Bug')),
                    ],
                    onChanged:
                        signedIn && !submitting ? onCategoryChanged : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged:
                        signedIn && !submitting ? onPriorityChanged : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: signedIn && !submitting ? onSubmit : null,
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(signedIn
                    ? submitting
                        ? 'Submitting...'
                        : 'Send to support'
                    : 'Sign in to contact support'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketStatusCard extends StatelessWidget {
  const _TicketStatusCard({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final resolved = ticket.status == 'resolved' || ticket.status == 'closed';
    final progress = switch (ticket.status) {
      'open' => 0.25,
      'in_progress' => 0.55,
      'waiting_user' => 0.75,
      'resolved' => 1.0,
      'closed' => 1.0,
      _ => 0.2,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                resolved
                    ? Icons.check_circle_rounded
                    : Icons.pending_actions_rounded,
                color: resolved ? AppColors.success : AppColors.primary,
              ),
              title: Text(ticket.title),
              subtitle: Text(
                '${ticket.status.replaceAll('_', ' ')} · ${ticket.category}\n'
                '${ticket.adminResponse?.isNotEmpty == true ? ticket.adminResponse! : ticket.message}',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  color: resolved ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
        onTap: onTap,
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(answer, style: const TextStyle(height: 1.5))],
      ),
    );
  }
}
