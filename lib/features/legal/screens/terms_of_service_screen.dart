import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_max_width.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _lastUpdated = 'Last updated: April 2026';

  static const _sections = <(String, String)>[
    (
      'Acceptance',
      'By creating an account or using Webroom you agree to these terms. If '
          'you do not agree, do not use the service.',
    ),
    (
      'Accounts',
      'You are responsible for the activity on your account. Keep your '
          'credentials private. Admins may gate your access to a single '
          'approved device; joining from another device requires your admin '
          'to approve it.',
    ),
    (
      'Acceptable use',
      'You agree not to:\n'
          '• Use Webroom to harass, impersonate, or threaten anyone.\n'
          '• Share unlawful, defamatory, or copyrighted content without '
          'permission.\n'
          '• Record or publish another user\'s audio without the host\'s '
          'permission.\n'
          '• Attempt to disrupt, reverse-engineer, or abuse the service.\n'
          '• Resell access to your account or rooms.',
    ),
    (
      'Hosts and admins',
      'Hosts control their rooms, including starting and ending sessions, '
          'muting members, enabling recordings, and publishing marquee text '
          'or banners. Admins allocate licences, approve accounts, and may '
          'remove users who break these terms. Hosts and admins must run '
          'their rooms in line with local laws.',
    ),
    (
      'Content',
      'You retain ownership of what you say or upload. You grant Webroom a '
          'non-exclusive licence to transmit, store, and display that content '
          'as needed to operate the service. Recordings made by a host are '
          'the responsibility of that host.',
    ),
    (
      'Subscriptions and licences',
      'Admins purchase licences that let them run rooms for their users. '
          'Licences have a fixed duration and renew only if explicitly '
          'extended. Rooms under an expired licence cannot be started.',
    ),
    (
      'Termination',
      'We may suspend or terminate your account if you break these terms or '
          'misuse the service. You can stop using the service at any time by '
          'signing out or asking your admin to remove you.',
    ),
    (
      'Disclaimer',
      'Webroom is provided "as is" without warranties of any kind. We do not '
          'guarantee that the service will be uninterrupted or error-free. '
          'To the maximum extent allowed by law, we are not liable for any '
          'indirect or consequential damages arising from your use of the '
          'service.',
    ),
    (
      'Changes',
      'We may update these terms from time to time. Material changes will be '
          'communicated through the app. Continued use after the effective '
          'date means you accept the updated terms.',
    ),
    (
      'Contact',
      'Questions about these terms? Reach out to your admin or email '
          'support@webroom.app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: WebMaxWidth(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            _lastUpdated,
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 20),
          for (final (title, body) in _sections) ...[
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      )),
    );
  }
}
