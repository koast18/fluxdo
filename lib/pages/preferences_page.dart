import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/s.dart';
import '../providers/preferences_provider.dart';
import '../providers/sticker_provider.dart';
import '../services/sticker_market_service.dart';

class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preferences = ref.watch(preferencesProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.preferences_title),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader(theme, l10n.preferences_basic),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.preferences_longPressPreview),
                  subtitle: Text(l10n.preferences_longPressPreviewDesc),
                  secondary: Icon(
                    Icons.touch_app_rounded,
                    color: preferences.longPressPreview
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  value: preferences.longPressPreview,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setLongPressPreview(value);
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha:0.3)),
                SwitchListTile(
                  title: Text(l10n.preferences_hideBarOnScroll),
                  subtitle: Text(l10n.preferences_hideBarOnScrollDesc),
                  secondary: Icon(
                    Icons.swap_vert_rounded,
                    color: preferences.hideBarOnScroll
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  value: preferences.hideBarOnScroll,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setHideBarOnScroll(value);
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha:0.3)),
                SwitchListTile(
                  title: Text(l10n.preferences_openLinksInApp),
                  subtitle: Text(l10n.preferences_openLinksInAppDesc),
                  secondary: Icon(
                    Icons.open_in_browser_rounded,
                    color: preferences.openExternalLinksInAppBrowser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  value: preferences.openExternalLinksInAppBrowser,
                  onChanged: (value) {
                    ref
                        .read(preferencesProvider.notifier)
                        .setOpenExternalLinksInAppBrowser(value);
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha:0.3)),
                SwitchListTile(
                  title: Text(l10n.preferences_anonymousShare),
                  subtitle: Text(l10n.preferences_anonymousShareDesc),
                  secondary: Icon(
                    Icons.visibility_off_rounded,
                    color: preferences.anonymousShare
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  value: preferences.anonymousShare,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setAnonymousShare(value);
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha:0.3)),
                SwitchListTile(
                  title: Text(l10n.preferences_autoFillLogin),
                  subtitle: Text(l10n.preferences_autoFillLoginDesc),
                  secondary: Icon(
                    Icons.password_rounded,
                    color: preferences.autoFillLogin
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  value: preferences.autoFillLogin,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setAutoFillLogin(value);
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha:0.3)),
                SwitchListTile(
                  title: Text(l10n.preferences_cfClearanceRefresh),
                  subtitle: Text(l10n.preferences_cfClearanceRefreshDesc),
                  secondary: Icon(
                    Icons.security_update_warning_rounded,
                    color: preferences.cfClearanceRefresh
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  value: preferences.cfClearanceRefresh,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setCfClearanceRefresh(value);
                  },
                ),
                if (Platform.isIOS || Platform.isAndroid) ...[
                  Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha:0.3)),
                  SwitchListTile(
                    title: Text(l10n.preferences_portraitLock),
                    subtitle: Text(l10n.preferences_portraitLockDesc),
                    secondary: Icon(
                      Icons.screen_lock_portrait_rounded,
                      color: preferences.portraitLock
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    value: preferences.portraitLock,
                    onChanged: (value) {
                      ref.read(preferencesProvider.notifier).setPortraitLock(value);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, l10n.preferences_editor),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.preferences_autoPanguSpacing),
                  subtitle: Text(l10n.preferences_autoPanguSpacingDesc),
                  secondary: Icon(
                    Icons.auto_fix_high_rounded,
                    color: preferences.autoPanguSpacing
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  value: preferences.autoPanguSpacing,
                  onChanged: (value) {
                    ref.read(preferencesProvider.notifier).setAutoPanguSpacing(value);
                  },
                ),
                Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withValues(alpha:0.3)),
                ListTile(
                  leading: Icon(
                    Icons.sticky_note_2_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(l10n.preferences_stickerSource),
                  subtitle: Text(
                    ref.watch(stickerMarketServiceProvider).baseUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => _showStickerBaseUrlDialog(context, ref),
                ),
              ],
            ),
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(theme, l10n.preferences_advanced),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                title: Text(l10n.preferences_crashlytics),
                subtitle: Text(l10n.preferences_crashlyticsDesc),
                secondary: Icon(
                  Icons.bug_report_rounded,
                  color: preferences.crashlytics
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                value: preferences.crashlytics,
                onChanged: (value) {
                  ref.read(preferencesProvider.notifier).setCrashlytics(value);
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showStickerBaseUrlDialog(BuildContext context, WidgetRef ref) {
    final service = ref.read(stickerMarketServiceProvider);
    final controller = TextEditingController(text: service.baseUrl);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.preferences_stickerSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: context.l10n.preferences_enterUrl,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  controller.text = StickerMarketService.defaultBaseUrl;
                },
                child: Text(context.l10n.common_restoreDefault),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await service.setBaseUrl(url);
                ref.invalidate(stickerGroupsProvider);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
