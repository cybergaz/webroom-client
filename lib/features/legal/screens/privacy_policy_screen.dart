import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_max_width.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'Last updated: April 2026';

  static const _sections = <(String, String)>[
    (
      'Who we are',
      'Webroom is an audio-room platform that lets hosts run live rooms with '
          'assigned members. This policy describes what information we collect '
          'when you use Webroom, how we use it, and the choices you have.',
    ),
    (
      'Information you give us',
      'When you sign up we collect your name, phone number, and optional email '
          'address. Admins may also record the device you use to log in so they '
          'can prevent account sharing on their licences. If you upload a '
          'profile picture, we store the image on our infrastructure.',
    ),
    (
      'Information we collect automatically',
      'We collect technical data needed to run the service: the app version, '
          'device model, and a randomly-generated device ID. While you are in '
          'a live room we collect real-time audio through your microphone so '
          'the host and other members can hear you. Audio is transmitted via '
          'our streaming provider (GetStream) and is not stored unless the '
          'host explicitly records the session.',
    ),
    (
      'How we use the information',
      '• To create and maintain your account.\n'
          '• To route audio between members of a live room.\n'
          '• To let admins moderate their rooms and verify device use.\n'
          '• To generate session recordings when a host enables them.\n'
          '• To keep the service secure and diagnose problems.',
    ),
    (
      'Recordings',
      'Hosts can record rooms. When a room is recorded you will see an '
          'indicator in the room screen. Recordings are stored in secure '
          'object storage and are accessible to the host and the admins who '
          'manage them. You can ask your admin to delete any session you '
          'were part of.',
    ),
    (
      'Sharing',
      'We do not sell your personal data. We share it only with the service '
          'providers that run Webroom on our behalf — primarily our hosting '
          'platform, database provider, and GetStream for real-time audio. '
          'We may disclose information when required by law.',
    ),
    (
      'Your choices',
      'You can sign out at any time, request that your admin removes you from '
          'a room, or ask support to delete your account. Turning off the '
          'microphone permission prevents us from collecting audio, but you '
          'will not be able to speak in rooms.',
    ),
    (
      'Retention',
      'We keep your profile data while your account is active. Recordings '
          'are kept for as long as your admin chooses to keep them within '
          'the licence period. Backups are rotated on a rolling window.',
    ),
    (
      'Contact',
      'If you have questions about this policy, or want to exercise any of '
          'the rights above, contact the admin who invited you to Webroom or '
          'email support@webroom.app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Privacy Policy'),
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
