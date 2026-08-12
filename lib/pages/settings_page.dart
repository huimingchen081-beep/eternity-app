import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/responsive_wrapper.dart';
import 'usage_guide_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF050510),
          appBar: AppBar(
            backgroundColor: const Color(0xCC0D0D2A),
            title: Text(
              _getTitle(appState.language),
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white70),
          ),
          body: ResponsiveWidth(
            maxWidth: 500,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
              // App info
              _buildSectionTitle(
                  appState.language == 'zh' ? '应用信息' : 'App Info'),
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.star_outlined,
                  label:
                      appState.language == 'zh' ? '版本' : 'Version',
                  value: appState.language == 'zh' ? '完整版' : 'Full Version',
                ),
              ]),

              const SizedBox(height: 16),

              // Storage
              _buildSectionTitle(
                  appState.language == 'zh' ? '存储空间' : 'Storage'),
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.storage_outlined,
                  label:
                      appState.language == 'zh' ? '已使用' : 'Used',
                  value: '${appState.storageUsedMB} MB / ${AppConstants.maxLocalStorageMB} MB',
                ),
                _InfoRow(
                  icon: Icons.star_outline,
                  label: appState.language == 'zh' ? '已点亮星球' : 'Lit Planets',
                  value: '${appState.litCount}',
                ),
              ]),

              const SizedBox(height: 16),

              // Reminder
              _buildSectionTitle(
                  appState.language == 'zh' ? '每日提醒' : 'Daily Reminder'),
              _buildInfoCard([
                _ReminderToggle(appState: appState),
              ]),

              const SizedBox(height: 16),

              // About
              _buildSectionTitle(
                  appState.language == 'zh' ? '关于' : 'About'),
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.menu_book_outlined,
                  label: appState.language == 'zh' ? '使用方法' : 'How to Use',
                  value: '',
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UsageGuidePage(
                            language: appState.language,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      appState.language == 'zh' ? '查看' : 'View',
                      style: const TextStyle(color: Color(0xFF4FC3F7)),
                    ),
                  ),
                ),
                _InfoRow(
                  icon: Icons.info_outline,
                  label: appState.language == 'zh' ? '版本' : 'Version',
                  value: '1.0.0',
                ),
                _InfoRow(
                  icon: Icons.privacy_tip_outlined,
                  label: appState.language == 'zh' ? '隐私政策' : 'Privacy Policy',
                  value: '',
                  trailing: TextButton(
                    onPressed: () => _showPrivacyDialog(
                      context,
                      AppConstants.privacyUrl,
                      appState.language,
                    ),
                    child: const Text('查看',
                        style: TextStyle(color: Color(0xFF4FC3F7))),
                  ),
                ),
              ]),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF4FC3F7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }

  String _getTitle(String lang) {
    switch (lang) {
      case 'zh':
        return '设置';
      case 'ja':
        return '設定';
      case 'ko':
        return '설정';
      default:
        return 'Settings';
    }
  }

  static void _showPrivacyDialog(
    BuildContext context,
    String url,
    String lang,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D2A),
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveWidth.isTablet(context) ? 200 : 40,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          lang == 'zh' ? '隐私政策' : 'Privacy Policy',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lang == 'zh'
                  ? '请复制链接后在浏览器中打开'
                  : 'Copy the link and open in browser',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              lang == 'zh' ? '关闭' : 'Close',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    lang == 'zh' ? '链接已复制到剪贴板' : 'Link copied to clipboard',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text(lang == 'zh' ? '复制链接' : 'Copy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: const Color(0xFF050510),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          ?trailing,
          if (value.isNotEmpty && trailing == null)
            Text(value,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ReminderToggle extends StatefulWidget {
  final AppState appState;
  const _ReminderToggle({required this.appState});

  @override
  State<_ReminderToggle> createState() => _ReminderToggleState();
}

class _ReminderToggleState extends State<_ReminderToggle> {
  bool _enabled = true;
  int _hour = 20;

  @override
  void initState() {
    super.initState();
    widget.appState.getReminderEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
    widget.appState.getReminderHour().then((v) {
      if (mounted) setState(() => _hour = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  color: Colors.white38, size: 18),
              const SizedBox(width: 10),
              Text(
                widget.appState.language == 'zh' ? '每日提醒' : 'Daily Reminder',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              Switch(
                value: _enabled,
                onChanged: (v) {
                  setState(() => _enabled = v);
                  widget.appState.setReminderEnabled(v);
                },
                activeTrackColor: const Color(0xFF4FC3F7),
              ),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('  '),
                Text(
                  '${_hour.toString().padLeft(2, '0')}:00',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _hour.toDouble(),
                    min: 6,
                    max: 23,
                    divisions: 17,
                    activeColor: const Color(0xFF4FC3F7),
                    onChanged: (v) {
                      setState(() => _hour = v.round());
                      widget.appState.setReminderHour(_hour);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
