import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';

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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Purchase status
              _buildSectionTitle(
                  appState.language == 'zh' ? '购买状态' : 'Purchase'),
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.shopping_cart_outlined,
                  label:
                      appState.language == 'zh' ? '版本' : 'Version',
                  value: appState.hasPurchased
                      ? (appState.language == 'zh' ? '完整版' : 'Full Version')
                      : (appState.language == 'zh' ? '免费版' : 'Free'),
                ),
                if (!appState.hasPurchased)
                  _InfoRow(
                    icon: Icons.lock_outline,
                    label:
                        appState.language == 'zh' ? '解锁价格' : 'Price',
                    value: '\$1.99',
                    trailing: ElevatedButton(
                      onPressed: () => appState.unlockFullVersion(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: const Color(0xFF050510),
                      ),
                      child: Text(
                        appState.language == 'zh' ? '购买' : 'Buy',
                      ),
                    ),
                  ),
                if (!appState.hasPurchased)
                  _InfoRow(
                    icon: Icons.restore,
                    label: appState.language == 'zh' ? '恢复购买' : 'Restore',
                    value: '',
                    trailing: TextButton(
                      onPressed: () => appState.restorePurchase(),
                      child: Text(
                        appState.language == 'zh' ? '恢复' : 'Restore',
                        style: const TextStyle(color: Color(0xFF4FC3F7)),
                      ),
                    ),
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
                  icon: Icons.info_outline,
                  label: appState.language == 'zh' ? '版本' : 'Version',
                  value: '1.0.0',
                ),
                _InfoRow(
                  icon: Icons.privacy_tip_outlined,
                  label: appState.language == 'zh' ? '隐私政策' : 'Privacy Policy',
                  value: '',
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('查看',
                        style: TextStyle(color: Color(0xFF4FC3F7))),
                  ),
                ),
              ]),
            ],
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
